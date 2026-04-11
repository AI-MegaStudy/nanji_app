from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import relationship

from app.db.base import Base


class UserNotificationSetting(Base):
    __tablename__ = "user_notification_setting"

    uns_id = Column(Integer, primary_key=True, index=True)
    uns_user_id = Column(Integer, ForeignKey("user.u_id"), nullable=False)
    uns_parking_lot_id = Column(Integer, ForeignKey("parking_lot.p_id"), nullable=True)
    uns_notification_type = Column(String(30), nullable=False)
    uns_is_enabled = Column(Boolean, nullable=False, server_default="1")
    uns_threshold_percent = Column(Numeric(5, 2), nullable=True)
    uns_minutes_before_departure = Column(Integer, nullable=True)
    uns_created_at = Column(DateTime, nullable=False)
    uns_updated_at = Column(DateTime, nullable=False)

    user = relationship("User", back_populates="notification_settings")
    parking_lot = relationship("ParkingLot", back_populates="notification_settings")


class NotificationLog(Base):
    __tablename__ = "notification_log"

    nl_id = Column(Integer, primary_key=True, index=True)
    nl_user_id = Column(Integer, ForeignKey("user.u_id"), nullable=False)
    nl_parking_lot_id = Column(Integer, ForeignKey("parking_lot.p_id"), nullable=True)
    nl_notification_type = Column(String(30), nullable=False)
    nl_title = Column(String(150), nullable=False)
    nl_body = Column(String(500), nullable=False)
    nl_send_status = Column(String(20), nullable=False, server_default="sent")
    nl_sent_at = Column(DateTime, nullable=True)
    nl_read_at = Column(DateTime, nullable=True)
    nl_created_at = Column(DateTime, nullable=False)
    nl_device_token_id = Column(Integer, ForeignKey("user_fcm_device_token.uf_id"), nullable=False)

    user = relationship("User", back_populates="notification_logs")
    parking_lot = relationship("ParkingLot", back_populates="notification_logs")
    device_token = relationship("UserFCMDeviceToken", back_populates="notification_logs")
