# 자리난지 팀원용 실행 가이드

## 문서 목적
- 팀원이 `자리난지` 앱을 로컬에서 실행할 때 필요한 순서를 정리한다.
- 앱이 실제 FastAPI와 AWS RDS 데이터를 읽도록 실행하는 기본 흐름을 안내한다.

## 기본 구조
- iOS 앱: `nanji_app`
- FastAPI: `Python/fastapi`
- DB: AWS RDS MySQL

앱은 직접 DB에 붙지 않는다.
반드시 아래 흐름으로 실행한다.

- `iOS App -> FastAPI -> AWS RDS MySQL`

## 실행 전 확인

### 1. RDS 상태 확인
- AWS RDS의 DB 인스턴스가 `Available` 상태인지 확인한다.
- `Stopped` 상태면 먼저 시작해야 한다.

### 1-1. MySQL Workbench 연결 확인
- DB를 직접 확인해야 할 때는 MySQL Workbench로 AWS RDS에 접속한다.
- 아래 값으로 새 연결을 만든다.

기본 연결 정보:
- Connection Name: `hangang`
- Hostname: `hangang-db.cfsau2mo0bww.ap-northeast-2.rds.amazonaws.com`
- Port: `3306`
- Username: `admin`
- Password: 생성 당시 사용한 비밀번호

연결 방법:
1. MySQL Workbench 실행
2. `MySQL Connections`에서 `+` 버튼 클릭
3. 위 정보 입력
4. `Store in Keychain...` 또는 비밀번호 입력
5. `Test Connection`
6. 연결 성공하면 저장 후 접속

주의:
- MySQL 8.4 관련 경고가 떠도 접속 자체는 가능할 수 있다.
- 경고창이 나오면 `Continue Anyway`로 진행한다.
- 연결이 안 되면 먼저 AWS RDS 상태가 `Available`인지 확인한다.

연결 후 확인하면 좋은 것:
- 왼쪽 스키마에서 `hangang_parking` 확인
- `parking_lot`
- `parking_prediction`
- `parking_status_log`
- `user`
- `user_favorite_parking_lot`
- `user_notification_setting`

접속 후 자주 쓰는 확인 SQL:

```sql
SHOW TABLES;
```

```sql
SELECT * FROM parking_lot;
```

```sql
SELECT COUNT(*) FROM parking_prediction;
```

### 2. `.env` 확인
- FastAPI의 DB 연결 정보가 들어 있는지 확인한다.
- 위치:
  - `/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/.env`

필요한 값 예시:
- `MYSQL_HOST`
- `MYSQL_PORT`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `MYSQL_DATABASE`

### 3. Python 가상환경 확인
- FastAPI 폴더 안 `.venv`가 있어야 한다.

## 실행 순서

### 1단계. FastAPI 실행
터미널을 열고 아래 명령 실행:

```bash
cd /Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi
.venv/bin/python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

정상 실행되면 대략 이런 식으로 보인다.

```text
Uvicorn running on http://127.0.0.1:8000
```

### 2단계. FastAPI 정상 여부 확인
브라우저에서 아래 주소를 열어본다.

- `http://127.0.0.1:8000/health`
- `http://127.0.0.1:8000/api/v1/parking/lots`

정상이라면 JSON 응답이 보인다.

### 3단계. Xcode에서 앱 실행
- Xcode에서 `nanji_app.xcodeproj` 또는 workspace 열기
- 시뮬레이터 선택
- `Run`

### 4단계. 로그인 후 주요 화면 확인
앱 실행 후 아래 흐름을 확인한다.

- 로그인 성공
- 홈 화면 진입
- 메인 주차장 현재 상태 표시
- 미래 예측 표시
- 시간대별 분석 화면 이동
- 출발 타이밍 추천 화면 이동
- 대체 주차장 보기 화면 이동
- 즐겨찾기 추가/삭제
- 벨 알림 토글
- 마이페이지 사용자 정보 표시

## 확인용 API 목록

### 기본 확인
- `GET /health`
- `GET /api/v1/parking/lots`

### 메인 주차장 데이터
- `GET /api/v1/parking/current/1`
- `GET /api/v1/predictions/1`

### 사용자 기능
- `POST /api/v1/auth/social-login`
- `GET /api/v1/me/profile`
- `GET /api/v1/me/favorites`
- `POST /api/v1/me/favorites/toggle`
- `GET /api/v1/me/notifications`
- `POST /api/v1/me/notifications`

## 앱에서 정상으로 보이면 좋은 것

### 홈
- 현재 남은 자리 표시
- 미래 예측 표시
- 안내 문구 표시

### 대체 주차장
- 대체 주차장 이름 표시
- 거리/도착시간 표시
- 현재 데이터가 없으면 `정보 준비 중`

### 출발 타이밍 추천
- 추천 출발 시간 표시
- 혼잡 예상 시간 표시
- 여유 예상 시간 표시

### 시간대별 분석
- 차트 표시
- 피크 시간 표시
- 추천 시간 표시

### 즐겨찾기
- 원하는 주차장만 선택해서 추가 가능
- 삭제 가능
- 벨 토글 가능

### 마이페이지
- 실제 로그인 사용자 이름/이메일 표시
- 즐겨찾기 개수 표시
- 알림 사용 개수 표시

## DB까지 같이 확인하고 싶을 때

### 즐겨찾기 확인
```sql
SELECT *
FROM user_favorite_parking_lot
ORDER BY ufp_id DESC;
```

### 알림 설정 확인
```sql
SELECT *
FROM user_notification_setting
ORDER BY uns_id DESC;
```

### 로그인 사용자 확인
```sql
SELECT u_id, u_provider, u_provider_user_id, u_email, u_name
FROM user
ORDER BY u_id DESC;
```

## 자주 발생하는 문제

### 1. 앱에서 서버 연결 실패
원인:
- FastAPI가 안 켜져 있음
- 잘못된 URL 호출

확인:
- `http://127.0.0.1:8000/health` 열리는지 본다.

### 2. 즐겨찾기/알림이 401
원인:
- 로그인 후 실제 사용자 `user_id`가 저장되지 않았을 수 있음

해결:
- 로그아웃 후 다시 로그인
- FastAPI 재시작

### 3. DB 연결 실패
원인:
- RDS 중지 상태
- `.env` 설정 문제

해결:
- AWS에서 RDS 상태 확인
- `.env` 값 확인

### 4. 거리/도착시간이 이상함
원인:
- 위치 권한 미허용
- 시뮬레이터 위치값 불안정

해결:
- 위치 권한 허용
- 시뮬레이터 위치 재설정

## 서버 종료 방법
FastAPI 실행 터미널에서:

```bash
Ctrl + C
```

## 한 줄 요약
- `RDS 확인 -> FastAPI 실행 -> health 확인 -> Xcode Run -> 로그인 후 기능 확인`
