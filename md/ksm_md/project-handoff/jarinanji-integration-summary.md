# 자리난지 통합 작업 정리

## 문서 목적
- 지금까지 진행한 `앱 - FastAPI - AWS RDS MySQL` 연동 작업을 한 번에 정리한다.
- 현재 무엇이 실제 데이터와 연결되어 있는지, 어떤 부분이 예외 상황용 fallback인지 구분한다.
- 다음 작업자가 이어서 볼 때 빠르게 현재 상태를 이해할 수 있도록 한다.

## 프로젝트 현재 구조
- iOS 앱: `/Users/electrozone/Documents/GitHub/nanji_app/nanji_app`
- FastAPI: `/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi`
- DB: AWS RDS MySQL
- 앱 이름: `자리난지`

## 전체 연결 구조
- 앱은 직접 DB에 붙지 않는다.
- 기본 흐름은 `iOS App -> FastAPI -> AWS RDS MySQL` 이다.
- 관리자 웹도 같은 API 서버를 바라보는 구조를 기준으로 잡았다.

## 이번 작업에서 완료한 것

### 1. DB 연결
- FastAPI에서 AWS RDS MySQL 연결 확인 완료
- 실제 테이블 목록 조회 확인 완료
- 실제 컬럼 구조 기준으로 ORM/응답 구조 정리 완료

### 2. 주차장 마스터 데이터
- `parking_lot`에 아래 4개 row 기준으로 서비스 구조 정리
  - `난지 메인 주차장`
  - `난지 캠핑장 주차장`
  - `하늘공원 주차장`
  - `월드컵공원 주차장`

### 3. 예측 데이터 적재
- `hmw` 데이터 기반으로 난지 묶음 예측을 FastAPI 반입용 포맷으로 가공
- `parking_prediction` 테이블에 적재 완료
- 메인 주차장 예측 조회 API 연결 완료

### 4. 현재 상태 데이터
- `parking_status_log` 기준 현재 상태 조회 API 연결 완료
- 메인 주차장 현재 상태를 앱 홈에서 읽어오도록 연결 완료

### 5. 앱 사용자 기능
- 로그인 후 홈 화면 진입
- 현재 상태 카드
- 미래 예측 카드
- 시간대별 분석
- 출발 타이밍 추천
- 대체 주차장 보기
- 즐겨찾기
- 알림 설정
- 마이페이지

### 6. 로그인 사용자 연동
- 소셜 로그인 후 FastAPI `social-login`으로 사용자 upsert
- FastAPI가 반환한 `user_id`를 앱에 저장
- 이후 즐겨찾기/알림/마이페이지 요청은 `X-User-ID` 헤더로 실제 로그인 사용자 기준 처리

## 실제 데이터와 연결된 부분

### 앱에서 실제 DB/FastAPI 기준으로 동작하는 부분
- 메인 주차장 현재 상태
- 메인 주차장 미래 예측
- 출발 타이밍 추천
- 시간대별 분석 데이터
- 주차장 목록
- 즐겨찾기 추가/삭제
- 알림 설정 저장
- 마이페이지 프로필
- 마이페이지 즐겨찾기 개수
- 마이페이지 알림 사용 개수

### 실제 DB 정보 기반이지만 일부 보완 로직이 있는 부분
- 대체 주차장 이름/주소/좌표: 실제 DB
- 대체 주차장 거리/도착시간: 실제 위치 또는 fallback 기준 계산
- 대체 주차장 현재 상태: 데이터가 없으면 `정보 준비 중`

## 현재 남아 있는 fallback / 예외 처리

### 1. 시간대별 분석 fallback
- `HourlyAnalysisAPI.swift`는 API 호출 실패 시 샘플 payload로 내려가는 구조가 남아 있다.
- 정상 상황에서는 실제 예측 데이터를 사용한다.
- 실패 시에도 화면이 아예 비지 않게 하기 위한 보완 경로다.

### 2. 대체 주차장 fallback 카드
- 대체 주차장 목록을 못 받으면 하드코딩 fallback 카드가 뜰 수 있다.
- 정상 상황에서는 실제 `parking_lot` 데이터를 사용한다.

