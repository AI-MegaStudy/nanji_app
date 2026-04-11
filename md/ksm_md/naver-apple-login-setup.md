# Naver Apple Login Setup

## 목적
- 현재 `nanji_app`에 반영된 `네이버 로그인`, `Apple 로그인` 구현 상태를 정리한다.
- 지금 어디까지 만들어졌는지와, 이후 무엇만 하면 되는지 빠르게 확인할 수 있게 한다.

## 현재 구현 상태 요약
- `네이버 로그인`은 실제 OAuth 흐름으로 동작하도록 구현되어 있다.
- `네이버 로그인`은 등록된 테스트 계정 기준으로 로그인 성공 확인을 했다.
- `Apple 로그인`은 Xcode capability와 앱 코드까지 붙여둔 상태다.
- `Apple 로그인`은 시뮬레이터에서 인증 UI까지는 뜨지만, 내부 Apple 인증 진행이 정상 완료되지 않았다.
- `Apple 로그인`은 현재 `실기기 테스트 필요` 상태다.

## 관련 코드 위치
- 네이버/애플 로그인 구현: [nanji_app/View/LoginView.swift](/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/View/LoginView.swift)
- 앱 시작 시 SDK 초기화 및 URL 콜백: [nanji_app/nanji_appApp.swift](/Users/electrozone/Documents/GitHub/nanji_app/nanji_app/nanji_appApp.swift)
- URL scheme 및 외부 앱 설정: [nanji-app-Info.plist](/Users/electrozone/Documents/GitHub/nanji_app/nanji-app-Info.plist)

## Naver 로그인 구현 방식
- `NidThirdPartyLogin` SDK를 사용한다.
- 앱 시작 시 `NaverSignInService.initializeIfPossible()`로 SDK를 초기화한다.
- `네이버로 계속하기` 버튼을 누르면 네이버 로그인 OAuth 화면으로 이동한다.
- 로그인 성공 후 `accessToken`을 받고, `https://openapi.naver.com/v1/nid/me` 로 사용자 정보를 조회한다.

## Naver 로그인에서 사용하는 값
- `provider = naver`
- `providerUserId`
- `displayName`
- `email`
- `profileImageURL`
- `accessToken`

## Naver 로그인에서 이미 끝난 것
- 네이버 개발자센터에서 애플리케이션 등록을 완료했다.
- 네이버 로그인 API 사용 설정을 했다.
- iOS용 `URL Scheme`을 `nanjiappnaverlogin`으로 정했다.
- `Client ID`와 `Client Secret`을 발급받아 코드와 `Info.plist`에 넣었다.
- Xcode에 네이버 SDK를 연결했다.
- 앱 내부에 네이버 URL Scheme을 등록했다.
- `LSApplicationQueriesSchemes`에 네이버 관련 값들을 추가했다.
- 등록된 테스트용 네이버 계정으로 로그인 성공을 확인했다.

## Naver 로그인에서 현재 남아 있는 점
- 아직 네이버 검수 전 상태라 `등록된 계정만 로그인 가능`한 상태일 수 있다.
- 그래서 다른 네이버 계정으로는 로그인이 막힐 수 있다.
- 이건 코드 문제보다 네이버 개발자센터 서비스 승인/검수 상태 문제다.

## Naver 로그인에서 나중에 해야 하는 것
1. 네이버 로그인 검수 상태 확인
2. 필요하면 네이버 로그인 검수 요청
3. 일반 사용자 계정도 로그인 가능한지 다시 테스트
4. 검수 완료 후 팀원/외부 사용자 기준 재확인

## Naver 로그인에서 자주 막히는 문제
- 다른 계정으로 로그인할 때 `등록된 아이디만 로그인할 수 있습니다` 문구가 뜰 수 있다.
- 이 경우 현재는 개발 단계라 허용된 테스트 계정만 로그인 가능한 상태로 보면 된다.
- 서비스 공개 범위 확대는 네이버 검수/승인 이후 다시 확인해야 한다.

