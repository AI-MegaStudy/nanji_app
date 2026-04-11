import Foundation

#if canImport(KakaoSDKCommon)
import KakaoSDKCommon
#endif

#if canImport(KakaoSDKAuth)
import KakaoSDKAuth
#endif

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

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
