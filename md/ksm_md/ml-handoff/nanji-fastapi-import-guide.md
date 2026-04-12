# Nanji ML 변화량 예측 FastAPI 반입 가이드

## 목적
- `hmw` 저장소의 난지 ML 산출물을 `nanji_app/Python/fastapi`에서 서비스용으로 반입하는 기준을 정리한다.
- 현재 앱과 웹은 **절대 점유 대수 기반 필드**를 계속 사용하므로, ML 출력이 변화량이어도 FastAPI 단계에서 절대값으로 복원한다.

## 현재 기준
- 원본 산출물 파일:
  - `/Users/electrozone/Documents/GitHub/nanji_work/hmw/Note/nanji_outputs_change/nanji_test_predictions.csv`
- 서비스 반입용 변환 파일:
  - `Python/fastapi/data/ml_ready/nanji_group_predictions_for_fastapi.csv`
  - `Python/fastapi/data/ml_ready/nanji_group_predictions_for_fastapi.json`

## 핵심 변경 사항
- 기존 ML 타깃:
  - `estimated_active_cars`
  - 의미: 특정 시점의 절대 점유 대수
- 현재 ML 타깃:
  - `estimated_active_cars_change`
  - 의미: 전 시간 대비 점유 차량 수 변화량

즉 이제 ML 출력은 바로 `pp_predicted_occupied_spaces`에 넣을 수 없다.

## 서비스 반입 원칙
- 앱 UI는 기존 절대값 필드 구조를 유지한다.
- 따라서 반입 단계에서 아래 순서로 처리한다.

1. ML 출력에서 `predicted_delta`를 읽는다.
2. 같은 예측 묶음의 시작 기준값 `base_occupied_spaces`를 읽는다.
3. `base_occupied_spaces`에 `predicted_delta`를 시간순으로 누적한다.
4. 누적 결과를 절대 점유 대수로 변환한다.
5. 절대값 기준으로 기존 DB 필드를 채운다.

## 현재 서비스 반입용 필드

### 필수 필드
- `parking_group`
- `base_time`
- `predicted_time`
- `prediction_horizon_minutes`
- `predicted_delta`
- `base_occupied_spaces`
- `model_version`

### 선택 필드
- `confidence_score`
- `source_file`

## 왜 `base_occupied_spaces`가 꼭 필요한가
- 변화량만 있으면 어디서부터 누적해야 하는지 알 수 없다.
- `parking_status_log`의 최신값을 임의로 쓰면 과거/배치 테스트 데이터 적재 시 기준이 흔들릴 수 있다.
- 따라서 ML 산출물 또는 기준 데이터셋에서 **각 예측 묶음의 시작 절대 점유 대수**를 확보해야 한다.

## 현재 변환 규칙

### 1. 예측 단위
- `parking_group = 난지전체`
- 이유:
  - 현재 ML 데이터는 개별 주차장 단위가 아니라 난지 전체 묶음 기준이다.

### 2. predicted_delta
- 원본 `weighted_core_prediction`을 서비스용 `predicted_delta`로 사용한다.
- 이유:
  - 현재 변화량 모델에서 `weighted_core_prediction`은 절대값이 아니라 변화량 예측 결과로 해석한다.

### 3. predicted_time
- 원본 `datetime`을 그대로 사용한다.

### 4. base_time
- 원본 파일에 명시값이 있으면 그대로 사용한다.
- 없으면 현재 테스트 반입에서는 `predicted_time - 1시간`으로 처리할 수 있다.
- 단, 운영 반영 전에는 실제 `base_time`을 받는 것을 권장한다.

### 5. base_occupied_spaces
- 우선순위는 아래와 같다.
  1. 원본 예측 산출물의 `base_occupied_spaces`
  2. `hmw/Data/processed/nanji_hourly_model_dataset_2020_2026_update.csv`의 `realtime_current_parking`
- 현재 기본 반입 흐름은 2번을 사용한다.
- 즉 예측 row의 `base_time`과 같은 시각의 `realtime_current_parking`을 기준값으로 사용한다.
- 둘 다 없으면 절대 점유 대수 복원이 불가능하므로 적재를 진행하지 않는다.

### 6. prediction_horizon_minutes
- 원본에 있으면 그대로 사용한다.
- 없으면 현재 테스트 반입에서는 `60`을 기본값으로 둘 수 있다.

### 7. confidence_score
- 원본에 있으면 저장한다.
- 없으면 공란 또는 `null`로 둔다.

### 8. model_version
- 예:
  - `weighted_delta_v1_test_import`
- 의미:
  - 변화량 모델 기반 테스트 반입 데이터라는 표시

## 절대 점유 대수 복원 방식
- 같은 `base_time` 기준으로 묶인 row를 `predicted_time` 오름차순으로 정렬한다.
- 초기값:
  - `current_occupied = base_occupied_spaces`
- 각 row마다:
  - `current_occupied = current_occupied + predicted_delta`
  - `current_occupied`는 `0 ~ total_spaces` 범위로 보정한다.

예시:
- `base_occupied_spaces = 120`
- `predicted_delta = +15, -8, +12`

복원 결과:
- 1시간 후: `135`
- 2시간 후: `127`
- 3시간 후: `139`

## DB 적재 시 최종 매핑
- `pp_parking_lot_id`: 난지 메인 주차장을 대표하는 `parking_lot.p_id`
- `pp_base_time`: `base_time`
- `pp_predicted_time`: `predicted_time`
- `pp_prediction_horizon_minutes`: `prediction_horizon_minutes`
- `pp_predicted_occupied_spaces`: 누적 복원한 절대 점유 대수
- `pp_predicted_available_spaces`: `p_total_spaces - pp_predicted_occupied_spaces`
- `pp_predicted_occupancy_rate`: `(pp_predicted_occupied_spaces / p_total_spaces) * 100`
- `pp_predicted_congestion_level`: 점유율 기준으로 계산
- `pp_confidence_score`: `confidence_score`
- `pp_model_version`: `model_version`

## 앱/웹 영향
- 앱과 관리자 웹은 기존 필드 구조를 그대로 사용한다.
- 즉 아래 필드는 유지된다.
  - `pp_predicted_occupied_spaces`
  - `pp_predicted_available_spaces`
  - `pp_predicted_occupancy_rate`
  - `pp_predicted_congestion_level`

따라서 이번 변경의 핵심 수정 지점은 앱/웹이 아니라:
- ML handoff 포맷
- FastAPI 반입 가공 스크립트
- FastAPI import 스크립트

## 현재 스크립트 동작
- `build_nanji_ml_import.py`
  - 변화량 기반 산출물을 FastAPI 반입용 CSV/JSON으로 가공한다.
  - 예측 산출물에 `base_occupied_spaces`가 없으면 `nanji_hourly_model_dataset_2020_2026_update.csv`에서 `realtime_current_parking`을 찾아 채운다.
- `import_nanji_group_predictions.py`
  - 변화량 기반 CSV면 누적 복원 후 `parking_prediction`으로 적재한다.
  - 절대값 기반 구 포맷도 여전히 읽을 수 있도록 유지한다.

## 다음 단계
1. `hmw` 기준 데이터셋의 `realtime_current_parking`이 base 값으로 충분한지 검증
2. 새 산출물로 `build_nanji_ml_import.py` 실행
3. `import_nanji_group_predictions.py --dry-run` 확인
4. 실제 DB 적재
5. 앱/웹에서 기존 화면이 그대로 동작하는지 확인
