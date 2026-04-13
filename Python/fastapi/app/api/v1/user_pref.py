from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.action_log import UserActionLog, UserFavoriteParkingLot
from app.models.notification import UserNotificationSetting
from app.models.user import User
from app.schemas.user_pref import (
    FavoriteParkingLotItem,
    FavoriteParkingLotListResponse,
    FavoriteParkingLotToggleRequest,
    FavoriteParkingLotToggleResponse,
    MyProfileResponse,
    NotificationSettingItem,
    NotificationSettingListResponse,
    NotificationSettingUpsertRequest,
    NotificationSettingUpsertResponse,
    UserActionLogCreateRequest,
    UserActionLogCreateResponse,
)

router = APIRouter(prefix="/me", tags=["me"])

def get_current_user(
    db: Session = Depends(get_db),
    x_user_id: Optional[str] = Header(default=None, alias="X-User-ID"),
) -> User:
    if x_user_id is None or not x_user_id.strip():
        raise HTTPException(status_code=401, detail="X-User-ID header is required")

    try:
        user_id = int(x_user_id)
    except ValueError as error:
        raise HTTPException(status_code=400, detail="X-User-ID must be an integer") from error

    user = db.query(User).filter(User.u_id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    return user


@router.get("/profile", response_model=MyProfileResponse)
def get_my_profile(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MyProfileResponse:
    favorite_count = (
        db.query(UserFavoriteParkingLot)
        .filter(UserFavoriteParkingLot.ufp_user_id == user.u_id)
        .count()
    )
    enabled_notification_count = (
        db.query(UserNotificationSetting)
        .filter(
            UserNotificationSetting.uns_user_id == user.u_id,
            UserNotificationSetting.uns_is_enabled == True,
        )
        .count()
    )

    return MyProfileResponse(
        user_id=user.u_id,
        provider=user.u_provider,
        name=user.u_name,
        email=user.u_email,
        favorite_count=favorite_count,
        enabled_notification_count=enabled_notification_count,
    )


@router.get("/favorites", response_model=FavoriteParkingLotListResponse)
def get_my_favorites(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FavoriteParkingLotListResponse:
    rows = (
        db.query(UserFavoriteParkingLot)
        .filter(UserFavoriteParkingLot.ufp_user_id == user.u_id)
        .order_by(UserFavoriteParkingLot.ufp_created_at.desc(), UserFavoriteParkingLot.ufp_id.desc())
        .all()
    )

    items = [
        FavoriteParkingLotItem(
            parking_lot_id=row.ufp_parking_lot_id,
            created_at=None if row.ufp_created_at is None else row.ufp_created_at.strftime("%Y-%m-%d %H:%M:%S"),
        )
        for row in rows
    ]
    return FavoriteParkingLotListResponse(user_id=user.u_id, count=len(items), items=items)


@router.post("/favorites/toggle", response_model=FavoriteParkingLotToggleResponse)
def toggle_my_favorite(
    payload: FavoriteParkingLotToggleRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FavoriteParkingLotToggleResponse:
    row = (
        db.query(UserFavoriteParkingLot)
        .filter(
            UserFavoriteParkingLot.ufp_user_id == user.u_id,
            UserFavoriteParkingLot.ufp_parking_lot_id == payload.parking_lot_id,
        )
        .first()
    )

    if row is not None:
        db.delete(row)
        db.commit()
        return FavoriteParkingLotToggleResponse(
            user_id=user.u_id,
            parking_lot_id=payload.parking_lot_id,
            is_favorite=False,
        )

    now = datetime.utcnow()
    row = UserFavoriteParkingLot(
        ufp_user_id=user.u_id,
        ufp_parking_lot_id=payload.parking_lot_id,
        ufp_created_at=now,
    )
    db.add(row)
    db.commit()
    return FavoriteParkingLotToggleResponse(
        user_id=user.u_id,
        parking_lot_id=payload.parking_lot_id,
        is_favorite=True,
    )


@router.get("/notifications", response_model=NotificationSettingListResponse)
def get_my_notification_settings(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> NotificationSettingListResponse:
    rows = (
        db.query(UserNotificationSetting)
        .filter(UserNotificationSetting.uns_user_id == user.u_id)
        .order_by(UserNotificationSetting.uns_updated_at.desc(), UserNotificationSetting.uns_id.desc())
        .all()
    )

    items = [
        NotificationSettingItem(
            parking_lot_id=row.uns_parking_lot_id if row.uns_parking_lot_id is not None else -1,
            notification_type=row.uns_notification_type,
            is_enabled=bool(row.uns_is_enabled),
        )
        for row in rows
        if row.uns_parking_lot_id is not None
    ]
    return NotificationSettingListResponse(user_id=user.u_id, count=len(items), items=items)


@router.post("/notifications", response_model=NotificationSettingUpsertResponse)
def upsert_my_notification_setting(
    payload: NotificationSettingUpsertRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> NotificationSettingUpsertResponse:
    if payload.parking_lot_id <= 0:
        raise HTTPException(status_code=400, detail="parking_lot_id must be positive")

    row = (
        db.query(UserNotificationSetting)
        .filter(
            UserNotificationSetting.uns_user_id == user.u_id,
            UserNotificationSetting.uns_parking_lot_id == payload.parking_lot_id,
            UserNotificationSetting.uns_notification_type == payload.notification_type,
        )
        .first()
    )

    now = datetime.utcnow()
    if row is None:
        row = UserNotificationSetting(
            uns_user_id=user.u_id,
            uns_parking_lot_id=payload.parking_lot_id,
            uns_notification_type=payload.notification_type,
            uns_is_enabled=payload.is_enabled,
            uns_created_at=now,
            uns_updated_at=now,
        )
        db.add(row)
    else:
        row.uns_is_enabled = payload.is_enabled
        row.uns_updated_at = now

    db.commit()
    return NotificationSettingUpsertResponse(
        user_id=user.u_id,
        parking_lot_id=payload.parking_lot_id,
        notification_type=payload.notification_type,
        is_enabled=payload.is_enabled,
    )


@router.post("/actions", response_model=UserActionLogCreateResponse)
def create_my_action_log(
    payload: UserActionLogCreateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserActionLogCreateResponse:
    action_type = payload.action_type.strip()
    if not action_type:
        raise HTTPException(status_code=400, detail="action_type is required")

    now = datetime.utcnow()
    row = UserActionLog(
        ual_user_id=user.u_id,
        ual_parking_lot_id=payload.parking_lot_id,
        ual_action_type=action_type,
        ual_action_target=payload.action_target,
        ual_action_value=payload.action_value,
        ual_source_page=payload.source_page,
        ual_session_id=payload.session_id,
        ual_created_at=now,
    )
    db.add(row)
    db.commit()

    return UserActionLogCreateResponse(
        user_id=user.u_id,
        action_type=row.ual_action_type,
        parking_lot_id=row.ual_parking_lot_id,
        source_page=row.ual_source_page,
        created_at=now.strftime("%Y-%m-%d %H:%M:%S"),
    )
