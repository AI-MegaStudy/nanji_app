# Nanji ML 데이터 요청 정리

## 문서 목적
- 머신러닝 모델 담당자에게 어떤 데이터와 산출물을 요청해야 하는지 정리한다.
- 현재 확정된 DB 구조와 FastAPI 연결 흐름을 기준으로 협업 포인트를 맞춘다.
- 앱 사용자 화면과 관리자 대시보드에 바로 연결할 수 있는 형태를 기준으로 요청한다.

## 현재 프로젝트 기준
- DB는 AWS RDS MySQL `hangang_parking`을 사용 중이다.
- 테이블은 이미 생성되어 있고, FastAPI는 기존 테이블에 연결하는 방향으로 진행 중이다.
- 현재 핵심 테이블은 아래와 같다.
  - `parking_lot`
  - `parking_status_log`
  - `parking_prediction`
  - `departure_recommendation`
  - `user`
  - `user_fcm_device_token`
  - `user_favorite_parking_lot`
  - `user_notification_setting`
  - `notification_log`
  - `user_action_log`
- 최종 DB 기준 문서는 `md/ksm_md/database-design/final-db-design.md`를 따른다.

## 백엔드 흐름
- 앱과 관리자 웹은 직접 DB에 붙지 않는다.
- 기본 흐름은 아래와 같다.
  - `앱 / 관리자 웹 -> FastAPI -> MySQL`
- 따라서 머신러닝 담당자에게는 “모델 파일만” 받는 것이 아니라, FastAPI와 DB에 붙일 수 있는 형태의 입력/출력 기준도 같이 받아야 한다.

## 머신러닝 담당자에게 꼭 요청해야 하는 것

### 1. 모델 입력 데이터 정의
- 어떤 컬럼을 입력으로 사용하는지
- 각 컬럼의 의미
- 각 컬럼의 타입
- 결측치가 있을 때 처리 방식
- 데이터 전처리 방식
- 시간 단위
  - 예: 5분 단위, 10분 단위, 1시간 단위
- 예측 기준 시각과 예측 대상 시각의 관계

예시 질문
- 예측할 때 필요한 최소 입력 컬럼은 무엇인가?
- `parking_status_log`만으로 가능한가, 아니면 날씨/공휴일/요일/시간대가 추가로 필요한가?
- 입력은 주차장별 시계열인가, 전체 데이터 통합인가?

### 2. 모델 학습 데이터 요구사항
- 학습에 사용한 원본 데이터 구조
- 주차장별 데이터 분리 여부
- 최소 필요한 데이터 기간
  - 예: 최소 3개월, 6개월, 1년
- 학습 데이터의 시간 해상도
  - 예: 10분 단위 기록
- 데이터가 부족한 주차장일 때 처리 방식

예시 질문
- 난지 주차장만 학습 가능한지, 다른 주차장도 일반화 가능한지?
- 주차장별로 모델을 따로 써야 하는지, 하나의 모델로 처리 가능한지?

### 3. 예측 결과 포맷
- FastAPI와 DB에 넣으려면 예측 결과 형식을 미리 확정해야 한다.
- 아래 항목들을 요청한다.

필수 요청 항목
- `예측 기준 시각`
- `예측 대상 시각`
- `예측 남은 자리 수`
- `예측 점유 대수`
- `예측 점유율`
- `예측 혼잡도`
- `신뢰도 점수`
- `모델 버전`

현재 DB 대응 테이블
- `parking_prediction`

현재 컬럼 기준
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

즉, 머신러닝 담당자에게는 최소한 위 컬럼에 매핑 가능한 결과를 달라고 요청해야 한다.

### 4. 출발 타이밍 추천 산출 기준
- 단순 예측값만으로 끝나지 않고, 앱에서는 “언제 출발하면 좋은지”까지 보여줘야 한다.
- 따라서 아래도 같이 요청해야 한다.

요청 항목
- 추천 도착 시간 계산 기준
- 추천 출발 시간 계산 기준
- 혼잡 시간대 계산 기준
- 여유 시간대 계산 기준
- 추천 메시지 생성 규칙
- 추천 근거 요약 방식

현재 DB 대응 테이블
- `departure_recommendation`

현재 컬럼 기준
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

즉, 머신러닝 담당자에게는 “예측값”뿐 아니라 “추천 로직 산출 기준”까지 같이 요청해야 한다.

### 5. 혼잡도 분류 기준
- 앱과 관리자 웹에서는 숫자만이 아니라 상태값도 같이 보여준다.
- 따라서 혼잡도 등급 분류 기준을 꼭 받아야 한다.

예시
- `free`
- `normal`
- `busy`
- `full`

요청할 내용
- 점유율 몇 퍼센트부터 `busy`인지
- `normal`과 `busy`를 나누는 기준
- 예측 결과와 실시간 데이터에서 같은 기준을 쓸지 여부

이 기준은 아래 두 테이블에 같이 맞아야 한다.
- `parking_status_log.ps_congestion_level`
- `parking_prediction.pp_predicted_congestion_level`

### 6. 주차장 기능 적용 범위
- 현재 프로젝트는 주차장마다 제공 기능이 다를 수 있다.
- 예: 난지 주차장만 예측 가능

