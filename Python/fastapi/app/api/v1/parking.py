from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.parking import ParkingLot
from app.schemas.parking import ParkingLotItem, ParkingLotListResponse

router = APIRouter(prefix="/parking", tags=["parking"])


@router.get("/lots", response_model=ParkingLotListResponse)
def get_parking_lots(db: Session = Depends(get_db)) -> ParkingLotListResponse:
    parking_lots = db.query(ParkingLot).order_by(ParkingLot.p_display_name.asc()).all()

    items = []
    for parking_lot in parking_lots:
        items.append(
            ParkingLotItem(
                p_id=parking_lot.p_id,
                p_name=parking_lot.p_name,
                p_display_name=parking_lot.p_display_name,
                p_parking_type=parking_lot.p_parking_type,
                p_region_name=parking_lot.p_region_name,
                p_address=parking_lot.p_address,
                p_latitude=parking_lot.p_latitude,
                p_longitude=parking_lot.p_longitude,
                p_total_spaces=parking_lot.p_total_spaces,
                p_open_time=None if parking_lot.p_open_time is None else str(parking_lot.p_open_time),
                p_close_time=None if parking_lot.p_close_time is None else str(parking_lot.p_close_time),
                p_operating_status=parking_lot.p_operating_status,
                p_supports_realtime_congestion=parking_lot.p_supports_realtime_congestion,
                p_supports_prediction=parking_lot.p_supports_prediction,
                p_supports_departure_timing=parking_lot.p_supports_departure_timing,
                p_supports_map_view=parking_lot.p_supports_map_view,
                p_supports_favorite=parking_lot.p_supports_favorite,
                p_supports_notification=parking_lot.p_supports_notification,
            )
        )

    return ParkingLotListResponse(count=len(items), items=items)