### 3. 위치 fallback
- 사용자 실제 위치를 못 받거나 좌표가 비정상일 때는 서울 기준 fallback 위치로 거리/도착시간을 계산한다.
- 따라서 정상 상황에서는 실제 계산값, 예외 상황에서는 임시 기준 계산값이 사용될 수 있다.

### 4. 30분 후 출발
- 현재 예측 데이터는 1시간 단위라 `30분 후 출발`은 가장 가까운 다음 예측값으로 근사한다.
- UX상 보완용이며, 진짜 30분 단위 예측은 아직 아니다.

## 즐겨찾기 / 알림 DB 관련 정리

### 즐겨찾기 테이블
- 잘못된 단일 unique 제약 제거 완료
- 현재는 `(ufp_user_id, ufp_parking_lot_id)` 복합 unique 기준 사용
- 같은 사용자가 같은 주차장을 중복 즐겨찾기하지 않도록 구성

### 알림 설정 테이블
- 잘못된 단일 unique 제약 제거 완료
- 현재는 `(uns_user_id, uns_parking_lot_id, uns_notification_type)` 복합 unique 기준 사용
- 같은 사용자/같은 주차장/같은 알림 유형 중복 저장 방지 구조

## 마이페이지 상태
- 마이페이지는 실제 로그인 사용자 기준으로 동작
- 표시 정보
  - 사용자 이름
  - 이메일
  - 로그인 방식
  - 회원 번호
  - 즐겨찾기 개수
  - 알림 사용 개수
- 기타 설정 연결 완료
  - 앱 정보
  - 이용 약관
  - 개인정보 처리방침

## 앱 이름 반영 상태
- 앱 표시 이름을 `자리난지`로 반영
- 로그인 화면, 홈, 대체주차장, 출발타이밍 등 주요 사용자 화면에도 적용
- 알림 제목 등 사용자에게 보이는 주요 문구도 `자리난지` 기준으로 수정

## 확인 완료한 핵심 흐름
- 로그인 후 실제 사용자 row 생성/갱신
- 홈 현재 상태 조회
- 홈 예측 조회
- 시간대별 분석 조회
- 출발 타이밍 추천 조회
- 즐겨찾기 DB 저장
- 알림 설정 DB 저장
- 마이페이지 프로필/개수 조회

## 지금 기준으로 큰 문제 없는지
- 정상 요청 기준 핵심 기능은 실제 데이터와 연결되어 있다.
- 다만 일부 화면은 실패 시 사용자 경험을 위해 fallback 데이터/문구를 가지고 있다.
- 따라서 `정상 흐름 기준 실데이터 연동 완료`, `예외 상황용 fallback 일부 남음`으로 정리하는 것이 정확하다.

## 다음 작업 추천

### 우선순위 1
- 시간대별 분석의 샘플 fallback 제거
- 대체 주차장 하드코딩 fallback 제거
- 위치 fallback일 때 숫자 대신 안내 문구 표시 검토

### 우선순위 2
- 관리자 웹에서 필요한 API 목록 정리
- 관리자 대시보드용 통계/예측 조회 엔드포인트 설계

### 우선순위 3
- 대체 주차장 실시간 상태 데이터 확보 시 `parking_status_log` 확장
- 더 촘촘한 예측 단위 확보 시 `30분 후 출발` 정밀화

## 관련 주요 파일
- 앱 API: `/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/Service/API.swift`
- 로그인 상태: `/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/VM/AuthStore.swift`
- 홈: `/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/Home.swift`
- 대체 주차장: `/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/RecommendPage_lsy.swift`
- 출발 타이밍: `/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/TimingPage_lsy.swift`
- 즐겨찾기: `/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/FavoritesPage.swift`
- 마이페이지: `/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/LoginView.swift`
- FastAPI 인증: `/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/app/api/v1/auth.py`
- FastAPI 사용자 설정: `/Users/electrozone/Documents/GitHub/nanji_app/Python/fastapi/app/api/v1/user_pref.py`

