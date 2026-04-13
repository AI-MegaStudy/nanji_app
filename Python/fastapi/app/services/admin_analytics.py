from collections import Counter, defaultdict
from datetime import date, datetime, timedelta
from typing import Any, Dict, Iterable, List, Optional, Tuple

from sqlalchemy.orm import Session

from app.models.action_log import UserActionLog, UserFavoriteParkingLot
from app.models.notification import NotificationLog, UserNotificationSetting
from app.models.parking import ParkingLot, ParkingPrediction, ParkingStatusLog
from app.models.user import User


ACTION_LABELS = {
    "login": "로그인",
    "congestion_view": "혼잡도 조회",
    "prediction_view": "예측 조회",
    "departure_timing_view": "출발 타이밍",
    "map_view": "지도 보기",
    "favorite_add": "즐겨찾기 추가",
    "favorite_remove": "즐겨찾기 제거",
    "notification_set": "알림 설정",
}

FUNNEL_ACTIONS = [
    ("login", "로그인"),
    ("congestion_view", "혼잡도 확인"),
    ("prediction_view", "예측 확인"),
    ("departure_timing_view", "출발 타이밍"),
    ("map_or_favorite", "지도/즐겨찾기"),
]

WEEKDAY_LABELS = ["월", "화", "수", "목", "금", "토", "일"]


def _fmt_datetime(value: Optional[datetime]) -> str:
    if value is None:
        return "-"
    return value.strftime("%Y-%m-%d %H:%M:%S")


