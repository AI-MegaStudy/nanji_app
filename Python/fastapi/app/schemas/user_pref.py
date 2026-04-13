from typing import Optional

from pydantic import BaseModel, ConfigDict, field_validator


ALLOWED_NOTIFICATION_TYPES = {"parking_status"}
ALLOWED_ACTION_TYPES = {
    "login",
    "congestion_view",
    "prediction_view",
    "departure_timing_view",
    "map_view",
    "favorite_add",
    "favorite_remove",
    "notification_set",
}


class FavoriteParkingLotItem(BaseModel):
    parking_lot_id: int
    created_at: Optional[str] = None


class FavoriteParkingLotListResponse(BaseModel):
    user_id: int
    count: int
    items: list[FavoriteParkingLotItem]


class FavoriteParkingLotToggleRequest(BaseModel):
    parking_lot_id: int

    @field_validator("parking_lot_id")
    @classmethod
    def validate_parking_lot_id(cls, value: int) -> int:
        if value <= 0:
            raise ValueError("parking_lot_id must be positive")
        return value


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

    @field_validator("parking_lot_id")
    @classmethod
    def validate_parking_lot_id(cls, value: int) -> int:
        if value <= 0:
            raise ValueError("parking_lot_id must be positive")
        return value

    @field_validator("notification_type")
    @classmethod
    def validate_notification_type(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in ALLOWED_NOTIFICATION_TYPES:
            raise ValueError("notification_type must be parking_status")
        return normalized


class NotificationSettingUpsertResponse(BaseModel):
    user_id: int
    parking_lot_id: int
    notification_type: str
    is_enabled: bool


class UserActionLogCreateRequest(BaseModel):
    action_type: str
    parking_lot_id: Optional[int] = None
    action_target: Optional[str] = None
    action_value: Optional[str] = None
    source_page: Optional[str] = None
    session_id: Optional[str] = None

    @field_validator("action_type")
    @classmethod
    def validate_action_type(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in ALLOWED_ACTION_TYPES:
            raise ValueError("action_type is not allowed")
        return normalized

    @field_validator("parking_lot_id")
    @classmethod
    def validate_optional_parking_lot_id(cls, value: Optional[int]) -> Optional[int]:
        if value is None:
            return None
        if value <= 0:
            raise ValueError("parking_lot_id must be positive")
        return value

    @field_validator("action_target")
    @classmethod
    def validate_action_target(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        normalized = value.strip()
        if not normalized:
            return None
        if len(normalized) > 100:
            raise ValueError("action_target must be 100 characters or fewer")
        return normalized

    @field_validator("action_value")
    @classmethod
    def validate_action_value(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        normalized = value.strip()
        if not normalized:
            return None
        if len(normalized) > 255:
            raise ValueError("action_value must be 255 characters or fewer")
        return normalized

    @field_validator("source_page")
    @classmethod
    def validate_source_page(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        normalized = value.strip()
        if not normalized:
            return None
        if len(normalized) > 50:
            raise ValueError("source_page must be 50 characters or fewer")
        return normalized

    @field_validator("session_id")
    @classmethod
    def validate_session_id(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        normalized = value.strip()
        if not normalized:
            return None
        if len(normalized) > 100:
            raise ValueError("session_id must be 100 characters or fewer")
        return normalized


class UserActionLogCreateResponse(BaseModel):
    user_id: int
    action_type: str
    parking_lot_id: Optional[int] = None
    source_page: Optional[str] = None
    created_at: str
