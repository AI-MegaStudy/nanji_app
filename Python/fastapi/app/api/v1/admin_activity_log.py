from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.admin_analytics import build_activity_log_overview

router = APIRouter(prefix="/admin/activity-log", tags=["admin"])


@router.get("/overview")
def get_admin_activity_log_overview(db: Session = Depends(get_db)):
    return build_activity_log_overview(db)
