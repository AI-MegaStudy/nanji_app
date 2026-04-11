import SwiftUI
import UIKit
import Combine

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

#if canImport(KakaoSDKCommon)
import KakaoSDKCommon
#endif

#if canImport(KakaoSDKAuth)
import KakaoSDKAuth
#endif

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

enum AuthProvider: String {
    case google
    case kakao
    case naver
    case apple

    var title: String {
        switch self {
        case .google: return "Google"
        case .kakao: return "카카오"
        case .naver: return "네이버"
        case .apple: return "Apple"
        }
    }

    var buttonTitle: String {
        "\(title)로 계속하기"
    }
}

struct AuthUser {
    let provider: AuthProvider
    let providerUserId: String
    let displayName: String
    let email: String?
    let profileImageURL: String?
    let accessToken: String?
    let idToken: String?
}

enum AuthError: LocalizedError {
    case missingGoogleSignInSDK
    case missingRootViewController
    case missingGoogleClientID
    case googleTokenUnavailable
    case googleUserDataUnavailable
    case missingKakaoSDK
    case missingKakaoNativeAppKey
    case kakaoTokenUnavailable
    case kakaoUserDataUnavailable
    case unsupportedProvider

    var errorDescription: String? {
        switch self {
        case .missingGoogleSignInSDK:
            return "GoogleSignIn SDK가 아직 프로젝트에 추가되지 않았습니다."
        case .missingRootViewController:
            return "로그인 화면을 표시할 UIViewController를 찾지 못했습니다."
        case .missingGoogleClientID:
            return "Google Client ID 설정이 비어 있습니다."
        case .googleTokenUnavailable:
            return "Google 토큰을 가져오지 못했습니다."
        case .googleUserDataUnavailable:
            return "Google 사용자 정보를 읽지 못했습니다."
        case .missingKakaoSDK:
            return "Kakao iOS SDK가 아직 프로젝트에 추가되지 않았습니다."
        case .missingKakaoNativeAppKey:
            return "카카오 네이티브 앱 키 설정이 비어 있습니다."
        case .kakaoTokenUnavailable:
            return "카카오 토큰을 가져오지 못했습니다."
        case .kakaoUserDataUnavailable:
            return "카카오 사용자 정보를 읽지 못했습니다."
        case .unsupportedProvider:
            return "아직 실제 연동이 준비되지 않은 로그인 방식입니다."
        }
    }
}

enum GoogleAuthConfig {
    // TODO: 여기에 Google Cloud Console의 iOS OAuth Client ID를 넣어주세요.
    // 직접 해야 하는 부분 1:
    // 예시) static let clientID = "1234567890-abcdefg.apps.googleusercontent.com"
    // 아직 넣지 않으면 Google 로그인 시 어떤 설정이 빠졌는지 앱에서 에러로 바로 보여줍니다.
    static let clientID = "95862729273-8mf1qha3pug7k8jerj9g1rp288sfi8jv.apps.googleusercontent.com"

    // TODO: Xcode Target > Info > URL Types에도 REVERSED_CLIENT_ID를 추가해야 합니다.
    // 직접 해야 하는 부분 2:
    // GoogleService-Info.plist를 쓰지 않는 현재 구조에서는 URL scheme을 수동 등록해야 콜백이 돌아옵니다.
    // 예시) com.googleusercontent.apps.1234567890-abcdefg
}

enum KakaoAuthConfig {
    // TODO: 여기에 Kakao Developers의 네이티브 앱 키를 넣어주세요.
    // 직접 해야 하는 부분 6:
    // Kakao Developers > 내 애플리케이션 > 앱 키 > 네이티브 앱 키
    static let nativeAppKey = "db0e4509a7ad197cdad36cbfc17df099"

    // TODO: Xcode Target > Info > URL Types에 아래 scheme을 추가해야 합니다.
    // 직접 해야 하는 부분 7:
    // kakao + 네이티브 앱 키 형태입니다. 예) kakao1234567890abcdef
    static var urlScheme: String {
        "kakao\(nativeAppKey)"
    }
}