따라서 머신러닝 담당자에게 아래를 물어봐야 한다.
- 어떤 주차장이 예측 대상인지
- 어떤 주차장은 실시간만 가능한지
- 어떤 주차장은 출발 타이밍 추천까지 가능한지

이 정보는 아래 컬럼과 연결된다.
- `p_supports_prediction`
- `p_supports_departure_timing`

### 7. 모델 실행 방식
- 백엔드에서 실제 연결하려면 실행 방식이 필요하다.
- 단순히 노트북 코드만 받으면 바로 붙이기 어렵다.

반드시 요청할 것
- 추론 실행 코드
- 입력 예시
- 출력 예시
- 패키지 버전
- 실행 명령어
- CPU/GPU 필요 여부
- 실행 시간

가능하면 받으면 좋은 것
- `requirements.txt`
- 모델 파일 경로 구조
- 함수 진입점
  - 예: `predict(parking_lot_id, base_time, records)`

### 8. API 연동 방식
- FastAPI에 붙일 때 아래 둘 중 어떤 방식인지 정해야 한다.

가능한 방식
- Python 함수 호출형
  - FastAPI 내부에서 직접 모델 함수를 호출
- 별도 추론 API 호출형
  - FastAPI가 ML 서버 API를 다시 호출

현재 프로젝트 단계에서는 아래를 우선 추천한다.
- Python 함수 호출형

머신러닝 담당자에게 요청할 것
- FastAPI 내부에서 바로 부를 수 있는 함수 형태 제공 가능 여부
- 불가능하면 별도 API 명세 제공

## 머신러닝 담당자에게 바로 보낼 질문 목록

### 데이터 관련
- 예측 모델에 필요한 입력 컬럼은 정확히 무엇인가?
- 각 입력 컬럼의 타입과 전처리 방식은 무엇인가?
- 예측에 필요한 최소 데이터 기간은 어느 정도인가?
- 주차장별로 모델이 분리되는가, 공통 모델인가?

### 예측 결과 관련
- 예측 결과를 어떤 형식으로 반환하는가?
- 예측 시각별로 남은 자리 수와 점유율을 같이 줄 수 있는가?
- 혼잡도 상태값도 같이 줄 수 있는가?
- 신뢰도 점수를 줄 수 있는가?

### 추천 관련
- 출발 타이밍 추천 로직도 모델 산출물에 포함되는가?
- 추천 도착 시간 / 출발 시간 / 혼잡 시간 / 여유 시간 계산 기준은 무엇인가?
- 추천 메시지는 규칙 기반인가, 모델 생성형인가?

### 운영 관련
- 모델 버전은 어떻게 관리하는가?
- 재학습 주기는 어느 정도인가?
- 추론 속도는 어느 정도인가?
- 배포 가능한 Python 함수 형태로 줄 수 있는가?

## 백엔드 기준으로 최종적으로 받아야 하는 산출물

### 최소 필수
- 입력 컬럼 명세
- 입력 예시 데이터
- 출력 컬럼 명세
- 출력 예시 데이터
- 혼잡도 분류 기준
- 모델 버전 표기 방식
- 실행 방법 설명

### 가능하면 같이 받기
- Python 추론 코드
- `requirements.txt`
- 샘플 모델 파일
- 테스트용 CSV
- 주차장별 지원 범위 표

## 백엔드에서 바로 쓰기 좋은 출력 예시

### 예측 결과 예시
```json
{
  "parking_lot_id": 1,
  "base_time": "2026-04-12T14:00:00",
  "predictions": [
    {
      "predicted_time": "2026-04-12T15:00:00",
      "prediction_horizon_minutes": 60,
      "predicted_occupied_spaces": 82,
      "predicted_available_spaces": 18,
      "predicted_occupancy_rate": 82.0,
      "predicted_congestion_level": "busy",
      "confidence_score": 0.87,
      "model_version": "v1.0.0"
    }
  ]
}
```

### 출발 타이밍 추천 예시
```json
{
  "parking_lot_id": 1,
  "target_date": "2026-04-12",
  "recommended_arrival_time": "2026-04-12T09:30:00",
  "recommended_departure_time": "2026-04-12T09:00:00",
  "busy_time_start": "2026-04-12T13:00:00",
  "busy_time_end": "2026-04-12T16:00:00",
  "free_time_start": "2026-04-12T09:00:00",
  "free_time_end": "2026-04-12T11:00:00",
  "recommended_message": "오전 9시 30분 전후 방문을 추천합니다.",
  "reason_summary": "오후 시간대 혼잡이 예상되어 오전 방문이 유리합니다."
}
```

## 정리
- 머신러닝 담당자에게는 단순히 “예측 결과 주세요”라고 하면 안 된다.
- 현재 DB와 FastAPI 구조에 맞춰 아래를 같이 요청해야 한다.
  - 입력 데이터 정의
  - 학습 데이터 요구사항
  - 예측 결과 포맷
  - 출발 타이밍 추천 기준
  - 혼잡도 분류 기준
  - 주차장별 지원 범위
  - 실행 방식
- 이 문서를 기준으로 먼저 요구사항을 맞춘 뒤, 그다음 FastAPI 예측 API를 구현하는 흐름으로 간다.
