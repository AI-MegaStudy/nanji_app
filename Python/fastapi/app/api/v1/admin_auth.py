import base64
import hashlib
import hmac
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import Admin
from app.schemas.admin_auth import AdminLoginRequest, AdminLoginResponse


router = APIRouter(prefix="/admin/auth", tags=["admin-auth"])

_PBKDF2_PREFIX = "pbkdf2_sha256"


def _derive_admin_login_id(email: str) -> str:
    normalized = (email or "").strip()
    if "@" in normalized:
        return normalized.split("@", 1)[0]
    return normalized


def _verify_pbkdf2_password(password: str, stored_hash: str) -> bool:
    try:
        algorithm, iterations_str, salt, digest = stored_hash.split("$", 3)
    except ValueError:
        return False

    if algorithm != _PBKDF2_PREFIX:
        return False

    try:
        iterations = int(iterations_str)
    except ValueError:
        return False

    computed = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        iterations,
    )
    encoded = base64.b64encode(computed).decode("utf-8")
    return hmac.compare_digest(encoded, digest)


def _verify_admin_password(password: str, stored_password: str) -> bool:
    normalized = (stored_password or "").strip()
    if not normalized:
        return False

    if normalized.startswith(f"{_PBKDF2_PREFIX}$"):
        return _verify_pbkdf2_password(password, normalized)

    # Backward-compatible fallback for existing plaintext admin rows.
    return hmac.compare_digest(password, normalized)


@router.post("/login", response_model=AdminLoginResponse)
def login_admin(
    payload: AdminLoginRequest,
    db: Session = Depends(get_db),
) -> AdminLoginResponse:
    login_id = payload.admin_id.strip()
    now = datetime.utcnow()

    admin = (
        db.query(Admin)
        .filter(
            Admin.a_status == "active",
            or_(
                Admin.a_email == login_id,
                Admin.a_email.like(f"{login_id}@%"),
            ),
        )
        .order_by(Admin.a_id.asc())
        .first()
    )

    if admin is None or not _verify_admin_password(payload.password, admin.a_password):
        raise HTTPException(status_code=401, detail="관리자 계정 정보가 올바르지 않습니다.")

    admin.a_last_login_at = now
    admin.a_updated_at = now
    db.commit()
    db.refresh(admin)

    return AdminLoginResponse(
        admin_id=admin.a_id,
        admin_login_id=_derive_admin_login_id(admin.a_email),
        admin_name=admin.a_name,
        admin_role=admin.a_role,
    )
