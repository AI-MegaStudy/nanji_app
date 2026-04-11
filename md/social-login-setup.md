# Social Login Setup

## 목적
- 현재 `nanji_app`에 붙어 있는 `Google 로그인`, `카카오 로그인` 구현 상태를 정리한다.
- 이미 끝난 작업과, 나중에 이어서 해야 하는 작업을 한 번에 확인할 수 있게 한다.

## 현재 구현 상태
- `Google 로그인`은 실제 OAuth 흐름으로 동작한다.
- `카카오 로그인`은 실제 OAuth 흐름으로 동작한다.
- 로그인 성공 시 앱 내부 상태에 사용자 정보가 저장되고 `마이페이지`로 진입할 수 있다.
- `마이페이지`에서 현재 로그인 제공자와 사용자 이름을 확인할 수 있다.
- `로그아웃`도 동작한다.
- 서버 저장용 API 호출 자리도 만들어져 있지만, 실제 백엔드/MySQL 저장은 아직 미완성이다.

## 현재 코드 위치
- Google, Kakao 로그인 흐름: [nanji_app/View/LoginView.swift](/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/LoginView.swift)
- 앱 시작 시 SDK 초기화/URL 콜백 처리: [nanji_app/nanji_appApp.swift](/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/nanji_appApp.swift)
- 소셜 로그인 서버 저장 요청 자리: [nanji_app/Service/API.swift](/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/Service/API.swift)
- URL scheme 및 iOS 앱 설정: [nanji-app-Info.plist](/Users/electrozone/Documents/GitHub/nanji_app/nanji-app-Info.plist)

## Google 로그인 구현 방식
- `GoogleSignIn-iOS` 패키지를 사용한다.
- `GoogleAuthConfig.clientID`에 Google Cloud에서 발급한 iOS Client ID를 넣는다.
- 앱 실행 후 `Google로 계속하기`를 누르면 Google OAuth 화면으로 이동한다.
- 로그인 성공 시 다음 정보를 앱에서 사용한다.
- `provider = google`
- `providerUserId`
- `displayName`
- `email`
- `profileImageURL`
- `accessToken`
- `idToken`

## Google 로그인에서 이미 끝난 설정
- Google Cloud Console에서 iOS OAuth Client ID를 발급했다.
- [`LoginView.swift`](/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/LoginView.swift)에 `clientID`를 넣었다.
- `URL Scheme`을 앱에 등록했다.
- Google 로그인 테스트를 완료했다.
- 테스트 사용자 계정도 추가해서 테스트 가능한 상태다.

## Google 로그인에서 나중에 할 일
- 운영 배포 전 `clientID`를 코드 하드코딩 대신 설정 파일로 분리한다.
- 테스트 사용자 정책 대신 실제 서비스 공개 범위로 정리한다.
- 서버가 준비되면 Google 로그인 후 서버 세션/JWT 발급 흐름으로 연결한다.

## Kakao 로그인 구현 방식
- `KakaoSDKCommon`, `KakaoSDKAuth`, `KakaoSDKUser`를 사용한다.
- 앱 시작 시 `KakaoSignInService.initializeIfPossible()`로 SDK를 초기화한다.
- `카카오로 계속하기`를 누르면 카카오톡 앱 로그인 또는 카카오 계정 로그인으로 이동한다.
- 로그인 성공 시 다음 정보를 앱에서 사용한다.
- `provider = kakao`
- `providerUserId`
- `displayName`
- `email`
- `profileImageURL`
- `accessToken`

## Kakao 로그인에서 이미 끝난 설정
- Kakao iOS SDK 패키지를 프로젝트에 추가했다.
- Kakao Developers에서 `난지앱`용 네이티브 앱 키를 발급했다.
- [`LoginView.swift`](/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/LoginView.swift)에 `nativeAppKey`를 넣을 수 있는 구조를 만들었다.
- 앱에 카카오 URL scheme을 등록할 수 있는 구조를 만들었다.
- Kakao Developers에서 카카오 로그인을 활성화했다.
- Kakao 로그인 테스트를 완료했다.

