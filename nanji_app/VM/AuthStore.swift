import Foundation
import Combine

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isLoggedIn: Bool
    @Published private(set) var currentUserName: String
    @Published private(set) var provider: AuthProvider?
    @Published private(set) var currentUserEmail: String?
    @Published private(set) var backendUserID: Int?
    @Published var errorMessage: String?
    @Published private(set) var appleUserID: String?

    private let defaults = UserDefaults.standard
    private let isLoggedInKey = "auth.isLoggedIn"
    private let userNameKey = "auth.userName"
    private let providerKey = "auth.provider"
    private let userEmailKey = "auth.userEmail"
    private let appleUserIDKey = "auth.apple.userID"
    private let appleNameKey = "auth.apple.name"
    private let appleEmailKey = "auth.apple.email"
    private let backendUserIDKey = "auth.backendUserID"

    init() {
        let storedProvider = defaults.string(forKey: providerKey).flatMap(AuthProvider.init(rawValue:))
        self.isLoggedIn = defaults.bool(forKey: isLoggedInKey)
        self.currentUserName = defaults.string(forKey: userNameKey) ?? "방문자"
        self.provider = storedProvider
        self.currentUserEmail = defaults.string(forKey: userEmailKey)
        self.appleUserID = defaults.string(forKey: appleUserIDKey)
        let storedBackendUserID = defaults.integer(forKey: backendUserIDKey)
        self.backendUserID = storedBackendUserID > 0 ? storedBackendUserID : nil

        if !isLoggedIn {
            currentUserName = "방문자"
            provider = nil
            currentUserEmail = nil
            appleUserID = nil
            backendUserID = nil
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
            case .naver:
                user = try await NaverSignInService.signIn()
            case .apple:
                user = try await AppleSignInService.signIn(
                    existingName: defaults.string(forKey: appleNameKey),
                    existingEmail: defaults.string(forKey: appleEmailKey)
                )
            }

            apply(user: user)

            do {
                let response = try await APIService.shared.upsertSocialLogin(
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
                backendUserID = response.userID
                defaults.set(response.userID, forKey: backendUserIDKey)
            } catch {
                APIService.shared.setAuthenticatedUserID(nil)
                backendUserID = nil
                defaults.removeObject(forKey: backendUserIDKey)
                let detail = (error as NSError).localizedDescription
                errorMessage = "\(user.provider.title) 로그인은 되었지만 계정 연동 중 문제가 발생했습니다.\n\(detail)"
            }
        } catch {
            errorMessage = AuthErrorMessageMapper.message(for: error, provider: provider)
        }
    }

    func signOut() {
        #if canImport(GoogleSignIn)
        if provider == .google {
            GIDSignIn.sharedInstance.signOut()
        }
        #endif

        KakaoSignInService.signOutIfNeeded(provider: provider)
        NaverSignInService.signOutIfNeeded(provider: provider)

        isLoggedIn = false
        currentUserName = "방문자"
        provider = nil
        currentUserEmail = nil
        appleUserID = nil
        backendUserID = nil

        defaults.removeObject(forKey: isLoggedInKey)
        defaults.removeObject(forKey: userNameKey)
        defaults.removeObject(forKey: providerKey)
        defaults.removeObject(forKey: userEmailKey)
        defaults.removeObject(forKey: appleUserIDKey)
        defaults.removeObject(forKey: appleNameKey)
        defaults.removeObject(forKey: appleEmailKey)
        defaults.removeObject(forKey: backendUserIDKey)
        APIService.shared.setAuthenticatedUserID(nil)
    }

    private func apply(user: AuthUser) {
        isLoggedIn = true
        currentUserName = user.displayName
        provider = user.provider
        currentUserEmail = user.email
        appleUserID = user.provider == .apple ? user.providerUserId : nil

        defaults.set(true, forKey: isLoggedInKey)
        defaults.set(currentUserName, forKey: userNameKey)
        defaults.set(user.provider.rawValue, forKey: providerKey)
        defaults.set(user.email, forKey: userEmailKey)

        if user.provider == .apple {
            defaults.set(user.providerUserId, forKey: appleUserIDKey)
            defaults.set(user.displayName, forKey: appleNameKey)
            defaults.set(user.email, forKey: appleEmailKey)
        }
    }
}
