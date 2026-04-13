# Team Login Guide

## 목적
- 팀원이 `자리난지` 앱에서 소셜 로그인을 테스트할 때 필요한 실행 순서와 주의사항을 정리한다.
- 현재 개발 방식은 `각자 로컬 FastAPI 실행 + 공통 AWS RDS 사용` 기준이다.

## 현재 구조
- 앱은 DB에 직접 붙지 않는다.
- 흐름은 항상 `앱 -> FastAPI -> AWS RDS` 이다.
- 따라서 로그인 정보가 DB에 저장되려면 각자 자기 컴퓨터에서 FastAPI가 먼저 떠 있어야 한다.

## 팀원 실행 순서
1. 프로젝트 최신 코드 받기
2. `Python/fastapi`에서 FastAPI 실행
3. 브라우저에서 `health` 확인
4. Xcode에서 앱 실행
5. 소셜 로그인 테스트
6. 필요하면 Workbench에서 DB 확인

## 앱용/웹용 백엔드 진입점
- 실제 FastAPI 구현은 공통으로 `nanji_app/Python/fastapi` 에 있다.
- 앱 테스트용 백엔드는 아래 경로에서 직접 실행한다.
  - `nanji_app/Python/fastapi`
- 웹 관리자용으로는 `nanji_web` 안에도 얇은 엔트리 구조가 있다.
  - `nanji_web/backend_admin/main.py`
  - `nanji_web/backend_admin/run_local_admin_backend.sh`
- 이 웹용 엔트리도 실제로는 같은 공통 FastAPI를 실행한다.
- 즉 앱과 관리자 웹은 백엔드 구현이 둘로 나뉘는 것이 아니라, 같은 AWS RDS를 보는 같은 FastAPI를 사용한다.

## FastAPI 실행
```bash
cd /Users/본인경로/nanji_app/Python/fastapi
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## 관리자 웹용 FastAPI 실행
- 웹 팀원이 `nanji_web` 기준으로 실행하고 싶으면 아래처럼 실행해도 된다.

```bash
cd /Users/본인경로/nanji_web/backend_admin
./run_local_admin_backend.sh
```

- 이 스크립트도 실제로는 `nanji_app/Python/fastapi` 의 공통 FastAPI를 실행한다.

## FastAPI 확인
- 브라우저에서 아래 주소가 열리면 정상이다.

```text
http://127.0.0.1:8000/health
```

- 기대 응답

```json
{"status":"ok"}
```

## 앱 실행
- Xcode에서 `nanji_app` 실행
- 같은 컴퓨터의 iOS 시뮬레이터 기준으로 테스트한다
- 현재 앱 기본 API 주소는 `http://127.0.0.1:8000` 이다

## 관리자 웹 실행
```bash
cd /Users/본인경로/nanji_web
flutter pub get
flutter run -d chrome
```

- 관리자 웹도 같은 컴퓨터의 `127.0.0.1:8000` FastAPI를 본다.
- 따라서 웹을 보기 전에 FastAPI가 먼저 실행 중이어야 한다.

## DB 저장이 되는 조건
- Google 로그인 자체 성공만으로는 DB 저장이 끝난 것이 아니다.
- 로그인 후 앱이 `/api/v1/auth/social-login` 을 호출해야 `user` 테이블에 저장된다.
- 따라서 아래 3개가 모두 맞아야 한다.
  - FastAPI가 실행 중일 것
  - 앱과 FastAPI가 같은 컴퓨터 기준으로 연결될 것
  - FastAPI가 공통 AWS RDS에 정상 연결될 것
- 관리자 웹 통계도 같은 원리로, 각자 로컬 FastAPI를 거쳐 공통 AWS RDS를 읽는다.
- 그래서 각 팀원이 자기 FastAPI만 제대로 켜고 있으면, 입력 데이터는 공통 DB에 쌓이고 관리자 웹에서는 전체 통계를 볼 수 있다.

## 현재 가능한 로그인
- Google 로그인
- 카카오 로그인
- 네이버 로그인
- Apple 로그인은 실기기 테스트 권장

## 로그인별 주의사항
- Google
  - 테스트 사용자에 등록된 Google 계정이면 로그인 가능

- 카카오
  - 현재 설정된 앱 키와 번들 ID 기준으로 로그인 가능
  - 같은 프로젝트 설정이면 추가 작업 없이 사용 가능

- 네이버
  - 등록된 테스트 계정만 로그인될 수 있음

- Apple
  - 시뮬레이터에서 불안정할 수 있음
  - 가능하면 실제 iPhone에서 테스트

## 실기기 테스트 주의
- 현재 문서는 `각자 로컬 FastAPI + 시뮬레이터` 기준이다.
- iPhone 실기기에서 테스트하면 `127.0.0.1` 은 아이폰 자기 자신을 가리킨다.
- 그래서 실기기 테스트는 별도 맥 IP 설정이나 배포된 FastAPI가 필요하다.

## 로그인 후 확인 포인트
1. 앱에서 로그인 성공
2. 마이페이지 진입 가능 여부 확인
3. 즐겨찾기/알림 저장이 되는지 확인
4. FastAPI 터미널에 요청 로그가 찍히는지 확인

## DB 확인 예시
```sql
SELECT u_id, u_provider, u_provider_user_id, u_email, u_name
FROM user
ORDER BY u_id DESC;
```

- 다른 팀원이 로그인했는데 여기 row가 안 생기면, 보통 아래 둘 중 하나다.
  - 그 팀원 컴퓨터에서 FastAPI가 안 떠 있었음
  - 앱이 자기 로컬 FastAPI에 연결되지 못했음

## 막히면 먼저 볼 것
- 브라우저에서 `http://127.0.0.1:8000/health` 가 안 열림
  - FastAPI가 안 떠 있는 상태

- 앱 로그인은 되는데 DB에 저장 안 됨
  - FastAPI가 안 떠 있거나, 로그인 후 `social-login` 호출이 실패한 상태

- Google 안 됨
  - 테스트 사용자 계정인지 확인

- 카카오 안 됨
  - 앱 키, 번들 ID, URL scheme 확인

- 네이버 안 됨
  - 등록된 테스트 계정인지 확인

- Apple 안 됨
  - 실기기에서 다시 테스트

## 참고 문서
- 앱/웹 실행 순서: [team-app-run-guide.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/project-handoff/team-app-run-guide.md)
- 상세 구현 정리: [social-login-setup.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/social-login-setup.md)
- 네이버/애플 정리: [naver-apple-login-setup.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/naver-apple-login-setup.md)