enum GoogleSignInService {
    @MainActor
    static func signIn() async throws -> AuthUser {
        guard !GoogleAuthConfig.clientID.isEmpty else {
            // 막히는 부분 표시:
            // 이 에러가 뜨면 Google OAuth Client ID를 아직 코드에 넣지 않은 상태입니다.
            throw AuthError.missingGoogleClientID
        }

        guard let rootViewController = UIApplication.topViewController else {
            throw AuthError.missingRootViewController
        }

        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: GoogleAuthConfig.clientID)

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user

        guard let profile = user.profile else {
            throw AuthError.googleUserDataUnavailable
        }

        let accessToken = user.accessToken.tokenString
        let idToken = user.idToken?.tokenString

        guard !accessToken.isEmpty else {
            throw AuthError.googleTokenUnavailable
        }

        return AuthUser(
            provider: .google,
            providerUserId: user.userID ?? profile.email,
            displayName: profile.name,
            email: profile.email,
            profileImageURL: profile.imageURL(withDimension: 240)?.absoluteString,
            accessToken: accessToken,
            idToken: idToken
        )
        #else
        // 막히는 부분 표시:
        // 이 분기로 오면 패키지 추가가 안 된 상태입니다.
        // Xcode > File > Add Package Dependencies...
        // https://github.com/google/GoogleSignIn-iOS
        throw AuthError.missingGoogleSignInSDK
        #endif
    }

    static func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
        #else
        return false
        #endif
    }
}

enum KakaoSignInService {
    @MainActor
    static func initializeIfPossible() {
        #if canImport(KakaoSDKCommon)
        if !KakaoAuthConfig.nativeAppKey.isEmpty {
            KakaoSDK.initSDK(appKey: KakaoAuthConfig.nativeAppKey)
        }
        #endif
    }

