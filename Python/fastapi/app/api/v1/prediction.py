from datetime import date, datetime, time, timedelta
from typing import Optional

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.parking import ParkingLot, ParkingPrediction, ParkingStatusLog
from app.schemas.prediction import ParkingPredictionItem, ParkingPredictionListResponse
from app.services.prediction_engine import generated_prediction_to_item, get_prediction_engine

router = APIRouter(prefix="/predictions", tags=["predictions"])


def _load_saved_predictions(
    parking_lot_id: int,
    target_date: date,
    limit: int,
    db: Session,
) -> list[ParkingPredictionItem]:
    day_start = datetime.combine(target_date, time.min)
    next_day_start = day_start + timedelta(days=1)
    predictions = (
        db.query(ParkingPrediction)
        .filter(
            ParkingPrediction.pp_parking_lot_id == parking_lot_id,
            ParkingPrediction.pp_predicted_time >= day_start,
            ParkingPrediction.pp_predicted_time < next_day_start,
        )
        .order_by(ParkingPrediction.pp_predicted_time.asc(), ParkingPrediction.pp_id.asc())
        .limit(limit)
        .all()
    )
    return [
        ParkingPredictionItem(
            pp_id=prediction.pp_id,
            pp_parking_lot_id=prediction.pp_parking_lot_id,
            pp_base_time=prediction.pp_base_time.strftime("%Y-%m-%d %H:%M:%S"),
            pp_predicted_time=prediction.pp_predicted_time.strftime("%Y-%m-%d %H:%M:%S"),
            pp_prediction_horizon_minutes=prediction.pp_prediction_horizon_minutes,
            pp_predicted_occupied_spaces=prediction.pp_predicted_occupied_spaces,
            pp_predicted_available_spaces=prediction.pp_predicted_available_spaces,
            pp_predicted_occupancy_rate=prediction.pp_predicted_occupancy_rate,
            pp_predicted_congestion_level=prediction.pp_predicted_congestion_level,
            pp_confidence_score=prediction.pp_confidence_score,
            pp_model_version=prediction.pp_model_version,
        )
        for prediction in predictions
    ]


@router.get("/{parking_lot_id}", response_model=ParkingPredictionListResponse)
def get_predictions_by_parking_lot(
    parking_lot_id: int,
    target_date: Optional[date] = None,
    limit: int = 168,
    db: Session = Depends(get_db),
) -> ParkingPredictionListResponse:
    safe_limit = max(1, min(limit, 168))

    parking_lot = db.query(ParkingLot).filter(ParkingLot.p_id == parking_lot_id).first()
    if parking_lot is None:
        return ParkingPredictionListResponse(count=0, items=[])

    latest_status = (
        db.query(ParkingStatusLog)
        .filter(
            ParkingStatusLog.ps_parking_lot_id == parking_lot_id,
            ParkingStatusLog.ps_source_type != "manual_test",
        )
        .order_by(ParkingStatusLog.ps_recorded_at.desc(), ParkingStatusLog.ps_id.desc())
        .first()
    )

    if latest_status is None:
        latest_prediction = (
            db.query(ParkingPrediction)
            .filter(ParkingPrediction.pp_parking_lot_id == parking_lot_id)
            .order_by(ParkingPrediction.pp_predicted_time.desc(), ParkingPrediction.pp_id.desc())
            .first()
        )
        effective_date = target_date or (
            latest_prediction.pp_predicted_time.date() if latest_prediction is not None else date.today()
        )
        items = _load_saved_predictions(parking_lot_id, effective_date, safe_limit, db)
        return ParkingPredictionListResponse(count=len(items), items=items)

    effective_date = target_date or latest_status.ps_recorded_at.date()

    saved_items = []
    if effective_date < latest_status.ps_recorded_at.date():
        saved_items = _load_saved_predictions(parking_lot_id, effective_date, safe_limit, db)
        if saved_items:
            return ParkingPredictionListResponse(count=len(saved_items), items=saved_items)

    engine = get_prediction_engine()
    generated_predictions = engine.generate_predictions(
        parking_lot=parking_lot,
        latest_status=latest_status,
        target_date=effective_date,
        limit=safe_limit,
    )
    items = [
        generated_prediction_to_item(parking_lot_id, generated_prediction, index)
        for index, generated_prediction in enumerate(generated_predictions)
    ]
    return ParkingPredictionListResponse(count=len(items), items=items)
