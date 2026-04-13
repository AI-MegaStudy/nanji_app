from datetime import date, datetime, time, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.parking import ParkingLot, ParkingStatusLog
from app.schemas.parking import (
    ParkingCurrentStatusItem,
    ParkingCurrentStatusResponse,
    ParkingStatusHistoryResponse,
    ParkingLotItem,
    ParkingLotListResponse,
)

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


@router.get("/current/{parking_lot_id}", response_model=ParkingCurrentStatusResponse)
def get_current_parking_status(parking_lot_id: int, db: Session = Depends(get_db)) -> ParkingCurrentStatusResponse:
    parking_lot = db.query(ParkingLot).filter(ParkingLot.p_id == parking_lot_id).first()
    if parking_lot is None:
        raise HTTPException(status_code=404, detail=f"parking_lot not found: {parking_lot_id}")

    latest_status = (
        db.query(ParkingStatusLog)
        .filter(
            ParkingStatusLog.ps_parking_lot_id == parking_lot_id,
            ParkingStatusLog.ps_source_type != "manual_test",
        )
        .order_by(ParkingStatusLog.ps_recorded_at.desc(), ParkingStatusLog.ps_id.desc())
        .first()
    )

    if latest_status is None:
        return ParkingCurrentStatusResponse(
            parking_lot_id=parking_lot.p_id,
            parking_lot_name=parking_lot.p_display_name,
            total_spaces=int(parking_lot.p_total_spaces),
            supports_realtime_congestion=parking_lot.p_supports_realtime_congestion,
            has_data=False,
            message="현재 실시간 주차 현황 데이터가 없습니다.",
        )

    return ParkingCurrentStatusResponse(
        parking_lot_id=parking_lot.p_id,
        parking_lot_name=parking_lot.p_display_name,
        total_spaces=latest_status.ps_occupied_spaces + latest_status.ps_available_spaces,
        supports_realtime_congestion=parking_lot.p_supports_realtime_congestion,
        has_data=True,
        item=ParkingCurrentStatusItem(
            ps_id=latest_status.ps_id,
            ps_parking_lot_id=latest_status.ps_parking_lot_id,
            ps_recorded_at=latest_status.ps_recorded_at.strftime("%Y-%m-%d %H:%M:%S"),
            ps_occupied_spaces=latest_status.ps_occupied_spaces,
            ps_available_spaces=latest_status.ps_available_spaces,
            ps_occupancy_rate=latest_status.ps_occupancy_rate,
            ps_congestion_level=latest_status.ps_congestion_level,
            ps_source_type=latest_status.ps_source_type,
        ),
    )


@router.get("/history/{parking_lot_id}", response_model=ParkingStatusHistoryResponse)
def get_parking_status_history(
    parking_lot_id: int,
    target_date: Optional[date] = None,
    db: Session = Depends(get_db),
) -> ParkingStatusHistoryResponse:
    parking_lot = db.query(ParkingLot).filter(ParkingLot.p_id == parking_lot_id).first()
    if parking_lot is None:
        raise HTTPException(status_code=404, detail=f"parking_lot not found: {parking_lot_id}")

    effective_date = target_date or datetime.now().date()
    day_start = datetime.combine(effective_date, time.min)
    next_day_start = day_start + timedelta(days=1)

    status_logs = (
        db.query(ParkingStatusLog)
        .filter(
            ParkingStatusLog.ps_parking_lot_id == parking_lot_id,
            ParkingStatusLog.ps_recorded_at >= day_start,
            ParkingStatusLog.ps_recorded_at < next_day_start,
        )
        .order_by(ParkingStatusLog.ps_recorded_at.asc(), ParkingStatusLog.ps_id.asc())
        .all()
    )

    items = []
    for status in status_logs:
        items.append(
            ParkingCurrentStatusItem(
                ps_id=status.ps_id,
                ps_parking_lot_id=status.ps_parking_lot_id,
                ps_recorded_at=status.ps_recorded_at.strftime("%Y-%m-%d %H:%M:%S"),
                ps_occupied_spaces=status.ps_occupied_spaces,
                ps_available_spaces=status.ps_available_spaces,
                ps_occupancy_rate=status.ps_occupancy_rate,
                ps_congestion_level=status.ps_congestion_level,
                ps_source_type=status.ps_source_type,
            )
        )

    return ParkingStatusHistoryResponse(
        parking_lot_id=parking_lot.p_id,
        parking_lot_name=parking_lot.p_display_name,
        target_date=effective_date.isoformat(),
        count=len(items),
        items=items,
    )
