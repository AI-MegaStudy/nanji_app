import Foundation

enum GoogleAuthConfig {
    // TODO: 여기에 Google Cloud Console의 iOS OAuth Client ID를 넣어주세요.
    // 직접 해야 하는 부분 1:
    // 예시) static let clientID = "1234567890-abcdefg.apps.googleusercontent.com"
    static let clientID = "95862729273-8mf1qha3pug7k8jerj9g1rp288sfi8jv.apps.googleusercontent.com"
}

enum KakaoAuthConfig {
    // TODO: 여기에 Kakao Developers의 네이티브 앱 키를 넣어주세요.
    // 직접 해야 하는 부분 6:
    // Kakao Developers > 내 애플리케이션 > 앱 키 > 네이티브 앱 키
    static let nativeAppKey = "db0e4509a7ad197cdad36cbfc17df099"

    static var urlScheme: String {
        "kakao\(nativeAppKey)"
    }
}

enum NaverAuthConfig {
    // TODO: 직접 해야 하는 부분 10:
    // 네이버 개발자센터에서 발급받은 앱 이름, Client ID, Client Secret, URL Scheme을 넣어주세요.
    static let appName = "자리난지"
    static let clientID = "E5bs2wNdybFlfgqvNTW8"
    static let clientSecret = "xLQbapdqa3"
    static let urlScheme = "nanjiappnaverlogin"
}
