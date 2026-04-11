from app.models.action_log import UserActionLog, UserFavoriteParkingLot
from app.models.notification import NotificationLog, UserNotificationSetting
from app.models.parking import DepartureRecommendation, ParkingLot, ParkingPrediction, ParkingStatusLog
from app.models.user import Admin, User, UserFCMDeviceToken

__all__ = [
    "Admin",
    "DepartureRecommendation",
    "NotificationLog",
    "ParkingLot",
    "ParkingPrediction",
    "ParkingStatusLog",
    "User",
    "UserActionLog",
    "UserFCMDeviceToken",
    "UserFavoriteParkingLot",
    "UserNotificationSetting",
]
