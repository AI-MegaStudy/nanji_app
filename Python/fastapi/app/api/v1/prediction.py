from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.parking import ParkingPrediction
from app.schemas.prediction import ParkingPredictionItem, ParkingPredictionListResponse

router = APIRouter(prefix="/predictions", tags=["predictions"])


@router.get("/{parking_lot_id}", response_model=ParkingPredictionListResponse)
def get_predictions_by_parking_lot(parking_lot_id: int, limit: int = 24, db: Session = Depends(get_db)) -> ParkingPredictionListResponse:
    safe_limit = max(1, min(limit, 168))

    latest_version_row = (
        db.query(
            ParkingPrediction.pp_model_version.label("model_version"),
            func.max(ParkingPrediction.pp_id).label("latest_pp_id"),
        )
        .filter(ParkingPrediction.pp_parking_lot_id == parking_lot_id)
        .group_by(ParkingPrediction.pp_model_version)
        .order_by(func.max(ParkingPrediction.pp_id).desc())
        .first()
    )

    latest_model_version = latest_version_row.model_version if latest_version_row is not None else None

    prediction_query = db.query(ParkingPrediction).filter(ParkingPrediction.pp_parking_lot_id == parking_lot_id)
    if latest_version_row is not None:
        prediction_query = prediction_query.filter(ParkingPrediction.pp_model_version == latest_model_version)

    predictions = (
        prediction_query
        .order_by(ParkingPrediction.pp_predicted_time.asc())
        .limit(safe_limit)
        .all()
    )

    items = []
    for prediction in predictions:
        items.append(
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
        )

    return ParkingPredictionListResponse(count=len(items), items=items)
