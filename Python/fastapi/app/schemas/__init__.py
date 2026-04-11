# Pydantic schemas package.
#
# Put request/response models here after API endpoints are defined.
from app.schemas.parking import ParkingLotItem, ParkingLotListResponse

__all__ = ["ParkingLotItem", "ParkingLotListResponse"]
