from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.db.base import Base


class UserFavoriteParkingLot(Base):
    __tablename__ = "user_favorite_parking_lot"

    ufp_id = Column(Integer, primary_key=True, index=True)
    ufp_user_id = Column(Integer, ForeignKey("user.u_id"), nullable=False)
    ufp_parking_lot_id = Column(Integer, ForeignKey("parking_lot.p_id"), nullable=False)
    ufp_created_at = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="favorite_parking_lots")
    parking_lot = relationship("ParkingLot", back_populates="favorite_links")


class UserActionLog(Base):
    __tablename__ = "user_action_log"

    ual_id = Column(Integer, primary_key=True, index=True)
    ual_user_id = Column(Integer, ForeignKey("user.u_id"), nullable=False)
    ual_parking_lot_id = Column(Integer, ForeignKey("parking_lot.p_id"), nullable=True)
    ual_action_type = Column(String(50), nullable=False)
    ual_action_target = Column(String(100), nullable=True)
    ual_action_value = Column(String(255), nullable=True)
    ual_source_page = Column(String(50), nullable=True)
    ual_session_id = Column(String(100), nullable=True)
    ual_created_at = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="action_logs")
    parking_lot = relationship("ParkingLot", back_populates="action_logs")