    @MainActor
    static func signIn() async throws -> AuthUser {
        guard !KakaoAuthConfig.nativeAppKey.isEmpty else {
            throw AuthError.missingKakaoNativeAppKey
        }

        #if canImport(KakaoSDKAuth) && canImport(KakaoSDKUser)
        return try await withCheckedThrowingContinuation { continuation in
            let completion: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let token else {
                    continuation.resume(throwing: AuthError.kakaoTokenUnavailable)
                    return
                }

                UserApi.shared.me { user, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let user, let userID = user.id else {
                        continuation.resume(throwing: AuthError.kakaoUserDataUnavailable)
                        return
                    }

                    let nickname = user.kakaoAccount?.profile?.nickname ?? "카카오 사용자"
                    let email = user.kakaoAccount?.email
                    let profileImageURL = user.kakaoAccount?.profile?.profileImageUrl?.absoluteString

                    continuation.resume(
                        returning: AuthUser(
                            provider: .kakao,
                            providerUserId: String(userID),
                            displayName: nickname,
                            email: email,
                            profileImageURL: profileImageURL,
                            accessToken: token.accessToken,
                            idToken: nil
                        )
                    )
                }
            }

            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: completion)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: completion)
            }
        }
        #else
        // 막히는 부분 표시:
        // 이 에러가 뜨면 Xcode > File > Add Package Dependencies... 에서
        // https://github.com/kakao/kakao-ios-sdk 를 추가해야 합니다.
        throw AuthError.missingKakaoSDK
        #endif
    }

    static func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(KakaoSDKAuth)
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        #endif

        return false
    }

    static func signOutIfNeeded(provider: AuthProvider?) {
        #if canImport(KakaoSDKUser)
        if provider == .kakao {
            UserApi.shared.logout { _ in }
        }
        #endif
    }
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isLoggedIn: Bool
    @Published private(set) var currentUserName: String
    @Published private(set) var provider: AuthProvider?
    @Published private(set) var currentUserEmail: String?
    @Published var errorMessage: String?

    private let defaults = UserDefaults.standard
    private let isLoggedInKey = "auth.isLoggedIn"
    private let userNameKey = "auth.userName"
    private let providerKey = "auth.provider"
    private let userEmailKey = "auth.userEmail"

    init() {
        let storedProvider = defaults.string(forKey: providerKey).flatMap(AuthProvider.init(rawValue:))
        self.isLoggedIn = defaults.bool(forKey: isLoggedInKey)
        self.currentUserName = defaults.string(forKey: userNameKey) ?? "방문자"
        self.provider = storedProvider
        self.currentUserEmail = defaults.string(forKey: userEmailKey)

        if !isLoggedIn {
            currentUserName = "방문자"
            provider = nil
            currentUserEmail = nil
        }
    }

    func signIn(with provider: AuthProvider) async {
        errorMessage = nil

        do {
            let user: AuthUser

            switch provider {
            case .google:
                user = try await GoogleSignInService.signIn()
            case .kakao:
                user = try await KakaoSignInService.signIn()
            case .naver, .apple:
                // TODO: 직접 해야 하는 부분 3:
                // 네이버/애플도 같은 패턴으로 SDK 연동 후 AuthUser를 만들어서 연결하면 됩니다.
                throw AuthError.unsupportedProvider
            }

            apply(user: user)

            do {
                try await APIService.shared.upsertSocialLogin(
                    SocialLoginPayload(
                        provider: user.provider.rawValue,
                        providerUserId: user.providerUserId,
                        email: user.email,
                        name: user.displayName,
                        profileImageURL: user.profileImageURL,
                        accessToken: user.accessToken,
                        idToken: user.idToken
                    )
                )
            } catch {
                // TODO: 백엔드 미구성 상태에서도 구글 로그인 자체는 테스트할 수 있도록 저장 실패는 분리했습니다.
                // 직접 해야 하는 부분 4:
                // 나중에 서버가 붙으면 여기서 JWT/세션 토큰을 받아 안전하게 저장하도록 확장하세요.
                errorMessage = "\(user.provider.title) 로그인은 성공했지만 서버 저장은 실패했습니다: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        #if canImport(GoogleSignIn)
        if provider == .google {
            GIDSignIn.sharedInstance.signOut()
        }
        #endif

        KakaoSignInService.signOutIfNeeded(provider: provider)

        isLoggedIn = false
        currentUserName = "방문자"
        provider = nil
        currentUserEmail = nil

        defaults.removeObject(forKey: isLoggedInKey)
        defaults.removeObject(forKey: userNameKey)
        defaults.removeObject(forKey: providerKey)
        defaults.removeObject(forKey: userEmailKey)
    }

    private func apply(user: AuthUser) {
        isLoggedIn = true
        currentUserName = user.displayName
        provider = user.provider
        currentUserEmail = user.email

        defaults.set(true, forKey: isLoggedInKey)
        defaults.set(currentUserName, forKey: userNameKey)
        defaults.set(user.provider.rawValue, forKey: providerKey)
        defaults.set(user.email, forKey: userEmailKey)
    }
}

struct LoginView: View {
    @EnvironmentObject private var authStore: AuthStore
    @State private var isLoading = false
    @State private var selectedProvider: AuthProvider?
    @State private var showAuthAlert = false

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                MainTabView()
            } else {
                loginScreen
            }
        }
        .animation(.easeInOut, value: authStore.isLoggedIn)
        .onChange(of: authStore.errorMessage) { _, newValue in
            showAuthAlert = newValue != nil
        }
        .alert("로그인 안내", isPresented: $showAuthAlert, actions: {
            Button("확인", role: .cancel) {
                authStore.errorMessage = nil
            }
        }, message: {
            Text(authStore.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        })
    }

    private var loginScreen: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 18) {
                    iconCard

                    Text("한강공원 주차장")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("AI 기반 주차 예측 서비스를 시작해보세요")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 14) {
                    AuthButton(
                        title: AuthProvider.google.buttonTitle,
                        backgroundColor: .white,
                        foregroundColor: .black,
                        icon: .text("G"),
                        isLoading: isLoading && selectedProvider == .google,
                        action: { signIn(with: .google) }
                    )

                    AuthButton(
                        title: AuthProvider.kakao.buttonTitle,
                        backgroundColor: Color(red: 0.99, green: 0.87, blue: 0.22),
                        foregroundColor: .black,
                        icon: .system(name: "bubble.left.fill"),
                        isLoading: isLoading && selectedProvider == .kakao,
                        action: { signIn(with: .kakao) }
                    )

                    AuthButton(
                        title: AuthProvider.naver.buttonTitle,
                        backgroundColor: Color(red: 0.00, green: 0.63, blue: 0.35),
                        foregroundColor: .white,
                        icon: .text("N"),
                        isLoading: isLoading && selectedProvider == .naver,
                        action: { signIn(with: .naver) }
                    )

                    AuthButton(
                        title: AuthProvider.apple.buttonTitle,
                        backgroundColor: .black,
                        foregroundColor: .white,
                        icon: .system(name: "applelogo"),
                        isLoading: isLoading && selectedProvider == .apple,
                        action: { signIn(with: .apple) }
                    )
                }
                .padding(.horizontal, 24)
                .disabled(isLoading)

                VStack(spacing: 8) {
                    Text("Google 로그인은 실제 OAuth 구조로 연결해두었습니다")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.82))

                    Text("패키지, Client ID, URL Scheme 중 빠진 설정이 있으면 앱에서 바로 에러 안내가 뜹니다")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.74))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                Text("로그인하면 서비스 이용약관과 개인정보 처리방침에 동의하는 것으로 간주됩니다")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 32)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.80, green: 0.93, blue: 0.99), Color(red: 0.64, green: 0.82, blue: 0.99)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var iconCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .frame(width: 96, height: 96)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private func signIn(with provider: AuthProvider) {
        guard !isLoading else { return }

        selectedProvider = provider
        isLoading = true

        Task {
            await authStore.signIn(with: provider)
            isLoading = false
            selectedProvider = nil
        }
    }
}

