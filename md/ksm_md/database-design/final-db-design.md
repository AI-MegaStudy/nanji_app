# Nanji Final DB Design

## 문서 목적
- `Han River Parking Prediction` 앱과 `Parking Dashboard` 관리자 웹이 함께 사용하는 최종 DB 구조를 정리한다.
- EER 기준으로 확정한 테이블, 관계, 컬럼 역할을 팀 문서로 남긴다.
- 이후 `CREATE TABLE SQL`, `FastAPI 모델`, `테스트 API` 구현의 기준 문서로 사용한다.

## 현재 기준
- 앱 영역: 사용자 로그인, 주차장 조회, 예측 조회, 출발 타이밍 추천, 즐겨찾기, 알림, FCM
- 관리자 웹 영역: 주차장 현황, 예측 분석, 사용자 행동 분석, 알림 이력, 활동 로그
- DB는 더 이상 선택 계층이 아니라 서비스 핵심 저장소로 본다.

## 최종 테이블 목록

### 사용자/관리자
- `user`
- `admin`

### 주차장/예측
- `parking_lot`
- `parking_status_log`
- `parking_prediction`
- `departure_recommendation`

### 사용자 개인화/알림
- `user_fcm_device_tokens`
- `user_favorite_parking_lot`
- `user_notification_setting`
- `notification_log`

### 행동 분석
- `user_action_log`

## 테이블별 역할

### `user`
- 앱 사용자 계정 저장
- 소셜 로그인 식별 기준
- 즐겨찾기, 알림 설정, FCM 토큰, 행동 로그의 부모

주요 컬럼
- `u_id`
- `u_provider`
- `u_provider_user_id`
- `u_email`
- `u_name`
- `u_status`
- `u_terms_agreed_at`
- `u_privacy_agreed_at`
- `u_marketing_agreed`
- `u_last_login_at`
- `u_created_at`
- `u_updated_at`

권장 제약
- PK: `u_id`
- UNIQUE: `(u_provider, u_provider_user_id)`

### `admin`
- 관리자 웹 로그인 계정 저장
- 앱 사용자와 별도 인증/권한 흐름 관리

주요 컬럼
- `a_id`
- `a_email`
- `a_password`
- `a_name`
- `a_role`
- `a_status`
- `a_last_login_at`
- `a_created_at`
- `a_updated_at`

권장 제약
- PK: `a_id`
- UNIQUE: `a_email`

### `parking_lot`
- 주차장 마스터 정보 저장
- 실시간 현황, 예측, 추천, 즐겨찾기, 알림의 기준 테이블

주요 컬럼
- `p_id`
- `p_name`
- `p_display_name`
- `p_parking_type`
- `p_region_name`
- `p_address`
- `p_latitude`
- `p_longitude`
- `p_total_spaces`
- `p_open_time`
- `p_close_time`
- `p_operating_status`
- `p_supports_realtime_congestion`
- `p_supports_prediction`
- `p_supports_departure_timing`
- `p_supports_map_view`
- `p_supports_favorite`
- `p_supports_notification`
- `p_created_at`
- `p_updated_at`

기능 지원 컬럼 의미
- `p_supports_realtime_congestion`: 실시간 혼잡도 제공 여부
- `p_supports_prediction`: 예측 제공 여부
- `p_supports_departure_timing`: 출발 타이밍 제공 여부
- `p_supports_map_view`: 지도 보기 제공 여부
- `p_supports_favorite`: 즐겨찾기 제공 여부
- `p_supports_notification`: 알림 제공 여부

### `user_fcm_device_tokens`
- 사용자 기기별 FCM 토큰 저장
- 한 사용자가 여러 기기를 가질 수 있도록 분리
- 푸시 발송 대상과 토큰 상태 관리

주요 컬럼
- `uf_id`
- `uf_user_id`
- `uf_fcm_token`
- `uf_device_type`
- `uf_device_uuid`
- `uf_app_version`
- `uf_os_version`
- `uf_is_active`
- `uf_last_used_at`
- `uf_created_at`
- `uf_updated_at`

권장 제약
- PK: `uf_id`
- UNIQUE: `uf_fcm_token`

### `parking_status_log`
- 실시간 주차 현황 로그 저장
- 관리자 대시보드의 현재 상태, 혼잡도 추이, 시간대별 현황 분석에 사용

주요 컬럼
- `ps_id`
- `ps_parking_lot_id`
- `ps_recorded_at`
- `ps_occupied_spaces`
- `ps_available_spaces`
- `ps_occupancy_rate`
- `ps_congestion_level`
- `ps_source_type`
- `ps_created_at`

### `parking_prediction`
- 미래 시점 예측 로그 저장
- 기준 시각 대비 1시간 후, 2시간 후 등 예측 결과 보관

