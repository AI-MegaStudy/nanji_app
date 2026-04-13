from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict


class ParkingLotItem(BaseModel):
    p_id: int
    p_name: str
    p_display_name: str
    p_parking_type: str
    p_region_name: str
    p_address: Optional[str] = None
    p_latitude: Decimal
    p_longitude: Decimal
    p_total_spaces: int
    p_open_time: Optional[str] = None
    p_close_time: Optional[str] = None
    p_operating_status: str
    p_supports_realtime_congestion: bool
    p_supports_prediction: bool
    p_supports_departure_timing: bool
    p_supports_map_view: bool
    p_supports_favorite: bool
    p_supports_notification: bool

    model_config = ConfigDict(from_attributes=True)


class ParkingLotListResponse(BaseModel):
    count: int
    items: list[ParkingLotItem]


class ParkingCurrentStatusItem(BaseModel):
    ps_id: int
    ps_parking_lot_id: int
    ps_recorded_at: str
    ps_occupied_spaces: int
    ps_available_spaces: int
    ps_occupancy_rate: Decimal
    ps_congestion_level: str
    ps_source_type: str

    model_config = ConfigDict(from_attributes=True)


class ParkingCurrentStatusResponse(BaseModel):
    parking_lot_id: int
    parking_lot_name: str
    total_spaces: int
    supports_realtime_congestion: bool
    has_data: bool
    item: Optional[ParkingCurrentStatusItem] = None
    message: Optional[str] = None


class ParkingStatusHistoryResponse(BaseModel):
    parking_lot_id: int
    parking_lot_name: str
    target_date: str
    count: int
    items: list[ParkingCurrentStatusItem]
