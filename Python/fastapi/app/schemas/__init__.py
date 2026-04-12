# Pydantic schemas package.
#
# Put request/response models here after API endpoints are defined.
from app.schemas.parking import (
    ParkingCurrentStatusItem,
    ParkingCurrentStatusResponse,
    ParkingLotItem,
    ParkingLotListResponse,
)
from app.schemas.prediction import ParkingPredictionItem, ParkingPredictionListResponse

__all__ = [
    "ParkingCurrentStatusItem",
    "ParkingCurrentStatusResponse",
    "ParkingLotItem",
    "ParkingLotListResponse",
    "ParkingPredictionItem",
    "ParkingPredictionListResponse",
]
