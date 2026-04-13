from fastapi import APIRouter

from app.api.v1.admin_activity_log import router as admin_activity_log_router
from app.api.v1.admin_dashboard import router as admin_dashboard_router
from app.api.v1.admin_parking_analysis import router as admin_parking_analysis_router
from app.api.v1.admin_prediction_analysis import router as admin_prediction_analysis_router
from app.api.v1.admin_user_behavior import router as admin_user_behavior_router
from app.api.v1.auth import router as auth_router
from app.api.v1.db import router as db_router
from app.api.v1.parking import router as parking_router
from app.api.v1.prediction import router as prediction_router
from app.api.v1.user_pref import router as user_pref_router


router = APIRouter(prefix="/v1", tags=["v1"])
router.include_router(auth_router)
router.include_router(db_router)
router.include_router(parking_router)
router.include_router(prediction_router)
router.include_router(user_pref_router)
router.include_router(admin_dashboard_router)
router.include_router(admin_parking_analysis_router)
router.include_router(admin_prediction_analysis_router)
router.include_router(admin_user_behavior_router)
router.include_router(admin_activity_log_router)


@router.get("/ping")
def ping() -> dict[str, str]:
    return {"message": "pong"}
