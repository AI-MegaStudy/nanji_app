# Nanji ML 예측 결과 FastAPI 반입 가이드

## 목적
- `hmw` 저장소에 있는 난지 예측 산출물을 `nanji_app/Python/fastapi`에서 바로 쓸 수 있는 형식으로 정리한다.
- 현재는 주차장별 개별 예측이 아니라 `난지 전체 묶음 기준` 예측을 서비스에 연결한다.

## 현재 기준
- 원본 산출물 파일:
  - `/Users/electrozone/Documents/GitHub/nanji_work/hmw/Note/nanji_outputs/nanji_test_predictions.csv`
- 서비스 반입용 변환 파일:
  - `Python/fastapi/data/ml_ready/nanji_group_predictions_for_fastapi.csv`
  - `Python/fastapi/data/ml_ready/nanji_group_predictions_for_fastapi.json`

## 왜 변환이 필요한가
- `hmw`의 예측 파일은 모델 검증용 테스트 결과다.
- 현재 파일에는 아래 항목이 없다.
  - `parking_group`
  - `base_time`
  - `confidence_score`
- FastAPI와 DB에 연결하려면 서비스용 컬럼이 필요해서 중간 가공 파일을 만든다.

## 현재 변환 규칙

### 1. 예측 단위
- `parking_group = 난지전체`
- 이유:
  - 현재 ML 데이터는 개별 주차장 단위가 아니라 난지 전체 묶음 기준이다.

### 2. 예측값 컬럼
- 원본 `weighted_core_prediction`을 서비스용 `estimated_active_cars`로 사용한다.
- 이유:
  - 보고서 기준으로 `weighted_core`가 실사용 구조에 더 적합하다고 정리되어 있기 때문이다.

### 3. predicted_time
- 원본 `datetime`을 그대로 사용한다.
- 의미:
  - 이 시각의 난지 전체 예상 활성 차량 수

### 4. base_time
- 현재 원본 파일에는 명시 값이 없어서 임시로 `predicted_time - 1시간`으로 처리한다.
- 주의:
  - 이 값은 서비스 테스트용 임시 규칙이다.
  - 운영 반영 전에는 ML 담당자에게 실제 `base_time`을 따로 받아야 한다.

### 5. prediction_horizon_minutes
- 임시로 `60` 고정
- 이유:
  - 현재 변환 규칙이 1시간 전 기준 예측으로 가정되어 있기 때문이다.

### 6. confidence_score
- 현재 공란
- 이유:
  - `hmw` 산출물에 예측별 신뢰도 점수가 포함되어 있지 않다.

### 7. model_version
- `weighted_core_v1_test_import`
- 의미:
  - 현재 파일은 운영용 최종 배치가 아니라 테스트 반입용 데이터라는 표시

## 현재 FastAPI에서 이 파일을 어떻게 쓸 수 있나
- 배치 import API 또는 스크립트에서 CSV/JSON을 읽는다.
- `parking_group = 난지전체`를 DB의 대표 `parking_lot` 레코드와 연결한다.
- 이후 `parking_prediction` 테이블로 적재할 때 아래처럼 변환한다.

## DB 적재 시 권장 매핑
- `pp_parking_lot_id`: 난지 전체를 대표하는 `parking_lot`의 `p_id`
- `pp_base_time`: `base_time`
- `pp_predicted_time`: `predicted_time`
- `pp_prediction_horizon_minutes`: `prediction_horizon_minutes`
- `pp_predicted_occupied_spaces`: `estimated_active_cars` 반올림 값
- `pp_predicted_available_spaces`: `p_total_spaces - predicted_occupied_spaces`
- `pp_predicted_occupancy_rate`: `(predicted_occupied_spaces / p_total_spaces) * 100`
- `pp_predicted_congestion_level`: 점유율 기준으로 계산
- `pp_confidence_score`: `confidence_score`가 있으면 저장
- `pp_model_version`: `model_version`

## 다음 단계
- `parking_lot`에 `난지전체` 대표 row를 먼저 넣는다.
- FastAPI에 예측 import 스크립트 또는 API를 만든다.
- ML 담당자에게는 운영 반영 전에 아래 2개를 추가 요청한다.
  - 실제 `base_time`
  - 예측별 `confidence_score`
