from __future__ import annotations

import argparse
import csv
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple

CURRENT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = CURRENT_DIR.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from app.db.session import SessionLocal
from app.models.parking import ParkingLot, ParkingPrediction


IMPORT_CSV = Path("/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/data/ml_ready/nanji_group_predictions_for_fastapi.csv")
DEFAULT_GROUP_NAME = "난지전체"
DEFAULT_PARKING_NAME = "난지메인"
DEFAULT_DISPLAY_NAME = "난지 메인 주차장"


def get_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import Nanji grouped prediction rows into parking_prediction.")
    parser.add_argument("--csv", default=str(IMPORT_CSV), help="Path to the ML-ready CSV file.")
    parser.add_argument("--parking-group", default=DEFAULT_GROUP_NAME, help="Grouped parking lot key used in the CSV.")
    parser.add_argument("--create-parking-lot", action="store_true", help="Create a representative parking_lot row if it does not exist.")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing to DB.")
    return parser.parse_args()


def find_or_create_group_lot(db, parking_group: str, create_if_missing: bool) -> Optional[ParkingLot]:
    parking_lot = (
        db.query(ParkingLot)
        .filter(
            (ParkingLot.p_name == DEFAULT_PARKING_NAME)
            | (ParkingLot.p_name == parking_group)
            | (ParkingLot.p_display_name == parking_group)
            | (ParkingLot.p_display_name == DEFAULT_DISPLAY_NAME)
        )
        .first()
    )

    if parking_lot is not None or not create_if_missing:
        return parking_lot

    # 대표 row가 아직 없을 때만 사용하는 기본값이다.
    # 운영 반영 전에는 실제 서비스 문구/좌표/주차면수로 교체하는 편이 좋다.
    parking_lot = ParkingLot(
        p_name=DEFAULT_PARKING_NAME,
        p_display_name=DEFAULT_DISPLAY_NAME,
        p_parking_type="public",
        p_region_name="난지",
        p_address="서울특별시 마포구 상암동 난지한강공원",
        p_latitude=37.5686,
        p_longitude=126.8789,
        p_total_spaces=1000,
        p_operating_status="open",
        p_supports_realtime_congestion=False,
        p_supports_prediction=True,
        p_supports_departure_timing=True,
        p_supports_map_view=True,
        p_supports_favorite=True,
        p_supports_notification=True,
        p_created_at=datetime.now(),
        p_updated_at=datetime.now(),
    )
    db.add(parking_lot)
    db.flush()
    return parking_lot


def classify_congestion(occupancy_rate: float) -> str:
    if occupancy_rate < 30:
        return "free"
    if occupancy_rate < 60:
        return "normal"
    if occupancy_rate < 85:
        return "busy"
    return "full"


def clamp_occupied(value: float, total_spaces: int) -> int:
    rounded = round(value)
    if rounded < 0:
        return 0
    if total_spaces > 0 and rounded > total_spaces:
        return total_spaces
    return rounded


def main() -> None:
    args = get_args()
    csv_path = Path(args.csv)
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV not found: {csv_path}")

    db = SessionLocal()
    try:
        parking_lot = find_or_create_group_lot(db, args.parking_group, args.create_parking_lot)
        if parking_lot is None:
            raise RuntimeError(
                "대표 parking_lot row를 찾지 못했습니다. 먼저 DB에 난지 메인 주차장 row를 넣거나 "
                "--create-parking-lot 옵션으로 생성하세요."
            )

        inserted = 0
        skipped = 0

        existing_rows = (
            db.query(
                ParkingPrediction.pp_base_time,
                ParkingPrediction.pp_predicted_time,
                ParkingPrediction.pp_model_version,
            )
            .filter(ParkingPrediction.pp_parking_lot_id == parking_lot.p_id)
            .all()
        )
        existing_keys = {
            (base_time, predicted_time, model_version)
            for base_time, predicted_time, model_version in existing_rows
        }

        print(
            f"start import parking_lot_id={parking_lot.p_id} existing_predictions={len(existing_keys)} csv={csv_path.name}",
            flush=True,
        )

        with csv_path.open("r", encoding="utf-8", newline="") as file:
            reader = csv.DictReader(file)
            source_rows = [row for row in reader if row["parking_group"] == args.parking_group]

        source_rows.sort(
            key=lambda row: (
                row["base_time"],
                row["predicted_time"],
                row.get("model_version", "") or "",
            )
        )

        cumulative_by_base_time: dict[Tuple[str, Optional[str]], float] = {}

        for index, row in enumerate(source_rows, start=1):
            base_time = datetime.strptime(row["base_time"], "%Y-%m-%d %H:%M:%S")
            predicted_time = datetime.strptime(row["predicted_time"], "%Y-%m-%d %H:%M:%S")
            confidence_score = None if not row.get("confidence_score") else float(row["confidence_score"])
            model_version = row.get("model_version") or None
            horizon_minutes = int(row["prediction_horizon_minutes"])

            key = (base_time, predicted_time, model_version)
            if key in existing_keys:
                skipped += 1
                continue

            if row.get("predicted_delta") not in (None, ""):
                cumulative_key = (row["base_time"], model_version)
                if cumulative_key not in cumulative_by_base_time:
                    base_occupied_raw = row.get("base_occupied_spaces")
                    if base_occupied_raw in (None, ""):
                        raise ValueError(
                            "변화량 기반 CSV를 적재하려면 각 row에 `base_occupied_spaces`가 필요합니다."
                        )
                    cumulative_by_base_time[cumulative_key] = float(base_occupied_raw)

                cumulative_by_base_time[cumulative_key] += float(row["predicted_delta"])
                occupied_spaces = clamp_occupied(cumulative_by_base_time[cumulative_key], parking_lot.p_total_spaces)
            else:
                estimated_active_cars = row.get("estimated_active_cars")
                if estimated_active_cars in (None, ""):
                    raise ValueError(
                        "절대값 기반 CSV를 적재하려면 `estimated_active_cars` 컬럼이 필요합니다."
                    )
                occupied_spaces = clamp_occupied(float(estimated_active_cars), parking_lot.p_total_spaces)

            available_spaces = max(0, parking_lot.p_total_spaces - occupied_spaces)
            occupancy_rate = 0 if parking_lot.p_total_spaces == 0 else round((occupied_spaces / parking_lot.p_total_spaces) * 100, 2)

            prediction = ParkingPrediction(
                pp_parking_lot_id=parking_lot.p_id,
                pp_base_time=base_time,
                pp_predicted_time=predicted_time,
                pp_prediction_horizon_minutes=horizon_minutes,
                pp_predicted_occupied_spaces=occupied_spaces,
                pp_predicted_available_spaces=available_spaces,
                pp_predicted_occupancy_rate=occupancy_rate,
                pp_predicted_congestion_level=classify_congestion(occupancy_rate),
                pp_confidence_score=confidence_score,
                pp_model_version=model_version,
                pp_created_at=datetime.now(),
            )
            db.add(prediction)
            existing_keys.add(key)
            inserted += 1

            if index % 1000 == 0:
                print(
                    f"progress processed={index} inserted={inserted} skipped={skipped}",
                    flush=True,
                )

        if args.dry_run:
            db.rollback()
            print(f"dry_run inserted={inserted} skipped={skipped} parking_lot_id={parking_lot.p_id}")
        else:
            db.commit()
            print(f"imported inserted={inserted} skipped={skipped} parking_lot_id={parking_lot.p_id}")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
