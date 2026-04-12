# Nanji FastAPI

## 목적
- 이미 AWS RDS MySQL에 생성된 테이블을 FastAPI와 연결하기 위한 백엔드 시작 구조
- 현재 단계는 `테이블 생성`이 아니라 `기존 DB 연결`, `연결 확인`, `기초 API 라우터 준비`가 목적

## 현재 원칙
- RDS에 이미 생성된 테이블을 사용한다.
- `Base.metadata.create_all()` 같은 테이블 생성 코드는 넣지 않는다.
- 먼저 DB 연결과 조회가 정상 동작하는지 확인한 뒤 API를 붙인다.

## 기본 구조
- `app/main.py`
  - FastAPI 앱 진입점
- `app/core/config.py`
  - 환경변수 설정
- `app/db/session.py`
  - SQLAlchemy 엔진과 세션
- `app/api/v1/`
  - 버전별 라우터
- `scripts/check_db_connection.py`
  - RDS 연결 확인 스크립트
- `scripts/list_tables.py`
  - 현재 RDS 테이블 목록 확인 스크립트
- `scripts/describe_tables.py`
  - 핵심 테이블 컬럼 구조 확인 스크립트

## 실행 순서
```bash
cd Python/fastapi
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python scripts/check_db_connection.py
python scripts/list_tables.py
python scripts/describe_tables.py
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## 현재 확인용 엔드포인트
- `GET /`
- `GET /health`
- `GET /api/v1/ping`
- `GET /api/v1/db/status`
- `GET /api/v1/db/tables`
- `GET /api/v1/db/tables/{table_name}/columns`
- `GET /api/v1/parking/lots`
- `GET /api/v1/parking/current/{parking_lot_id}`
- `GET /api/v1/predictions/{parking_lot_id}`

### 예측 API 동작 원칙
- `GET /api/v1/predictions/{parking_lot_id}` 는 주차장별로 가장 최근에 적재된 `pp_model_version`만 반환한다.
- 예전 테스트 적재본과 새 테스트 적재본이 같이 있어도, 기본 응답은 최신 반입 버전 기준으로 정리된다.
- 현재 변화량 복원 반입본의 예시 `pp_model_version`
  - `weighted_delta_v1_test_import`

## ML 반입 스크립트
- `python scripts/build_nanji_ml_import.py`
  - `hmw`의 테스트 예측 결과를 FastAPI 반입용 CSV/JSON으로 변환
- `python scripts/import_nanji_group_predictions.py --dry-run`
  - `난지전체` 예측 CSV를 DB 적재 형식으로 검증
- `python scripts/import_nanji_group_predictions.py --create-parking-lot`
  - 대표 `parking_lot` row가 없으면 만들고 `parking_prediction`으로 적재
- `python scripts/insert_test_current_status.py --dry-run`
  - 현재 상태 테스트 row를 미리 검증
- `python scripts/insert_test_current_status.py`
  - `parking_status_log`에 테스트용 현재 상태 1건 삽입
- `python scripts/collect_nanji_realtime_status.py --dry-run`
  - 한강공원 통합주차포털 난지 페이지의 `주차가능대수`를 기준으로 `parking_status_log` 적재 내용을 미리 검증
- `python scripts/collect_nanji_realtime_status.py`
  - 한강공원 통합주차포털의 `주차가능대수`, `주차구획수(계)`를 기준으로 실제 현재 상태 1건 적재

## 실시간 기준 대수 수집
- 목적
  - 변화량 예측 모델에서 필요한 `base_occupied_spaces`의 운영 기준값을 쌓기 위해 난지 현재 주차 대수를 주기적으로 저장한다.
- 권장 방식
  - 한강공원 통합주차포털 `https://www.ihangangpark.kr/parking/region/region9` 에서 `난지1,2,3,4주차장` 행을 직접 읽는다.
  - `주차가능대수`와 `주차구획수(계)`를 사용해 현재 점유 대수를 계산한다.
- 실행 예시
```bash
cd Python/fastapi
source .venv/bin/activate
python scripts/collect_nanji_realtime_status.py --dry-run
python scripts/collect_nanji_realtime_status.py
```
- 적재 기준
  - `주차구획수(계)` -> 총 주차면 수
  - `주차가능대수` -> 현재 남은 자리 수
  - `ps_occupied_spaces = total - available`
  - `ps_occupancy_rate = occupied / total * 100`
  - `ps_source_type = ihangangpark_site`
- 주의사항
  - 이 방식은 앞으로 생성되는 예측의 기준값을 안정적으로 쌓는 용도다.
  - 이미 만들어진 과거 배치 예측의 `base_time`을 자동 복원해주지는 않는다.
  - 사이트 HTML 구조가 바뀌면 스크립트 파싱 로직도 함께 점검해야 한다.
- 자동 실행
  - 맥 개발 환경에서는 `launchd`로 10분 주기 자동 실행을 걸 수 있다.
  - 가이드와 템플릿은 아래 문서를 참고한다.
    - [realtime-collector-scheduler-guide.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/ml-handoff/realtime-collector-scheduler-guide.md)

## 다음 단계
1. 실제 테이블 구조 조회
2. 실제 DB 기준으로 ORM/Pydantic 모델 맞추기
3. 로그인, 주차장, 실시간 상태, 예측 API 연결
