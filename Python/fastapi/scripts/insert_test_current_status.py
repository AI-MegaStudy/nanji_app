from __future__ import annotations

import argparse
import sys
from datetime import datetime
from pathlib import Path

CURRENT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = CURRENT_DIR.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from app.db.session import SessionLocal
from app.models.parking import ParkingLot, ParkingStatusLog


def get_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Insert a test current parking status row.")
    parser.add_argument("--parking-lot-id", type=int, default=1, help="Target parking_lot p_id.")
    parser.add_argument("--occupied", type=int, default=172, help="Current occupied spaces.")
    parser.add_argument("--source-type", default="manual_test", help="Source type label for this test row.")
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


def main() -> None:
    args = get_args()

    db = SessionLocal()
    try:
        parking_lot = db.query(ParkingLot).filter(ParkingLot.p_id == args.parking_lot_id).first()
        if parking_lot is None:
            raise RuntimeError(f"parking_lot not found: {args.parking_lot_id}")

        occupied_spaces = max(0, args.occupied)
        total_spaces = int(parking_lot.p_total_spaces)
        available_spaces = max(0, total_spaces - occupied_spaces)
        occupancy_rate = 0 if total_spaces == 0 else round((occupied_spaces / total_spaces) * 100, 2)
        recorded_at = datetime.now()

        row = ParkingStatusLog(
            ps_parking_lot_id=parking_lot.p_id,
            ps_recorded_at=recorded_at,
            ps_occupied_spaces=occupied_spaces,
            ps_available_spaces=available_spaces,
            ps_occupancy_rate=occupancy_rate,
            ps_congestion_level=classify_congestion(occupancy_rate),
            ps_source_type=args.source_type,
            ps_created_at=recorded_at,
        )
        db.add(row)
        db.flush()

        print(
            {
                "parking_lot_id": parking_lot.p_id,
                "parking_lot_name": parking_lot.p_display_name,
                "recorded_at": recorded_at.strftime("%Y-%m-%d %H:%M:%S"),
                "occupied_spaces": occupied_spaces,
                "available_spaces": available_spaces,
                "occupancy_rate": occupancy_rate,
                "congestion_level": row.ps_congestion_level,
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
