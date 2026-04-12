from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict


class ParkingPredictionItem(BaseModel):
    pp_id: int
    pp_parking_lot_id: int
    pp_base_time: str
    pp_predicted_time: str
    pp_prediction_horizon_minutes: int
    pp_predicted_occupied_spaces: int
    pp_predicted_available_spaces: int
    pp_predicted_occupancy_rate: Decimal
    pp_predicted_congestion_level: str
    pp_confidence_score: Optional[Decimal] = None
    pp_model_version: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ParkingPredictionListResponse(BaseModel):
    count: int
    items: list[ParkingPredictionItem]
