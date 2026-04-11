from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.db.base import Base


class User(Base):
    __tablename__ = "user"

    u_id = Column(Integer, primary_key=True, index=True)
    u_provider = Column(String(20), nullable=False)
    u_provider_user_id = Column(String(100), nullable=False)
    u_email = Column(String(255), nullable=True)
    u_name = Column(String(100), nullable=False)
    u_status = Column(String(20), nullable=False, server_default="active")
    u_terms_agreed_at = Column(DateTime, nullable=True)
    u_privacy_agreed_at = Column(DateTime, nullable=True)
    u_marketing_agreed = Column(Boolean, nullable=False, server_default="0")
    u_last_login_at = Column(DateTime, nullable=True)
    u_created_at = Column(DateTime, nullable=False)
    u_updated_at = Column(DateTime, nullable=False)

    fcm_device_tokens = relationship("UserFCMDeviceToken", back_populates="user")
    favorite_parking_lots = relationship("UserFavoriteParkingLot", back_populates="user")
    notification_settings = relationship("UserNotificationSetting", back_populates="user")
    notification_logs = relationship("NotificationLog", back_populates="user")
    action_logs = relationship("UserActionLog", back_populates="user")


class Admin(Base):
    __tablename__ = "admin"

    a_id = Column(Integer, primary_key=True, index=True)
    a_email = Column(String(255), nullable=False)
    a_password = Column(String(255), nullable=False)
    a_name = Column(String(100), nullable=False)
    a_role = Column(String(30), nullable=False, server_default="admin")
    a_status = Column(String(20), nullable=False, server_default="active")
    a_last_login_at = Column(DateTime, nullable=True)
    a_created_at = Column(DateTime, nullable=False)
    a_updated_at = Column(DateTime, nullable=False)


class UserFCMDeviceToken(Base):
    __tablename__ = "user_fcm_device_token"

    uf_id = Column(Integer, primary_key=True, index=True)
    uf_fcm_token = Column(String(255), nullable=False)
    uf_device_type = Column(String(20), nullable=False)
    uf_device_uuid = Column(String(120), nullable=True)
    uf_app_version = Column(String(30), nullable=True)
    uf_os_version = Column(String(30), nullable=True)
    uf_is_active = Column(Boolean, nullable=False, server_default="1")
    uf_last_used_at = Column(DateTime, nullable=True)
    uf_created_at = Column(DateTime, nullable=True)
    uf_updated_at = Column(DateTime, nullable=True)
    uf_user_id = Column(Integer, ForeignKey("user.u_id"), nullable=False)

    user = relationship("User", back_populates="fcm_device_tokens")
    notification_logs = relationship("NotificationLog", back_populates="device_token")
