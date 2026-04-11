from fastapi import APIRouter

from app.api.v1.db import router as db_router
from app.api.v1.parking import router as parking_router


router = APIRouter(prefix="/v1", tags=["v1"])
router.include_router(db_router)
router.include_router(parking_router)


@router.get("/ping")
def ping() -> dict[str, str]:
    return {"message": "pong"}
