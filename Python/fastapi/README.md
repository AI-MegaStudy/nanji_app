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

## 다음 단계
1. 실제 테이블 구조 조회
2. 실제 DB 기준으로 ORM/Pydantic 모델 맞추기
3. 로그인, 주차장, 실시간 상태, 예측 API 연결
