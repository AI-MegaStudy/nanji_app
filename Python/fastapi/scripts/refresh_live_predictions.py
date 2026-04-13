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
from app.models.parking import ParkingLot, ParkingPrediction, ParkingStatusLog
from app.services.prediction_engine import MODEL_VERSION, get_prediction_engine


def get_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Refresh live parking predictions from the latest actual status.")
    parser.add_argument("--parking-lot-id", type=int, default=1, help="Target parking_lot p_id.")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing to DB.")
    return parser.parse_args()


def main() -> None:
    args = get_args()
    db = SessionLocal()

    try:
        parking_lot = db.query(ParkingLot).filter(ParkingLot.p_id == args.parking_lot_id).first()
        if parking_lot is None:
            raise RuntimeError(f"parking_lot not found: {args.parking_lot_id}")

        latest_status = (
            db.query(ParkingStatusLog)
            .filter(
                ParkingStatusLog.ps_parking_lot_id == args.parking_lot_id,
                ParkingStatusLog.ps_source_type != "manual_test",
            )
            .order_by(ParkingStatusLog.ps_recorded_at.desc(), ParkingStatusLog.ps_id.desc())
            .first()
        )
        if latest_status is None:
            raise RuntimeError("latest real parking status not found")

        engine = get_prediction_engine()
        generated = engine.generate_predictions(
            parking_lot=parking_lot,
            latest_status=latest_status,
            target_date=latest_status.ps_recorded_at.date(),
            limit=24,
        )

        deleted = (
            db.query(ParkingPrediction)
            .filter(
                ParkingPrediction.pp_parking_lot_id == args.parking_lot_id,
                ParkingPrediction.pp_model_version == MODEL_VERSION,
                ParkingPrediction.pp_predicted_time >= latest_status.ps_recorded_at,
            )
            .delete(synchronize_session=False)
        )

        inserted = 0
        for prediction in generated:
            row = ParkingPrediction(
                pp_parking_lot_id=args.parking_lot_id,
                pp_base_time=prediction.base_time,
                pp_predicted_time=prediction.predicted_time,
                pp_prediction_horizon_minutes=int((prediction.predicted_time - prediction.base_time).total_seconds() // 60),
                pp_predicted_occupied_spaces=prediction.occupied_spaces,
                pp_predicted_available_spaces=prediction.available_spaces,
                pp_predicted_occupancy_rate=prediction.occupancy_rate,
                pp_predicted_congestion_level=prediction.congestion_level,
                pp_confidence_score=None,
                pp_model_version=MODEL_VERSION,
                pp_created_at=datetime.now(),
            )
            db.add(row)
            inserted += 1

        if args.dry_run:
            db.rollback()
        else:
            db.commit()

        print(
            {
                "parking_lot_id": args.parking_lot_id,
                "recorded_at": latest_status.ps_recorded_at.strftime("%Y-%m-%d %H:%M:%S"),
                "deleted_existing_live_predictions": deleted,
                "generated_predictions": inserted,
                "model_version": MODEL_VERSION,
                "dry_run": args.dry_run,
            }
        )
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
