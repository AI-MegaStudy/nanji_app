from __future__ import annotations

import argparse
import os
import re
import sys
from datetime import datetime
from html import unescape
from pathlib import Path
from typing import Any

import requests
import certifi

CURRENT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = CURRENT_DIR.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from app.db.session import SessionLocal
from app.models.parking import ParkingLot, ParkingStatusLog


SOURCE_PAGE_URL = "https://www.ihangangpark.kr/parking/region/region9"
DEFAULT_ROW_NAME = "난지1,2,3,4주차장"


def get_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Collect the current Nanji parking status from the Han River parking portal and store it in parking_status_log."
    )
    parser.add_argument("--parking-lot-id", type=int, default=1, help="Target parking_lot p_id.")
    parser.add_argument(
        "--row-name",
        default=DEFAULT_ROW_NAME,
        help="Exact parking row name to match from the Han River parking page.",
    )
    parser.add_argument(
        "--page-url",
        default=SOURCE_PAGE_URL,
        help="Han River parking detail page URL to scrape.",
    )
    parser.add_argument(
        "--source-type",
        default="ihangangpark_site",
        help="Source type label stored in parking_status_log.",
    )
    parser.add_argument(
        "--insecure",
        action="store_true",
        help="Disable SSL certificate verification if the local CA store is broken.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Preview without saving.")
    return parser.parse_args()


def classify_congestion(occupancy_rate: float) -> str:
    if occupancy_rate < 30:
        return "free"
    if occupancy_rate < 60:
        return "normal"
    if occupancy_rate < 85:
        return "busy"
    return "full"


def parse_int(value: Any, field_name: str) -> int:
    if value is None or str(value).strip() == "":
        raise ValueError(f"Source field is empty: {field_name}")
    digits = re.sub(r"[^\d.-]", "", str(value).strip())
    if not digits:
        raise ValueError(f"Source field has no numeric value: {field_name}")
    return int(float(digits))


def fetch_page_html(page_url: str, *, insecure: bool = False) -> str:
    verify: str | bool = False if insecure else certifi.where()

    try:
        response = requests.get(page_url, timeout=30, verify=verify)
        response.raise_for_status()
    except requests.exceptions.SSLError:
        if insecure:
            raise
        response = requests.get(page_url, timeout=30, verify=False)
        response.raise_for_status()

    response.encoding = response.encoding or "utf-8"
    return response.text


def clean_html_text(value: str) -> str:
    text = unescape(re.sub(r"<[^>]+>", "", value))
    return re.sub(r"\s+", " ", text).strip()


def extract_table_rows(page_html: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for table_row in re.findall(r"<tr\b.*?>.*?</tr>", page_html, re.DOTALL | re.IGNORECASE):
        columns = re.findall(r"<td\b.*?>(.*?)</td>", table_row, re.DOTALL | re.IGNORECASE)
        if len(columns) < 5:
            continue

        name = clean_html_text(columns[0])
        if not name:
            continue

        rows.append(
            {
                "name": name,
                "address": clean_html_text(columns[1]),
                "available_spaces": clean_html_text(columns[3]),
                "total_spaces": clean_html_text(columns[4]),
            }
        )
    return rows


def pick_nanji_row(rows: list[dict[str, str]], row_name: str) -> dict[str, str]:
    exact_matches = [row for row in rows if row["name"] == row_name]
    if exact_matches:
        return exact_matches[0]

    nanji_rows = [row for row in rows if "난지" in row["name"]]
    if not nanji_rows:
        raise ValueError("No Nanji parking rows were found on the Han River parking page.")
    if len(nanji_rows) == 1:
        return nanji_rows[0]

    available_names = ", ".join(sorted(row["name"] for row in nanji_rows))
    raise ValueError(
        "Multiple Nanji rows were found. "
        f"Pass --row-name explicitly. Available rows: {available_names}"
    )


def parse_recorded_at() -> datetime:
    now = datetime.now()
    return now.replace(minute=0, second=0, microsecond=0)


def main() -> None:
    args = get_args()
    page_html = fetch_page_html(args.page_url, insecure=args.insecure)
    rows = extract_table_rows(page_html)
    if not rows:
        raise ValueError("The Han River parking page did not contain any parsable parking rows.")
    selected_row = pick_nanji_row(rows, args.row_name)

    db = SessionLocal()
    try:
        parking_lot = db.query(ParkingLot).filter(ParkingLot.p_id == args.parking_lot_id).first()
        if parking_lot is None:
            raise RuntimeError(f"parking_lot not found: {args.parking_lot_id}")

        total_spaces = parse_int(selected_row.get("total_spaces"), "total_spaces")
        available_spaces = parse_int(selected_row.get("available_spaces"), "available_spaces")
        available_spaces = max(0, min(available_spaces, total_spaces))
        occupied_spaces = max(0, total_spaces - available_spaces)
        occupancy_rate = 0 if total_spaces == 0 else round((occupied_spaces / total_spaces) * 100, 2)
        recorded_at = parse_recorded_at()

        existing_row = (
            db.query(ParkingStatusLog)
            .filter(
                ParkingStatusLog.ps_parking_lot_id == parking_lot.p_id,
                ParkingStatusLog.ps_recorded_at == recorded_at,
                ParkingStatusLog.ps_source_type == args.source_type,
            )
            .first()
        )

        row = existing_row or ParkingStatusLog(
            ps_parking_lot_id=parking_lot.p_id,
            ps_recorded_at=recorded_at,
            ps_source_type=args.source_type,
            ps_created_at=datetime.now(),
        )
        row.ps_occupied_spaces = occupied_spaces
        row.ps_available_spaces = available_spaces
        row.ps_occupancy_rate = occupancy_rate
        row.ps_congestion_level = classify_congestion(occupancy_rate)
        if existing_row is None:
            db.add(row)
        db.flush()

        print(
            {
                "parking_lot_id": parking_lot.p_id,
                "parking_lot_name": parking_lot.p_display_name,
                "site_row_name": selected_row.get("name"),
                "site_address": selected_row.get("address"),
                "site_total_spaces": total_spaces,
                "site_available_spaces": available_spaces,
                "site_occupied_spaces": occupied_spaces,
                "recorded_at": recorded_at.strftime("%Y-%m-%d %H:%M:%S"),
                "occupancy_rate": occupancy_rate,
                "congestion_level": row.ps_congestion_level,
                "source_type": args.source_type,
                "dry_run": args.dry_run,
            }
        )

        if args.dry_run:
            db.rollback()
            print("dry_run complete")
        else:
            db.commit()
            print("insert complete")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