주요 컬럼
- `pp_id`
- `pp_parking_lot_id`
- `pp_base_time`
- `pp_predicted_time`
- `pp_prediction_horizon_minutes`
- `pp_predicted_occupied_spaces`
- `pp_predicted_available_spaces`
- `pp_predicted_occupancy_rate`
- `pp_predicted_congestion_level`
- `pp_confidence_score`
- `pp_model_version`
- `pp_created_at`

### `departure_recommendation`
- 출발 타이밍 및 추천 방문 시간 저장
- 앱의 추천 방문 시간, 혼잡 예상 시간, 여유 시간 표시에 사용

주요 컬럼
- `dr_id`
- `dr_parking_lot_id`
- `dr_target_date`
- `dr_recommended_arrival_time`
- `dr_recommended_departure_time`
- `dr_busy_time_start`
- `dr_busy_time_end`
- `dr_free_time_start`
- `dr_free_time_end`
- `dr_recommended_message`
- `dr_reason_summary`
- `dr_created_at`

### `user_favorite_parking_lot`
- 사용자 즐겨찾기 저장
- 주차장별 즐겨찾기 순위 분석에도 사용

주요 컬럼
- `ufp_id`
- `ufp_user_id`
- `ufp_parking_lot_id`
- `ufp_created_at`

권장 제약
- PK: `ufp_id`
- UNIQUE: `(ufp_user_id, ufp_parking_lot_id)`

### `user_notification_setting`
- 사용자별 알림 선호 저장
- 특정 주차장 기준 알림 또는 공통 알림 설정 저장

주요 컬럼
- `uns_id`
- `uns_user_id`
- `uns_parking_lot_id`
- `uns_notification_type`
- `uns_is_enabled`
- `uns_threshold_percent`
- `uns_minutes_before_departure`
- `uns_created_at`
- `uns_updated_at`

권장 제약
- PK: `uns_id`
- UNIQUE 고려: `(uns_user_id, uns_parking_lot_id, uns_notification_type)`

### `notification_log`
- 실제 발송된 알림 이력 저장
- 발송 여부, 읽음 여부, 어떤 기기로 보냈는지 추적

주요 컬럼
- `nl_id`
- `nl_user_id`
- `nl_parking_lot_id`
- `nl_device_token_id`
- `nl_notification_type`
- `nl_title`
- `nl_body`
- `nl_send_status`
- `nl_sent_at`
- `nl_read_at`
- `nl_created_at`

설계 메모
- 공지형 알림까지 포함하면 `nl_parking_lot_id`는 nullable 가능
- 기기 단위 발송 추적이 필요하면 `nl_device_token_id` 유지

### `user_action_log`
- 사용자 행동 로그 저장
- 관리자 대시보드의 퍼널, 활동 로그, 기능 사용률 분석 핵심 테이블

주요 컬럼
- `ual_id`
- `ual_user_id`
- `ual_parking_lot_id`
- `ual_action_type`
- `ual_action_target`
- `ual_action_value`
- `ual_source_page`
- `ual_session_id`
- `ual_created_at`

`ual_action_type` 예시
- `login`
- `congestion_view`
- `prediction_view`
- `departure_timing_view`
- `map_view`
- `favorite_add`
- `favorite_remove`
- `notification_set`

## 최종 카디널리티

### `user` 기준
- `user` 1 : N `user_fcm_device_tokens`
- `user` 1 : N `user_favorite_parking_lot`
- `user` 1 : N `user_notification_setting`
- `user` 1 : N `notification_log`
- `user` 1 : N `user_action_log`

### `parking_lot` 기준
- `parking_lot` 1 : N `parking_status_log`
- `parking_lot` 1 : N `parking_prediction`
- `parking_lot` 1 : N `departure_recommendation`
- `parking_lot` 1 : N `user_favorite_parking_lot`
- `parking_lot` 1 : N `user_notification_setting`
- `parking_lot` 1 : N `notification_log`
- `parking_lot` 1 : N `user_action_log`

### `user_fcm_device_tokens` 기준
- `user_fcm_device_tokens` 1 : N `notification_log`

## 관리자 대시보드에서 이 구조로 가능한 항목
- 오늘 방문자 수
- 혼잡도 조회 수
- 예측 조회 수
- 출발 타이밍 조회 수
- 지도 클릭 수
- 즐겨찾기 추가 수
- 주차장별 인기 순위
- 실시간 사용자 활동 로그
- 기능별 사용 비율
- 사용자 행동 퍼널
- 알림 발송 성공/실패 이력

## EER 검토 결과 요약
- 현재 EER는 구조적으로 다음 단계로 넘어가도 되는 상태
- 핵심 FK 방향과 카디널리티는 정상
- FCM 토큰 분리 구조 정상
- 앱/관리자 웹 공통 사용 구조로 적절함

## 다음 단계
1. EER 기준으로 `CREATE TABLE SQL` 생성
2. MySQL에 실제 테이블 생성
3. FastAPI에서 DB 연결 설정
4. SQLAlchemy 또는 ORM 모델 작성
5. `/health`, `/auth`, `/parking`, `/notification` 정도부터 테스트 API 연결
