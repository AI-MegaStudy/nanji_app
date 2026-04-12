from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.parking import ParkingPrediction
from app.schemas.prediction import ParkingPredictionItem, ParkingPredictionListResponse

router = APIRouter(prefix="/predictions", tags=["predictions"])


@router.get("/{parking_lot_id}", response_model=ParkingPredictionListResponse)
def get_predictions_by_parking_lot(parking_lot_id: int, limit: int = 24, db: Session = Depends(get_db)) -> ParkingPredictionListResponse:
    safe_limit = max(1, min(limit, 168))

    predictions = (
        db.query(ParkingPrediction)
        .filter(ParkingPrediction.pp_parking_lot_id == parking_lot_id)
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
