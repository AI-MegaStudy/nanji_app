import SwiftUI

@main
struct NanjiParkingApp: App {
    @StateObject private var authStore = AuthStore()

    init() {
        KakaoSignInService.initializeIfPossible()
        NaverSignInService.initializeIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(authStore)
                .onOpenURL { url in
                    // TODO: 직접 해야 하는 부분 5:
                    // Google 로그인 후 앱으로 돌아오는 콜백을 처리합니다.
                    // URL Types 설정이 안 되어 있으면 이 코드까지 들어오지 않습니다.
                    if GoogleSignInService.handleOpenURL(url) {
                        return
                    }

                    // TODO: 직접 해야 하는 부분 8:
                    // 카카오 로그인 후 앱으로 돌아오는 콜백입니다.
                    // URL Types에 kakao{NATIVE_APP_KEY}가 없으면 이 경로가 동작하지 않습니다.
                    if KakaoSignInService.handleOpenURL(url) {
                        return
                    }

                    // TODO: 직접 해야 하는 부분 11:
                    // 네이버 로그인 후 앱으로 돌아오는 콜백입니다.
                    // Info.plist와 개발자센터에 같은 URL Scheme이 등록되어 있어야 합니다.
                    _ = NaverSignInService.handleOpenURL(url)
                }
        }
    }
}
