# 사용자 앱 SQL Injection 방어 정리

## 1. 문서 목적

이 문서는 사용자 앱 기준으로 진행한 SQL Injection 방어 및 입력값 검증 보강 작업을 정리한 문서입니다.

대상 범위:

- iOS 앱이 FastAPI로 보내는 입력값
- FastAPI에서 받는 사용자 앱 요청
- SQL Injection 가능성을 줄이기 위한 백엔드 방어선
- 디버그성 DB API 노출 최소화

---

## 2. 현재 구조 기준 위험 판단

현재 프로젝트의 실제 구조는 아래와 같습니다.

```text
사용자 앱 -> FastAPI -> AWS RDS MySQL
```

즉 SQL Injection 관점에서 실제로 중요한 지점은 앱 화면 자체보다 FastAPI입니다.

이유:

- 앱과 웹은 입력을 전달하는 입구
- 실제 SQL 실행은 FastAPI + SQLAlchemy 쪽에서 발생
- DB는 앱이 직접 붙지 않고 FastAPI를 통해 접근

---

## 3. 현재 코드 상태 점검 결과

### 3-1. 비교적 안전한 점

현재 FastAPI는 대부분 SQLAlchemy ORM을 사용하고 있습니다.

대표 파일:

- `Python/fastapi/app/api/v1/auth.py`
- `Python/fastapi/app/api/v1/user_pref.py`
- `Python/fastapi/app/api/v1/parking.py`
- `Python/fastapi/app/api/v1/prediction.py`

즉 아래와 같은 직접 문자열 SQL 조합은 현재 핵심 API에는 거의 없습니다.

- `f"SELECT ... {user_input} ..."`
- 문자열 이어붙이기 기반 쿼리
- 사용자 입력이 포함된 raw SQL

따라서 현재 위험은 “이미 있는 직접 SQL 문자열”보다,
**입력값 제한이 느슨한 상태에서 이상한 값이 DB에 들어가는 문제**에 더 가까웠습니다.

### 3-2. 보완이 필요했던 점

입력값에 대해 아래 방어가 부족했습니다.

- 허용 provider 제한
- 허용 action_type 제한
- notification_type 제한
- 문자열 길이 제한
- 디버그용 DB 메타 API 노출

---

## 4. 이번에 실제 반영한 방어

### 4-1. 소셜 로그인 요청 검증 강화

대상 파일:

- `Python/fastapi/app/schemas/auth.py`

반영 내용:

- `provider` 허용값 제한
  - `google`
  - `kakao`
  - `naver`
  - `apple`
- `provider_user_id` 공백 제거
- `provider_user_id` 길이 제한 100자
- `email` 길이 제한 255자
- `name` 길이 제한 100자
- optional 문자열 필드 공백 정리

즉 소셜 로그인 요청은 이제:

- 허용된 provider만 통과
- 너무 긴 문자열은 차단
- 빈 문자열은 정리

방식으로 동작합니다.

### 4-2. 사용자 설정 API 입력 검증 강화

대상 파일:

- `Python/fastapi/app/schemas/user_pref.py`

반영 내용:

#### 즐겨찾기 토글

- `parking_lot_id`는 양수만 허용

#### 알림 설정

- `parking_lot_id`는 양수만 허용
- `notification_type`은 현재 `parking_status`만 허용

#### 사용자 행동 로그

- `action_type` 허용값 제한
  - `login`
  - `congestion_view`
  - `prediction_view`
  - `departure_timing_view`
  - `map_view`
  - `favorite_add`
  - `favorite_remove`
  - `notification_set`
- `parking_lot_id`는 양수만 허용
- `action_target` 최대 100자
- `action_value` 최대 255자
- `source_page` 최대 50자
- `session_id` 최대 100자

즉 현재는 사용자 앱이 아무 문자열이나 보내는 구조가 아니라,
서버가 허용된 값만 받도록 정리된 상태입니다.

---

## 5. 디버그용 DB API 차단

대상 파일:

- `Python/fastapi/app/api/v1/db.py`

기존 상태:

- `/api/v1/db/status`
- `/api/v1/db/tables`
- `/api/v1/db/tables/{table_name}/columns`

이런 엔드포인트가 기본 노출 상태였습니다.

문제점:

- 직접 SQL Injection 포인트는 아니더라도
- 공격자가 테이블 구조를 쉽게 알 수 있게 함
- 운영에서는 굳이 열려 있을 이유가 없음

현재 변경:

- 환경변수 `ENABLE_DEBUG_DB_API`가 켜져 있을 때만 접근 가능
- 기본값은 비활성
- 즉 사용자 앱/운영 상태에서는 기본적으로 404처럼 숨겨짐

한 줄 요약:

**DB 메타정보 엔드포인트를 기본 공개 상태에서 개발용 옵션 상태로 변경**

---

## 6. 왜 이 방식이 좋은가

현재 프로젝트는 ORM 기반이라, 지금 단계에서 가장 효과적인 SQL Injection 방어는 아래 조합입니다.

1. ORM 유지
2. 허용값 화이트리스트
3. 길이 제한
4. 디버그 API 차단

이 방식의 장점:

- 사용자 입력이 이상한 값으로 DB에 들어가는 걸 줄임
- 이후 동적 검색/정렬 추가 시 위험도를 낮춤
- 운영에서 필요 없는 메타정보 노출을 줄임

---

## 7. 앱 쪽에서 별도 주의할 점

현재 iOS 앱은 SQL을 직접 실행하지 않기 때문에,
앱 자체의 SQL Injection 방어보다 중요한 것은 아래입니다.

- 서버를 신뢰하지 않고 에러 처리하기
- 너무 긴 입력값은 프론트에서도 정리하기
- 관리자용 더미 로그인 같은 개발용 구조를 운영에 그대로 쓰지 않기

즉 현재 사용자 앱 쪽에서는
**백엔드 검증이 주 방어선**이고,
앱은 보조적으로 입력을 정리하는 구조로 보면 됩니다.

---

## 8. 아직 남아 있는 다음 단계

이번에는 사용자 앱 기준으로 먼저 방어선을 세웠고,
다음 단계로 추천되는 건 아래입니다.

### 8-1. 관리자 로그인 서버 인증화

현재 관리자 웹 로그인은 더미 프론트 인증 상태입니다.

향후 필요:

- FastAPI 관리자 로그인 API 추가
- 비밀번호 해시 저장
- 세션 또는 토큰 인증

### 8-2. 비밀번호 해시 적용

추천:

- `bcrypt`

이유:

- 비밀번호 전용 해시
- 단순 SHA256보다 안전
- 운영용 인증 구조에 적합

### 8-3. 동적 검색/정렬 추가 시 화이트리스트 유지

앞으로 검색 필터나 정렬 옵션을 추가할 경우,
절대 직접 문자열 SQL 조합으로 가지 말고 아래 원칙을 유지해야 합니다.

- 허용된 정렬 key만 매핑
- raw SQL 최소화
- `text()` 사용 시 바인드 파라미터 사용
- 테이블명/컬럼명을 직접 사용자 입력으로 받지 않기

---

## 9. 한 줄 결론

이번 사용자 앱 쪽 SQL Injection 방어는 다음 세 가지가 핵심입니다.

- 입력값 허용 목록과 길이 제한 추가
- 행동 로그/알림/소셜 로그인 요청 검증 강화
- 디버그용 DB 메타 API 기본 차단

즉 현재는 “ORM 기반 기본 안전성” 위에
**입력 검증과 노출 최소화**를 추가한 상태라고 보면 됩니다.
