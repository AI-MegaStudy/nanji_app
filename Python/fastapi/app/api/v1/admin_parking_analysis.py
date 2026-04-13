from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.services.admin_analytics import build_parking_analysis_overview

router = APIRouter(prefix="/admin/parking-analysis", tags=["admin"])


@router.get("/overview")
def get_admin_parking_analysis_overview(db: Session = Depends(get_db)):
    return build_parking_analysis_overview(db)
