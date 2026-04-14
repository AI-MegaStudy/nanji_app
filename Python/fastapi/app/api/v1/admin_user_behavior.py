from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.admin_analytics import build_user_behavior_overview

router = APIRouter(prefix="/admin/user-behavior", tags=["admin"])


@router.get("/overview")
def get_admin_user_behavior_overview(db: Session = Depends(get_db)):
    return build_user_behavior_overview(db)