private struct AuthButton: View {
    enum IconType {
        case system(name: String)
        case text(String)
    }

    let title: String
    let backgroundColor: Color
    let foregroundColor: Color
    let icon: IconType
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .frame(width: 34, height: 34)
                } else {
                    iconView
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(iconBackgroundOpacity))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Text(isLoading ? "로그인 중..." : title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    private var iconBackgroundOpacity: Double {
        switch icon {
        case .system: return 0.12
        case .text: return 0.15
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case let .system(name):
            Image(systemName: name)
                .font(.headline)
        case let .text(value):
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}

struct MainTabView: View {
    @State private var selection = 2

    var body: some View {
        TabView(selection: $selection) {
            PlaceholderTab(title: "대체 주차장")
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("대체주차장")
                }
                .tag(0)

            PlaceholderTab(title: "출발 타이밍")
                .tabItem {
                    Image(systemName: "clock")
                    Text("출발타이밍")
                }
                .tag(1)

            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(2)

            PlaceholderTab(title: "즐겨찾기")
                .tabItem {
                    Image(systemName: "star")
                    Text("즐겨찾기")
                }
                .tag(3)

            MyPageView()
                .tabItem {
                    Image(systemName: "person")
                    Text("마이페이지")
                }
                .tag(4)
        }
        .tint(Color.blue)
    }
}

private struct PlaceholderTab: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text("준비 중인 화면입니다")
                .foregroundColor(.secondary)
                .padding(.top, 6)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
    }
}

private struct MyPageView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(authStore.currentUserName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(loginMethodText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let email = authStore.currentUserEmail {
                        Text(email)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Button(role: .destructive) {
                    authStore.signOut()
                } label: {
                    Text("로그아웃")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.89, green: 0.32, blue: 0.28))

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("마이페이지")
        }
    }

    private var loginMethodText: String {
        guard let provider = authStore.provider else {
            return "로그인 정보가 없습니다"
        }

        return "\(provider.title) 계정으로 로그인됨"
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthStore())
    }
}

private extension UIApplication {
    static var topViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        var top = window?.rootViewController

        while let presented = top?.presentedViewController {
            top = presented
        }

        return top
    }
}
