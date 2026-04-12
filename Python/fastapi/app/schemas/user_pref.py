from typing import Optional

from pydantic import BaseModel, ConfigDict


class FavoriteParkingLotItem(BaseModel):
    parking_lot_id: int
    created_at: Optional[str] = None


class FavoriteParkingLotListResponse(BaseModel):
    user_id: int
    count: int
    items: list[FavoriteParkingLotItem]


class FavoriteParkingLotToggleRequest(BaseModel):
    parking_lot_id: int


class FavoriteParkingLotToggleResponse(BaseModel):
    user_id: int
    parking_lot_id: int
    is_favorite: bool


class MyProfileResponse(BaseModel):
    user_id: int
    provider: str
    name: str
    email: Optional[str] = None
    favorite_count: int
    enabled_notification_count: int


class NotificationSettingItem(BaseModel):
    parking_lot_id: int
    notification_type: str
    is_enabled: bool

    model_config = ConfigDict(from_attributes=True)


class NotificationSettingListResponse(BaseModel):
    user_id: int
    count: int
    items: list[NotificationSettingItem]


class NotificationSettingUpsertRequest(BaseModel):
    parking_lot_id: int
    notification_type: str = "parking_status"
    is_enabled: bool


class NotificationSettingUpsertResponse(BaseModel):
    user_id: int
    parking_lot_id: int
    notification_type: str
    is_enabled: bool