## Kakao 로그인에서 중요한 설정값
- 코드에 넣는 값: `네이티브 앱 키`
- URL scheme에 넣는 값: `kakao{네이티브 앱 키}`
- iOS 번들 ID: `com.khankong.nanji-app`

## Kakao 로그인에서 자주 막히는 부분
- `KOE004`
- 카카오 로그인 기능이 비활성화되어 있을 때 발생한다.
- `Kakao Developers > 카카오 로그인`에서 활성화가 필요하다.

- `KOE009`
- iOS bundleId validation failed.
- `Kakao Developers`에 등록한 iOS 번들 ID와 Xcode의 번들 ID가 다를 때 발생한다.
- 현재 앱 번들 ID는 `com.khankong.nanji-app` 이다.

## Kakao 로그인에서 나중에 할 일
- `nativeAppKey`를 코드 하드코딩 대신 설정 파일로 분리한다.
- 팀원이 직접 빌드할 때 필요한 설정 절차를 별도 문서로 더 짧게 정리한다.
- 운영 전 동의 항목과 추가 사용자 정보 수집 범위를 정리한다.

## 현재 앱 내부 로그인 상태 관리 방식
- `AuthStore`가 로그인 상태를 관리한다.
- 로그인 성공 시 앱 내부 상태에 사용자 이름, 이메일, 제공자 정보를 저장한다.
- `UserDefaults`를 사용해 로그인 상태를 간단히 유지한다.
- 지금은 임시 세션 구조이며, 실제 운영 세션/JWT 방식은 아직 아니다.

## 서버 저장 구조
- [`API.swift`](/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/Service/API.swift)에 `upsertSocialLogin(_:)`가 준비되어 있다.
- 현재는 앱에서 아래 형태의 데이터를 서버로 보낼 수 있게 해둔 상태다.
- `provider`
- `providerUserId`
- `email`
- `name`
- `profileImageURL`
- `accessToken`
- `idToken`

## DB 저장은 아직 안 된 상태
- 지금은 `/auth/social-login` 엔드포인트 자리가 있을 뿐, 실제 서버와 MySQL은 미구성 상태다.
- 앱에서 직접 MySQL에 붙는 구조는 쓰지 않는다.
- 권장 구조는 `iOS 앱 -> 백엔드 API -> MySQL` 이다.

## 나중에 DB 연결할 때 하면 되는 것
- 백엔드에 `/auth/social-login` API 구현
- Google/Kakao 토큰 검증
- `provider + providerUserId` 기준 사용자 upsert
- 서버 전용 세션 또는 JWT 발급
- 앱에서는 서버가 내려준 토큰을 저장하도록 구조 변경

## 추천 DB 컬럼 예시
- `provider`
- `provider_user_id`
- `email`
- `name`
- `profile_image_url`
- `created_at`
- `updated_at`

## 팀원이 사용할 때
- 이미 설정이 반영된 프로젝트를 그대로 사용하면, 보통 로그인 자체는 추가 설정 없이 동작한다.
- 다만 팀원이 직접 Xcode에서 빌드하는 경우에는 `Signing`과 `Bundle Identifier` 문제는 따로 확인해야 할 수 있다.
- 로그인 SDK, 앱 키, URL scheme이 프로젝트에 포함되어 있으면 대부분 그대로 따라온다.

## 다음 추천 작업 순서
1. 네이버 로그인 붙이기
2. Apple 로그인 붙이기
3. 로그인 설정값을 코드 하드코딩에서 분리하기
4. 소셜 로그인 서버 API 만들기
5. MySQL 저장 구조 연결하기
6. 로그인/회원 상태를 앱 세션 구조로 정리하기

## 메모
- 현재 Google, Kakao 로그인은 `실제 OAuth 로그인 테스트 성공` 기준으로 정리했다.
- DB 저장은 아직 붙지 않았기 때문에, 지금 단계에서는 `소셜 로그인 성공`과 `회원 저장 완료`를 같은 의미로 보면 안 된다.
