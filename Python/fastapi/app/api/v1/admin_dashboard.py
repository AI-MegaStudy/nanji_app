from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.admin_analytics import build_dashboard_overview

router = APIRouter(prefix="/admin/dashboard", tags=["admin"])


@router.get("/overview")
def get_admin_dashboard_overview(db: Session = Depends(get_db)):
    return build_dashboard_overview(db)