def _fmt_relative_time(value: Optional[datetime], now: datetime) -> str:
    if value is None:
        return "-"
    delta = now - value
    minutes = max(0, int(delta.total_seconds() // 60))
    if minutes < 1:
        return "방금 전"
    if minutes < 60:
        return f"{minutes}분 전"
    hours = minutes // 60
    if hours < 24:
        return f"{hours}시간 전"
    return f"{delta.days}일 전"


def _safe_rate(part: int, total: int) -> int:
    if total <= 0:
        return 0
    return int(round((part / total) * 100))


def _safe_float_rate(part: int, total: int) -> float:
    if total <= 0:
        return 0.0
    return round((part / total) * 100, 2)


def _get_parking_lots(db: Session) -> List[ParkingLot]:
    return db.query(ParkingLot).order_by(ParkingLot.p_id.asc()).all()


def _get_latest_status_by_lot(db: Session) -> Dict[int, ParkingStatusLog]:
    result: Dict[int, ParkingStatusLog] = {}
    parking_lots = _get_parking_lots(db)
    for parking_lot in parking_lots:
        row = (
            db.query(ParkingStatusLog)
            .filter(
                ParkingStatusLog.ps_parking_lot_id == parking_lot.p_id,
                ParkingStatusLog.ps_source_type != "manual_test",
            )
            .order_by(ParkingStatusLog.ps_recorded_at.desc(), ParkingStatusLog.ps_id.desc())
            .first()
        )
        if row is not None:
            result[parking_lot.p_id] = row
    return result


def _load_action_logs(
    db: Session,
    since: Optional[datetime] = None,
) -> List[UserActionLog]:
    query = db.query(UserActionLog)
    if since is not None:
        query = query.filter(UserActionLog.ual_created_at >= since)
    return query.order_by(UserActionLog.ual_created_at.asc(), UserActionLog.ual_id.asc()).all()


def _load_predictions(
    db: Session,
    since: Optional[datetime] = None,
) -> List[ParkingPrediction]:
    query = db.query(ParkingPrediction)
    if since is not None:
        query = query.filter(ParkingPrediction.pp_predicted_time >= since)
    return query.order_by(ParkingPrediction.pp_predicted_time.asc(), ParkingPrediction.pp_id.asc()).all()


def _build_hourly_usage(logs: Iterable[UserActionLog]) -> List[Dict[str, int]]:
    counter = Counter()
    for log in logs:
        if log.ual_created_at is not None:
            counter[log.ual_created_at.hour] += 1
    return [{"hour": hour, "value": counter.get(hour, 0)} for hour in range(24)]


def _build_feature_usage(logs: Iterable[UserActionLog]) -> List[Dict[str, Any]]:
    keys = [
        ("congestion_view", "혼잡도 조회"),
        ("prediction_view", "예측 조회"),
        ("departure_timing_view", "출발 타이밍"),
        ("map_view", "지도 보기"),
        ("favorite_total", "즐겨찾기"),
    ]
    counter = Counter(log.ual_action_type for log in logs)
    favorite_total = counter.get("favorite_add", 0) + counter.get("favorite_remove", 0)
    values = {
        "congestion_view": counter.get("congestion_view", 0),
        "prediction_view": counter.get("prediction_view", 0),
        "departure_timing_view": counter.get("departure_timing_view", 0),
        "map_view": counter.get("map_view", 0),
        "favorite_total": favorite_total,
    }
    return [{"key": key, "name": label, "value": values[key]} for key, label in keys]


def _build_funnel(logs: Iterable[UserActionLog]) -> List[Dict[str, Any]]:
    users_by_key: Dict[str, set] = defaultdict(set)
    for log in logs:
        if log.ual_user_id is None:
            continue
        if log.ual_action_type == "map_view":
            users_by_key["map_or_favorite"].add(log.ual_user_id)
        if log.ual_action_type in ("favorite_add", "favorite_remove"):
            users_by_key["map_or_favorite"].add(log.ual_user_id)
        users_by_key[log.ual_action_type].add(log.ual_user_id)

    base_count = len(users_by_key.get("login", set()))
    if base_count == 0:
        base_count = len({log.ual_user_id for log in logs if log.ual_user_id is not None})

    funnel = []
    for key, label in FUNNEL_ACTIONS:
        count = len(users_by_key.get(key, set()))
        funnel.append(
            {
                "key": key,
                "label": label,
                "count": count,
                "rate": _safe_rate(count, base_count),
            }
        )
    return funnel


def _build_parking_overview(
    parking_lot: Optional[ParkingLot],
    latest_status: Optional[ParkingStatusLog],
    now: datetime,
) -> Dict[str, Any]:
    if parking_lot is None:
        return {
            "parking_lot_id": 0,
            "parking_lot_name": "정보 없음",
            "total_spaces": 0,
            "available_spaces": 0,
            "occupied_spaces": 0,
            "occupancy_rate": 0,
            "congestion_level": "unknown",
            "has_realtime_data": False,
        }

    total_spaces = int(parking_lot.p_total_spaces or 0)
    available_spaces = 0
    occupied_spaces = 0
    occupancy_rate = 0.0
    congestion_level = "unknown"
    has_realtime_data = False

    if latest_status is not None:
        total_spaces = max(total_spaces, latest_status.ps_available_spaces + latest_status.ps_occupied_spaces)
        available_spaces = int(latest_status.ps_available_spaces or 0)
        occupied_spaces = int(latest_status.ps_occupied_spaces or 0)
        occupancy_rate = float(latest_status.ps_occupancy_rate or 0)
        congestion_level = latest_status.ps_congestion_level or "unknown"
        has_realtime_data = True

    return {
        "parking_lot_id": parking_lot.p_id,
        "parking_lot_name": parking_lot.p_display_name,
        "total_spaces": total_spaces,
        "available_spaces": available_spaces,
        "occupied_spaces": occupied_spaces,
        "occupancy_rate": round(occupancy_rate, 2),
        "congestion_level": congestion_level,
        "has_realtime_data": has_realtime_data,
    }


def build_dashboard_overview(db: Session) -> Dict[str, Any]:
    now = datetime.now()
    today_start = datetime.combine(date.today(), datetime.min.time())
    today_logs = _load_action_logs(db, since=today_start)
    latest_status_map = _get_latest_status_by_lot(db)
    parking_lots = _get_parking_lots(db)
    main_lot = next((lot for lot in parking_lots if lot.p_id == 1), parking_lots[0] if parking_lots else None)
    main_status = latest_status_map.get(main_lot.p_id) if main_lot is not None else None
    feature_usage = _build_feature_usage(today_logs)
    feature_counts = {item["key"]: item["value"] for item in feature_usage}
    login_users = {log.ual_user_id for log in today_logs if log.ual_action_type == "login" and log.ual_user_id is not None}
    if not login_users:
        login_users = {log.ual_user_id for log in today_logs if log.ual_user_id is not None}

    favorite_count = db.query(UserFavoriteParkingLot).count()
    metrics = [
        {
            "key": "today_visitors",
            "label": "오늘 방문자",
            "value": len(login_users),
            "display_value": f"{len(login_users):,}명",
        },
        {
            "key": "congestion_views",
            "label": "혼잡도 조회",
            "value": feature_counts.get("congestion_view", 0),
            "display_value": f"{feature_counts.get('congestion_view', 0):,}회",
        },
        {
            "key": "prediction_views",
            "label": "예측 조회",
            "value": feature_counts.get("prediction_view", 0),
            "display_value": f"{feature_counts.get('prediction_view', 0):,}회",
        },
        {
            "key": "departure_timing_views",
            "label": "출발 타이밍",
            "value": feature_counts.get("departure_timing_view", 0),
            "display_value": f"{feature_counts.get('departure_timing_view', 0):,}회",
        },
        {
            "key": "map_views",
            "label": "지도 클릭",
            "value": feature_counts.get("map_view", 0),
            "display_value": f"{feature_counts.get('map_view', 0):,}회",
        },
        {
            "key": "favorites",
            "label": "즐겨찾기",
            "value": favorite_count,
            "display_value": f"{favorite_count:,}건",
        },
    ]

    user_login_counts = Counter(
        log.ual_user_id for log in db.query(UserActionLog).filter(UserActionLog.ual_action_type == "login").all()
        if log.ual_user_id is not None
    )
    returning_users = sum(1 for user_id in login_users if user_login_counts.get(user_id, 0) > 1)
    prediction_views = feature_counts.get("prediction_view", 0)
    departure_views = feature_counts.get("departure_timing_view", 0)
    hourly_usage = _build_hourly_usage(today_logs)
    peak_hour_item = max(hourly_usage, key=lambda item: item["value"]) if hourly_usage else {"hour": 0, "value": 0}
    insights = [
        {
            "id": 1,
            "type": "info",
            "message": f"오늘 접속 사용자 중 {_safe_rate(returning_users, len(login_users))}%가 재방문 사용자입니다.",
            "time": _fmt_relative_time(now - timedelta(minutes=10), now),
        },
        {
            "id": 2,
            "type": "warning",
            "message": f"예측 조회 대비 출발 타이밍 전환율은 {_safe_rate(departure_views, prediction_views)}%입니다.",
            "time": _fmt_relative_time(now - timedelta(minutes=25), now),
        },
        {
            "id": 3,
            "type": "info",
            "message": f"오늘 가장 활동이 많은 시간대는 {peak_hour_item['hour']}시입니다.",
            "time": _fmt_relative_time(now - timedelta(hours=1), now),
        },
    ]

    return {
        "generated_at": _fmt_datetime(now),
        "metrics": metrics,
        "parking_overview": _build_parking_overview(main_lot, main_status, now),
        "insights": insights,
        "hourly_usage": hourly_usage,
        "feature_usage": feature_usage,
        "funnel": _build_funnel(today_logs),
    }


def build_parking_analysis_overview(db: Session) -> Dict[str, Any]:
    now = datetime.now()
    lots = _get_parking_lots(db)
    latest_status_map = _get_latest_status_by_lot(db)
    action_logs = _load_action_logs(db)
    favorites = db.query(UserFavoriteParkingLot).all()

    favorite_counter = Counter(row.ufp_parking_lot_id for row in favorites if row.ufp_parking_lot_id is not None)
    selection_counter = Counter(log.ual_parking_lot_id for log in action_logs if log.ual_parking_lot_id is not None)
    map_counter = Counter(
        log.ual_parking_lot_id
        for log in action_logs
        if log.ual_action_type == "map_view" and log.ual_parking_lot_id is not None
    )

    lot_rows = []
    for lot in lots:
        status = latest_status_map.get(lot.p_id)
        occupancy_rate = float(status.ps_occupancy_rate or 0) if status is not None else 0.0
        lot_rows.append(
            {
                "id": lot.p_id,
                "display_name": lot.p_display_name,
                "total_spaces": int(lot.p_total_spaces or 0),
                "supports_realtime": bool(lot.p_supports_realtime_congestion),
                "supports_prediction": bool(lot.p_supports_prediction),
                "available_spaces": int(status.ps_available_spaces or 0) if status is not None else 0,
                "occupied_spaces": int(status.ps_occupied_spaces or 0) if status is not None else 0,
                "occupancy_rate": round(occupancy_rate, 2),
                "status_label": "운영 중" if status is not None else "정보 준비 중",
                "has_realtime_data": status is not None,
            }
        )

    total_map_actions = sum(map_counter.values())
    total_actions = len(action_logs)
    most_popular_lot_id = favorite_counter.most_common(1)[0][0] if favorite_counter else None
    most_popular_name = next((lot.p_display_name for lot in lots if lot.p_id == most_popular_lot_id), "-")

    selection_data = [
        {"label": lot.p_display_name, "count": selection_counter.get(lot.p_id, 0)}
        for lot in lots
    ]
    map_usage_data = [
        {"label": lot.p_display_name, "count": map_counter.get(lot.p_id, 0)}
        for lot in lots
    ]

    session_spans: List[float] = []
    session_logs: Dict[str, List[datetime]] = defaultdict(list)
    for log in action_logs:
        if log.ual_session_id and log.ual_created_at:
            session_logs[log.ual_session_id].append(log.ual_created_at)
    for timestamps in session_logs.values():
        timestamps.sort()
        session_spans.append((timestamps[-1] - timestamps[0]).total_seconds() / 60)

    duration_buckets = {"0~5분": 0, "5~15분": 0, "15분+": 0}
    for span in session_spans:
        if span < 5:
            duration_buckets["0~5분"] += 1
        elif span < 15:
            duration_buckets["5~15분"] += 1
        else:
            duration_buckets["15분+"] += 1
    avg_duration_data = [{"label": key, "count": value} for key, value in duration_buckets.items()]

    weekday_lot_counts: Dict[int, Counter] = defaultdict(Counter)
    for log in action_logs:
        if log.ual_created_at is None or log.ual_parking_lot_id is None:
            continue
        weekday_lot_counts[log.ual_created_at.weekday()][log.ual_parking_lot_id] += 1

    weekly_parking_data = []
    for idx, label in enumerate(WEEKDAY_LABELS):
        top_counts = weekday_lot_counts.get(idx, Counter()).most_common(3)
        values = [item[1] for item in top_counts] + [0, 0, 0]
        weekly_parking_data.append(
            {
                "label": label,
                "primary": values[0],
                "secondary": values[1],
                "tertiary": values[2],
            }
        )

    favorite_ranking = []
    previous = None
    for index, (lot_id, count) in enumerate(favorite_counter.most_common(5), start=1):
        lot_name = next((lot.p_display_name for lot in lots if lot.p_id == lot_id), "-")
        change = 0 if previous is None else count - previous
        trend = "up" if change > 0 else "down" if change < 0 else "same"
        favorite_ranking.append(
            {"rank": index, "name": lot_name, "count": count, "trend": trend, "change": abs(change)}
        )
        previous = count

    return {
        "generated_at": _fmt_datetime(now),
        "metrics": [
            {"key": "favorites_total", "label": "총 즐겨찾기", "value": f"{sum(favorite_counter.values()):,}건"},
            {"key": "map_usage_rate", "label": "지도 사용률", "value": f"{_safe_rate(total_map_actions, total_actions)}%"},
            {"key": "popular_lot", "label": "가장 인기있는 주차장", "value": most_popular_name},
        ],
        "lot_rows": lot_rows,
        "selection_data": selection_data,
        "map_usage_data": map_usage_data,
        "avg_duration_data": avg_duration_data,
        "weekly_parking_data": weekly_parking_data,
        "favorite_ranking": favorite_ranking,
    }


def build_prediction_analysis_overview(db: Session) -> Dict[str, Any]:
    now = datetime.now()
    predictions = _load_predictions(db)
    action_logs = _load_action_logs(db)
    prediction_views = [log for log in action_logs if log.ual_action_type == "prediction_view"]
    departure_views = [log for log in action_logs if log.ual_action_type == "departure_timing_view"]

    by_hour = Counter()
    departure_by_hour = Counter()
    hourly_pattern_counter: Dict[int, Counter] = defaultdict(Counter)
    weekly_prediction_counter: Dict[int, Counter] = defaultdict(Counter)
    congestion_counter = Counter()
    accuracy_groups: Dict[str, List[float]] = defaultdict(list)

    for prediction in predictions:
        if prediction.pp_predicted_time is None:
            continue
        hour = prediction.pp_predicted_time.hour
        weekday = prediction.pp_predicted_time.weekday()
        by_hour[hour] += 1
        level = prediction.pp_predicted_congestion_level or "unknown"
        hourly_pattern_counter[hour][level] += 1
        weekly_prediction_counter[weekday][level] += 1
        congestion_counter[level] += 1
        horizon = prediction.pp_prediction_horizon_minutes or 0
        if horizon <= 60:
            group_key = "1시간 이내"
        elif horizon <= 120:
            group_key = "2시간 이내"
        else:
            group_key = "3시간 이상"
        if prediction.pp_confidence_score is not None:
            accuracy_groups[group_key].append(float(prediction.pp_confidence_score))

    for log in departure_views:
        if log.ual_created_at is not None:
            departure_by_hour[log.ual_created_at.hour] += 1

    prediction_by_hour = [{"label": f"{hour}시", "count": by_hour.get(hour, 0)} for hour in range(24)]
    departure_timing = [{"label": f"{hour}시", "count": departure_by_hour.get(hour, 0)} for hour in range(24)]

    def _level_counts(counter: Counter) -> Tuple[int, int, int]:
        return (
            counter.get("free", 0),
            counter.get("normal", 0),
            counter.get("busy", 0) + counter.get("very_busy", 0),
        )

    hourly_pattern = []
    for hour in range(24):
        free_count, normal_count, busy_count = _level_counts(hourly_pattern_counter.get(hour, Counter()))
        hourly_pattern.append(
            {"label": f"{hour}시", "primary": free_count, "secondary": normal_count, "tertiary": busy_count}
        )

    weekly_prediction = []
    for idx, label in enumerate(WEEKDAY_LABELS):
        free_count, normal_count, busy_count = _level_counts(weekly_prediction_counter.get(idx, Counter()))
        weekly_prediction.append(
            {"label": label, "primary": free_count, "secondary": normal_count, "tertiary": busy_count}
        )

    accuracy_trend = []
    for label in ["1시간 이내", "2시간 이내", "3시간 이상"]:
        values = accuracy_groups.get(label, [])
        average = int(round(sum(values) / len(values) * 100)) if values else 0
        accuracy_trend.append({"label": label, "accuracy": average, "usage": len(values)})

    prediction_user_ids = {log.ual_user_id for log in prediction_views if log.ual_user_id is not None}
    post_action_defs = [
        ("departure_timing_view", "출발 타이밍 이동"),
        ("map_view", "지도 보기"),
        ("favorite_add", "즐겨찾기 추가"),
    ]
    post_actions = []
    for key, label in post_action_defs:
        count = sum(1 for log in action_logs if log.ual_action_type == key and log.ual_user_id in prediction_user_ids)
        post_actions.append(
            {
                "label": label,
                "count": count,
                "rate": _safe_float_rate(count, len(prediction_views)),
            }
        )

    current_statuses = _get_latest_status_by_lot(db)
    current_congestion_counter = Counter(
        status.ps_congestion_level or "unknown" for status in current_statuses.values()
    )
    congestion_prediction = []
    for label, key in [("여유", "free"), ("보통", "normal"), ("혼잡", "busy")]:
        prediction_count = congestion_counter.get(key, 0)
        if key == "busy":
            prediction_count += congestion_counter.get("very_busy", 0)
        current_count = current_congestion_counter.get(key, 0)
        if key == "busy":
            current_count += current_congestion_counter.get("very_busy", 0)
        congestion_prediction.append(
            {"label": label, "prediction": prediction_count, "no_prediction": current_count}
        )

    peak_hour = max(by_hour.items(), key=lambda item: item[1])[0] if by_hour else 0
    avg_occupancy = int(round(sum(float(p.pp_predicted_occupancy_rate or 0) for p in predictions) / len(predictions))) if predictions else 0

    return {
        "generated_at": _fmt_datetime(now),
        "metrics": [
            {"key": "prediction_count", "label": "예측 적재 수", "value": f"{len(predictions):,}건"},
            {"key": "avg_occupancy", "label": "평균 예측 점유율", "value": f"{avg_occupancy}%"},
            {"key": "peak_prediction_hour", "label": "가장 많이 조회된 예측 시간", "value": f"{peak_hour}시"},
            {"key": "departure_views", "label": "출발 타이밍 조회", "value": f"{len(departure_views):,}회"},
        ],
        "prediction_by_hour": prediction_by_hour,
        "departure_timing": departure_timing,
        "hourly_pattern": hourly_pattern,
        "weekly_prediction": weekly_prediction,
        "accuracy_trend": accuracy_trend,
        "post_actions": post_actions,
        "congestion_prediction": congestion_prediction,
        "prediction_insight": f"예측 데이터는 {peak_hour}시에 가장 많이 생성되거나 조회되었습니다.",
        "departure_insight": f"예측 조회 대비 출발 타이밍 전환율은 {_safe_rate(len(departure_views), len(prediction_views))}%입니다.",
        "hourly_insight": f"현재 적재된 예측은 평균 점유율 {avg_occupancy}% 수준입니다.",
        "congestion_insight": "혼잡도 분포는 예측 데이터와 최신 실시간 상태를 함께 비교합니다.",
    }


def build_user_behavior_overview(db: Session) -> Dict[str, Any]:
    now = datetime.now()
    logs = _load_action_logs(db)
    today_start = datetime.combine(date.today(), datetime.min.time())
    today_logs = [log for log in logs if log.ual_created_at is not None and log.ual_created_at >= today_start]
    unique_users = {log.ual_user_id for log in logs if log.ual_user_id is not None}
    active_users_today = {log.ual_user_id for log in today_logs if log.ual_user_id is not None}

    funnel_steps = _build_funnel(logs)

    session_candidates: Dict[Tuple[int, date], List[datetime]] = defaultdict(list)
    for log in logs:
        if log.ual_user_id is None or log.ual_created_at is None:
            continue
        session_candidates[(log.ual_user_id, log.ual_created_at.date())].append(log.ual_created_at)
    session_durations = {"0~5분": 0, "5~15분": 0, "15분+": 0}
    for timestamps in session_candidates.values():
        timestamps.sort()
        minutes = (timestamps[-1] - timestamps[0]).total_seconds() / 60
        if minutes < 5:
            session_durations["0~5분"] += 1
        elif minutes < 15:
            session_durations["5~15분"] += 1
        else:
            session_durations["15분+"] += 1

    login_counts = Counter(
        log.ual_user_id for log in logs if log.ual_action_type == "login" and log.ual_user_id is not None
    )
    returning_count = sum(1 for count in login_counts.values() if count > 1)
    new_count = max(0, len(login_counts) - returning_count)
    return_patterns = [
        {"label": "신규 사용자", "count": new_count, "percentage": _safe_rate(new_count, len(login_counts))},
        {"label": "재방문 사용자", "count": returning_count, "percentage": _safe_rate(returning_count, len(login_counts))},
    ]

    weekly_users: Dict[int, set] = defaultdict(set)
    weekly_actions = Counter()
    for log in logs:
        if log.ual_created_at is None:
            continue
        weekday = log.ual_created_at.weekday()
        if log.ual_user_id is not None:
            weekly_users[weekday].add(log.ual_user_id)
        weekly_actions[weekday] += 1
    weekly_active_users = [
        {
            "label": label,
            "primary": len(weekly_users.get(index, set())),
            "secondary": weekly_actions.get(index, 0),
        }
        for index, label in enumerate(WEEKDAY_LABELS)
    ]

    feature_counter = Counter(log.ual_action_type for log in logs)
    feature_frequency = [
        {"label": ACTION_LABELS.get(key, key), "count": count}
        for key, count in feature_counter.most_common(8)
    ]

    notification_enabled = (
        db.query(UserNotificationSetting)
        .filter(UserNotificationSetting.uns_is_enabled == True)
        .count()
    )
    notification_logs = db.query(NotificationLog).all()
    notification_read = sum(1 for row in notification_logs if row.nl_read_at is not None)
    notification_sent = len(notification_logs)
    notification_stats = [
        {
            "label": "알림 활성화",
            "count": notification_enabled,
            "percentage": _safe_rate(notification_enabled, max(len(unique_users), 1)),
            "icon_key": "notifications_active",
        },
        {
            "label": "발송 로그",
            "count": notification_sent,
            "percentage": 100 if notification_sent > 0 else 0,
            "icon_key": "send",
        },
        {
            "label": "읽음 로그",
            "count": notification_read,
            "percentage": _safe_rate(notification_read, notification_sent),
            "icon_key": "done_all",
        },
    ]

    drop_off = []
    previous = funnel_steps[0]["count"] if funnel_steps else 0
    for step in funnel_steps[1:]:
        count = max(previous - step["count"], 0)
        drop_off.append({"label": step["label"], "count": count, "rate": _safe_rate(count, previous)})
        previous = step["count"]

    avg_actions_per_user = round(len(logs) / len(unique_users), 1) if unique_users else 0
    return {
        "generated_at": _fmt_datetime(now),
        "metrics": [
            {"key": "total_users", "label": "전체 사용자", "value": f"{len(unique_users):,}명"},
            {"key": "active_users_today", "label": "오늘 활성 사용자", "value": f"{len(active_users_today):,}명"},
            {"key": "avg_actions", "label": "사용자당 평균 행동", "value": f"{avg_actions_per_user}회"},
            {"key": "notification_enabled", "label": "알림 사용 사용자", "value": f"{notification_enabled:,}명"},
        ],
        "funnel_steps": [{"label": item["label"], "count": item["count"], "rate": item["rate"]} for item in funnel_steps],
        "session_durations": [{"label": label, "count": count} for label, count in session_durations.items()],
        "return_patterns": return_patterns,
        "weekly_active_users": weekly_active_users,
        "feature_frequency": feature_frequency,
        "notification_stats": notification_stats,
        "drop_off": drop_off,
        "active_user_insight": f"오늘 활성 사용자는 {len(active_users_today)}명입니다.",
        "session_insight": "세션 시간은 사용자별 하루 행동 구간을 기준으로 계산했습니다.",
        "return_insight": f"재방문 사용자 비율은 {_safe_rate(returning_count, len(login_counts))}%입니다.",
    }


def build_activity_log_overview(db: Session) -> Dict[str, Any]:
    now = datetime.now()
    logs = (
        db.query(UserActionLog)
        .order_by(UserActionLog.ual_created_at.desc(), UserActionLog.ual_id.desc())
        .limit(30)
        .all()
    )
    counts_counter = Counter(log.ual_action_type for log in logs)
    users = {user.u_id: user for user in db.query(User).all()}
    parking_lots = {lot.p_id: lot for lot in _get_parking_lots(db)}

    counts = [
        {"key": key, "label": ACTION_LABELS.get(key, key), "count": counts_counter.get(key, 0)}
        for key in ["login", "congestion_view", "prediction_view", "map_view", "favorite_add", "notification_set"]
    ]
    activities = []
    for log in logs:
        user_name = users.get(log.ual_user_id).u_name if log.ual_user_id in users else "알 수 없음"
        parking_name = parking_lots.get(log.ual_parking_lot_id).p_display_name if log.ual_parking_lot_id in parking_lots else ""
        detail_parts = [parking_name, log.ual_action_target or "", log.ual_action_value or ""]
        detail = " / ".join(part for part in detail_parts if part)
        activities.append(
            {
                "time": _fmt_datetime(log.ual_created_at),
                "action": ACTION_LABELS.get(log.ual_action_type, log.ual_action_type),
                "user": user_name,
                "detail": detail or "-",
                "type": log.ual_action_type or "other",
            }
        )

    total_count = db.query(UserActionLog).count()
    latest_time = logs[0].ual_created_at if logs else None
    insights = [
        {"title": "최근 활동 수", "value": f"{len(logs)}건", "detail": "최근 30건 활동 로그 기준"},
        {"title": "전체 누적 로그", "value": f"{total_count:,}건", "detail": "user_action_log 전체 기준"},
        {"title": "마지막 활동", "value": _fmt_relative_time(latest_time, now), "detail": "가장 최근 사용자 이벤트 기준"},
    ]
    return {
        "generated_at": _fmt_datetime(now),
        "total_count": total_count,
        "counts": counts,
        "activities": activities,
        "insights": insights,
    }
