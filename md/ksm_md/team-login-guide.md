# Team Login Guide

## 목적
- 팀원이 `nanji_app`에서 소셜 로그인을 테스트할 때 필요한 최소 내용만 정리한다.

## 기본 사용 방법
1. 프로젝트 실행
2. 로그인 화면에서 원하는 로그인 버튼 선택
3. 로그인 성공 후 `마이페이지` 진입 확인

## 현재 가능한 로그인
- Google 로그인
- 카카오 로그인
- 네이버 로그인
- Apple 로그인은 실기기 테스트 필요

## 로그인별 주의사항
- Google
  - 테스트 사용자에 등록된 Google 계정이면 로그인 가능

- 카카오
  - 현재 설정된 앱 키와 번들 ID 기준으로 로그인 가능
  - 같은 프로젝트 설정이면 보통 추가 작업 없이 사용 가능

- 네이버
  - 현재 개발 단계라 등록된 테스트 계정만 로그인될 수 있음
  - 다른 네이버 계정은 막힐 수 있음

- Apple
  - 시뮬레이터에서 불안정할 수 있음
  - 가능하면 실제 iPhone에서 테스트

## 팀원이 따로 확인할 것
- Xcode에서 빌드가 되는지
- Signing 설정이 본인 환경에서 문제 없는지
- 번들 ID를 임의로 바꾸지 않았는지

## 막히면 먼저 볼 것
- Google 안 됨: 테스트 사용자 계정인지 확인
- 카카오 안 됨: 앱 키, 번들 ID, URL scheme 확인
- 네이버 안 됨: 등록된 테스트 계정인지 확인
- Apple 안 됨: 실기기에서 다시 테스트

## 참고 문서
- 상세 구현 정리: [social-login-setup.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/social-login-setup.md)
- 네이버/애플 정리: [naver-apple-login-setup.md](/Users/electrozone/Documents/GitHub/nanji_app/md/ksm_md/naver-apple-login-setup.md)
