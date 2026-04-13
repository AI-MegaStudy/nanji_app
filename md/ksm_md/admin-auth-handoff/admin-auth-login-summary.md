# 관리자 로그인 서버 연동 정리

## 작업 배경

- 기존 `nanji_web` 관리자 로그인은 프론트에서 더미 계정(`admin / 1111`)만 비교하는 구조였다.
- 이 방식은 실제 관리자 계정 검증이 아니어서 운영용으로 사용할 수 없었다.
- 따라서 FastAPI에서 `admin` 테이블을 기준으로 로그인 검증하도록 변경했다.

## 최종 구조

- 웹 관리자 로그인 입력
- `nanji_web`가 FastAPI `POST /api/v1/admin/auth/login` 호출
- FastAPI가 `admin` 테이블의 계정 정보를 확인
- 로그인 성공 시 관리자 정보 반환
- 웹은 응답을 기준으로 대시보드 진입

즉 현재 구조는 아래와 같다.

- 관리자 웹 -> FastAPI -> AWS RDS `admin` 테이블

## 반영 파일

### FastAPI

- `Python/fastapi/app/api/v1/admin_auth.py`
- `Python/fastapi/app/schemas/admin_auth.py`
- `Python/fastapi/app/api/v1/__init__.py`

### 웹

- `/Users/electrozone/Documents/GitHub/nanji_web/lib/Service/admin_dashboard_api.dart`
- `/Users/electrozone/Documents/GitHub/nanji_web/lib/VM/admin_auth_viewmodel.dart`

## 추가된 API

### 관리자 로그인

- Method: `POST`
- Path: `/api/v1/admin/auth/login`

요청 예시:

```json
{
  "admin_id": "admin",
  "password": "1111"
}
```

응답 예시:

```json
{
  "admin_id": 1,
  "admin_login_id": "admin",
  "admin_name": "관리자",
  "admin_role": "admin"
}
```

## 로그인 ID 처리 방식

현재 `admin` 테이블에는 별도 username 컬럼이 없고 `a_email` 컬럼만 있다.

그래서 로그인 시 아래 두 방식 모두 허용하도록 구현했다.

- 이메일 전체 입력
  - 예: `admin@jarinanji.com`
- 이메일의 `@` 앞부분 입력
  - 예: `admin`

즉 DB에 `a_email = 'admin@jarinanji.com'` 이 저장되어 있으면,
웹 로그인에서는 `admin` 또는 `admin@jarinanji.com` 둘 다 사용할 수 있다.

## 비밀번호 저장 방식

운영 기준으로는 평문 저장이 아니라 해시 저장을 사용한다.

현재 FastAPI 로그인 검증은 아래 순서로 처리한다.

1. `pbkdf2_sha256$...` 형식 해시 검증
2. 기존 평문 저장 계정에 대한 임시 호환 비교

즉 지금은 기존 계정이 있어도 로그인은 가능하게 해두었지만,
운영 기준으로는 해시 저장을 권장한다.

## 테스트용 해시 예시

비밀번호 `1111` 기준 예시 해시:

```text
pbkdf2_sha256$390000$jarinanjiadminsalt01$+vwGBMaTICLABOM7XKkBJzhKQNsRCMQ51whQ36TO/ko=
```

예시 SQL:

```sql
INSERT INTO admin (
  a_email,
  a_password,
  a_name,
  a_role,
  a_status,
  a_created_at,
  a_updated_at
) VALUES (
  'admin@jarinanji.com',
  'pbkdf2_sha256$390000$jarinanjiadminsalt01$+vwGBMaTICLABOM7XKkBJzhKQNsRCMQ51whQ36TO/ko=',
  '관리자',
  'admin',
  'active',
  NOW(),
  NOW()
);
```

로그인 테스트 시:

- ID: `admin` 또는 `admin@jarinanji.com`
- PW: `1111`

## 웹 변경 내용

기존:

- `admin_auth_viewmodel.dart` 안에 더미 계정 맵 하드코딩
- 프론트에서만 비교 후 로그인 성공 처리

변경 후:

- `AdminDashboardApi.signInAdmin(...)` 추가
- `AdminAuthViewModel.signIn(...)` 가 FastAPI 로그인 API 호출
- 서버 응답의 `detail` 문구를 그대로 에러 메시지로 사용

즉 더 이상 프론트 더미 로그인 비교를 사용하지 않는다.

## 테스트 순서

1. `admin` 테이블에 관리자 계정 반영
2. FastAPI 실행

```bash
cd /Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi
source .venv/bin/activate
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

3. 관리자 웹 실행

```bash
cd /Users/electrozone/Documents/GitHub/nanji_web
flutter run -d chrome
```

4. 로그인 시도

- ID: `admin` 또는 `admin@jarinanji.com`
- PW: `1111`

## 확인 완료 상태

- FastAPI 관리자 로그인 API 추가 완료
- 웹 더미 로그인 제거 완료
- DB 관리자 계정 기준 로그인 동작 확인 완료

## 이후 추천 작업

1. 관리자 로그인 성공 후 토큰/세션 구조 추가
2. 관리자 API 인증 가드 추가
3. 기존 평문 비밀번호 관리자 계정이 있다면 해시 저장 방식으로 정리
