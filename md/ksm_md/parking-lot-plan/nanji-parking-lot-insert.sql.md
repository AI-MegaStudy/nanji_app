# Nanji Parking Lot Insert SQL

## 목적
- `parking_lot` 테이블에 `난지 메인 주차장`과 대체주차장 3개를 직접 입력할 때 사용할 SQL 초안을 남긴다.
- 현재 ML 예측은 `난지 메인 주차장`에만 연결하고, 나머지 3개는 대체주차장 안내용으로 사용한다.

## 사용 전 체크
- 이미 동일한 row가 들어가 있으면 중복 입력되지 않도록 먼저 조회한다.
- `p_total_spaces`, 주소, 좌표는 현재 서비스 연결용 초안이므로 실제 값 확인 후 보정하는 것이 가장 좋다.

## 조회 SQL
```sql
SELECT
  p_id,
  p_name,
  p_display_name,
  p_region_name,
  p_supports_prediction,
  p_supports_departure_timing
FROM parking_lot
WHERE p_name IN ('난지메인', '난지캠핑장', '하늘공원', '월드컵공원')
   OR p_display_name IN ('난지 메인 주차장', '난지 캠핑장 주차장', '하늘공원 주차장', '월드컵공원 주차장');
```

## 입력 SQL
```sql
INSERT INTO parking_lot (
  p_name,
  p_display_name,
  p_parking_type,
  p_region_name,
  p_address,
  p_latitude,
  p_longitude,
  p_total_spaces,
  p_open_time,
  p_close_time,
  p_operating_status,
  p_supports_realtime_congestion,
  p_supports_prediction,
  p_supports_departure_timing,
  p_supports_map_view,
  p_supports_favorite,
  p_supports_notification,
  p_created_at,
  p_updated_at
) VALUES
(
  '난지메인',
  '난지 메인 주차장',
  'public',
  '난지',
  '서울특별시 마포구 상암동 난지한강공원',
  37.5686,
  126.8789,
  1000,
  '06:00:00',
  '23:00:00',
  'open',
  1,
  1,
  1,
  1,
  1,
  1,
  NOW(),
  NOW()
),
(
  '난지캠핑장',
  '난지 캠핑장 주차장',
  'public',
  '난지',
  '서울특별시 마포구 상암동 난지한강공원 일대',
  37.5700,
  126.8795,
  300,
  '06:00:00',
  '23:00:00',
  'open',
  0,
  0,
  0,
  1,
  1,
  1,
  NOW(),
  NOW()
),
(
  '하늘공원',
  '하늘공원 주차장',
  'public',
  '난지',
  '서울특별시 마포구 하늘공원로 일대',
  37.5697,
  126.8780,
  250,
  '06:00:00',
  '23:00:00',
  'open',
  0,
  0,
  0,
  1,
  1,
  1,
  NOW(),
  NOW()
),
(
  '월드컵공원',
  '월드컵공원 주차장',
  'public',
  '난지',
  '서울특별시 마포구 월드컵로 일대',
  37.5710,
  126.8810,
  250,
  '06:00:00',
  '23:00:00',
  'open',
  0,
  0,
  0,
  1,
  1,
  1,
  NOW(),
  NOW()
);
```

## 현재 권장 연결 방식
- `parking_prediction`은 `난지 메인 주차장`의 `p_id`에만 연결한다.
- `난지 캠핑장 주차장`, `하늘공원 주차장`, `월드컵공원 주차장`은 대체주차장 안내용으로만 먼저 사용한다.

## 이후 단계
- 위 4개 row 입력
- `난지 메인 주차장`의 `p_id` 확인
- FastAPI import 스크립트로 `parking_prediction` 적재
- 앱/웹에서 대체주차장 3개 카드 노출