## Naver 로그인 설정값
- 앱 이름: `nanji_app`
- URL Scheme: `nanjiappnaverlogin`
- 번들 ID: `com.khankong.nanji-app`

## Apple 로그인 구현 방식
- `AuthenticationServices` 기반 `Sign in with Apple`을 사용한다.
- 별도 외부 SDK는 필요 없다.
- Xcode에서 `Sign in with Apple` capability를 추가했다.
- Apple 로그인 요청 시 `.fullName`, `.email` scope를 요청한다.
- 로그인 성공 시 `providerUserId`, `displayName`, `email`, `idToken`을 앱 상태에 저장하도록 구현했다.

## Apple 로그인에서 주의할 점
- Apple은 `이름`과 `이메일`을 처음 로그인할 때만 주는 경우가 많다.
- 그래서 앱 내부에 처음 받은 값을 저장해두고, 다음 로그인 때는 비어 있어도 이전 값을 사용하도록 처리했다.

## Apple 로그인에서 이미 끝난 것
- Xcode `Signing & Capabilities`에서 `Sign in with Apple`을 추가했다.
- `Apple 로그인 버튼 -> 인증 요청 -> 결과 처리` 코드 구조를 붙였다.
- Apple 로그인 결과를 앱의 `AuthStore` 구조에 연결했다.
- 이름/이메일이 재로그인 시 비어도 유지되도록 저장 구조를 추가했다.

## Apple 로그인에서 현재 상태
- 시뮬레이터에서 로그인 UI는 뜬다.
- 하지만 Apple 인증 진행 중 흰 화면, 암호 입력 이후 정지, passcode 관련 로그 등 시뮬레이터 불안정 문제가 발생했다.
- 코드 상의 delegate/coordinator 수명 문제는 한 번 수정했다.
- 현재는 `실기기 테스트로 확인해야 하는 상태`다.

## Apple 로그인에서 보인 문제
- `MCPasscodeManager passcode set check is not supported on this device`
- `AuthorizationError Code=1000`
- Apple 로그인 화면은 보이지만 시뮬레이터에서 다음 단계로 안 넘어가는 현상

## Apple 로그인에서 판단한 내용
- 현재 문제는 코드보다 `시뮬레이터 Apple 인증 환경` 이슈일 가능성이 크다.
- 시뮬레이터 재시작, 초기화, 다른 기종 변경까지 해도 안정적이지 않을 수 있다.
- 그래서 Apple 로그인은 `실제 아이폰`에서 테스트하는 것이 가장 중요하다.

## Apple 로그인에서 나중에 해야 하는 것
1. 실제 iPhone에서 로그인 테스트
2. 로그인 성공 시 `마이페이지` 진입과 사용자 정보 저장 확인
3. 서버 저장 구조와 연결
4. 실기기에서도 안 되면 유지할지 제거할지 결정

## Apple 로그인 유지/제거 판단 기준
- 실기기에서 정상 로그인되면 유지
- 실기기에서도 반복적으로 막히면 현재 일정 기준으로는 제거 또는 보류 가능
- 구글/카카오/네이버가 이미 동작하므로, Apple 로그인은 일정 우선순위에 따라 나중에 다시 붙여도 된다

## DB 저장과의 관계
- 네이버/애플 모두 로그인 성공 시 현재 앱 구조에서는 `AuthUser`로 변환된다.
- 따라서 이후 서버 저장 API 구조는 기존 구글/카카오와 같은 방식으로 연결할 수 있다.
- 저장 대상 예시:
- `provider`
- `provider_user_id`
- `email`
- `name`
- `profile_image_url`
- `id_token`
- `access_token`

## 지금 바로 남은 최소 작업
- 네이버 로그인: 검수/승인 상태는 나중에 확인
- Apple 로그인: 실기기 테스트 1회 진행

## 현재 결론
- `네이버 로그인`은 개발 테스트용 계정 기준으로 구현 완료에 가깝다.
- `Apple 로그인`은 코드 반영은 끝났고, 실기기 검증이 남아 있다.
