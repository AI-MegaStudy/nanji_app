from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, Integer, Numeric, String, Text, Time
from sqlalchemy.orm import relationship

from app.db.base import Base


class ParkingLot(Base):
    __tablename__ = "parking_lot"

    p_id = Column(Integer, primary_key=True, index=True)
    p_name = Column(String(100), nullable=False)
    p_display_name = Column(String(120), nullable=False)
    p_parking_type = Column(String(30), nullable=False, server_default="public")
    p_region_name = Column(String(100), nullable=False)
    p_address = Column(String(255), nullable=True)
    p_latitude = Column(Numeric(10, 7), nullable=False)
    p_longitude = Column(Numeric(10, 7), nullable=False)
    p_total_spaces = Column(Integer, nullable=False, server_default="0")
    p_open_time = Column(Time, nullable=True)
    p_close_time = Column(Time, nullable=True)
    p_operating_status = Column(String(20), nullable=False, server_default="open")
    p_supports_realtime_congestion = Column(Boolean, nullable=False, server_default="1")
    p_supports_prediction = Column(Boolean, nullable=False, server_default="0")
    p_supports_departure_timing = Column(Boolean, nullable=False, server_default="0")
    p_supports_map_view = Column(Boolean, nullable=False, server_default="1")
    p_supports_favorite = Column(Boolean, nullable=False, server_default="1")
    p_supports_notification = Column(Boolean, nullable=False, server_default="1")
    p_created_at = Column(DateTime, nullable=False)
    p_updated_at = Column(DateTime, nullable=False)

    status_logs = relationship("ParkingStatusLog", back_populates="parking_lot")
    predictions = relationship("ParkingPrediction", back_populates="parking_lot")
    departure_recommendations = relationship("DepartureRecommendation", back_populates="parking_lot")
    favorite_links = relationship("UserFavoriteParkingLot", back_populates="parking_lot")
    notification_settings = relationship("UserNotificationSetting", back_populates="parking_lot")
    notification_logs = relationship("NotificationLog", back_populates="parking_lot")
    action_logs = relationship("UserActionLog", back_populates="parking_lot")


class ParkingStatusLog(Base):
    __tablename__ = "parking_status_log"

    ps_id = Column(Integer, primary_key=True, index=True)
    ps_recorded_at = Column(DateTime, nullable=False)
    ps_occupied_spaces = Column(Integer, nullable=False, server_default="0")
    ps_available_spaces = Column(Integer, nullable=False, server_default="0")
    ps_occupancy_rate = Column(Numeric(5, 2), nullable=False, server_default="0.00")
    ps_congestion_level = Column(String(20), nullable=False, server_default="normal")
    ps_source_type = Column(String(20), nullable=False, server_default="api")
    ps_created_at = Column(DateTime, nullable=False)
    ps_parking_lot_id = Column(Integer, ForeignKey("parking_lot.p_id"), nullable=False)

    parking_lot = relationship("ParkingLot", back_populates="status_logs")


class ParkingPrediction(Base):
    __tablename__ = "parking_prediction"

    pp_id = Column(Integer, primary_key=True, index=True)
    pp_base_time = Column(DateTime, nullable=False)
    pp_predicted_time = Column(DateTime, nullable=False)
    pp_prediction_horizon_minutes = Column(Integer, nullable=False, server_default="0")
    pp_predicted_occupied_spaces = Column(Integer, nullable=False, server_default="0")
    pp_predicted_available_spaces = Column(Integer, nullable=False, server_default="0")
    pp_predicted_occupancy_rate = Column(Numeric(5, 2), nullable=False, server_default="0.00")
    pp_predicted_congestion_level = Column(String(20), nullable=False, server_default="normal")
    pp_confidence_score = Column(Numeric(5, 2), nullable=True)
    pp_model_version = Column(String(50), nullable=True)
    pp_created_at = Column(DateTime, nullable=True)
    pp_parking_lot_id = Column(Integer, ForeignKey("parking_lot.p_id"), nullable=False)

    parking_lot = relationship("ParkingLot", back_populates="predictions")


class DepartureRecommendation(Base):
    __tablename__ = "departure_recommendation"

    dr_id = Column(Integer, primary_key=True, index=True)
    dr_target_date = Column(Date, nullable=False)
    dr_recommended_arrival_time = Column(DateTime, nullable=True)
    dr_recommended_departure_time = Column(DateTime, nullable=True)
    dr_busy_time_start = Column(DateTime, nullable=True)
    dr_busy_time_end = Column(DateTime, nullable=True)
    dr_free_time_start = Column(DateTime, nullable=True)
    dr_free_time_end = Column(DateTime, nullable=True)
    dr_recommended_message = Column(String(255), nullable=True)
    dr_reason_summary = Column(Text, nullable=True)
    dr_created_at = Column(DateTime, nullable=True)
    dr_parking_lot_id = Column(Integer, ForeignKey("parking_lot.p_id"), nullable=False)

    parking_lot = relationship("ParkingLot", back_populates="departure_recommendations")
