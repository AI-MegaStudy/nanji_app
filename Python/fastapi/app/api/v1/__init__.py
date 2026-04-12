from fastapi import APIRouter

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


@router.get("/ping")
def ping() -> dict[str, str]:
    return {"message": "pong"}
