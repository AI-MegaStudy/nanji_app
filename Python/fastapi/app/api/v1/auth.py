from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.action_log import UserActionLog
from app.models.user import User
from app.schemas.auth import SocialLoginRequest, SocialLoginResponse


router = APIRouter(prefix="/auth", tags=["auth"])


def _fallback_name(provider: str) -> str:
    provider_label = {
        "google": "Google",
        "kakao": "카카오",
        "naver": "네이버",
        "apple": "Apple",
    }.get(provider.lower(), provider)
    return f"{provider_label} 사용자"


@router.post("/social-login", response_model=SocialLoginResponse)
def upsert_social_login(
    payload: SocialLoginRequest,
    db: Session = Depends(get_db),
) -> SocialLoginResponse:
    provider = payload.provider.strip().lower()
    provider_user_id = payload.provider_user_id.strip()

    if not provider:
        raise HTTPException(status_code=400, detail="provider is required")

    if not provider_user_id:
        raise HTTPException(status_code=400, detail="provider_user_id is required")

    now = datetime.utcnow()
    user = (
        db.query(User)
        .filter(
            User.u_provider == provider,
            User.u_provider_user_id == provider_user_id,
        )
        .first()
    )

    is_new_user = user is None
    if user is None:
        user = User(
            u_provider=provider,
            u_provider_user_id=provider_user_id,
            u_email=payload.email,
            u_name=(payload.name or "").strip() or _fallback_name(provider),
            u_status="active",
            u_marketing_agreed=False,
            u_last_login_at=now,
            u_created_at=now,
            u_updated_at=now,
        )
        db.add(user)
    else:
        if payload.email:
            user.u_email = payload.email
        if payload.name and payload.name.strip():
            user.u_name = payload.name.strip()
        user.u_status = "active"
        user.u_last_login_at = now
        user.u_updated_at = now

    db.commit()
    db.refresh(user)

    login_log = UserActionLog(
        ual_user_id=user.u_id,
        ual_parking_lot_id=None,
        ual_action_type="login",
        ual_action_target=provider,
        ual_action_value="success",
        ual_source_page="login",
        ual_session_id=None,
        ual_created_at=now,
    )
    db.add(login_log)
    db.commit()

    return SocialLoginResponse(
        user_id=user.u_id,
        provider=user.u_provider,
        provider_user_id=user.u_provider_user_id,
        email=user.u_email,
        name=user.u_name,
        is_new_user=is_new_user,
    )
