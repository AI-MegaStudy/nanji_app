import Foundation

#if canImport(NidThirdPartyLogin)
import NidThirdPartyLogin
#endif

enum NaverSignInService {
    @MainActor
    static func initializeIfPossible() {
        #if canImport(NidThirdPartyLogin)
        guard !NaverAuthConfig.clientID.isEmpty,
              !NaverAuthConfig.clientSecret.isEmpty,
              !NaverAuthConfig.urlScheme.isEmpty else {
            return
        }

        NidOAuth.shared.initialize(
            appName: NaverAuthConfig.appName,
            clientId: NaverAuthConfig.clientID,
            clientSecret: NaverAuthConfig.clientSecret,
            urlScheme: NaverAuthConfig.urlScheme
        )
        #endif
    }

    @MainActor
    static func signIn() async throws -> AuthUser {
        guard !NaverAuthConfig.clientID.isEmpty else {
            throw AuthError.missingNaverClientID
        }

        guard !NaverAuthConfig.clientSecret.isEmpty else {
            throw AuthError.missingNaverClientSecret
        }

        guard !NaverAuthConfig.urlScheme.isEmpty else {
            throw AuthError.missingNaverURLScheme
        }

        #if canImport(NidThirdPartyLogin)
        let token = try await withCheckedThrowingContinuation { continuation in
            NidOAuth.shared.requestLogin { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        let accessToken = token.accessToken.tokenString
        guard !accessToken.isEmpty else {
            throw AuthError.naverTokenUnavailable
        }

        let profile = try await fetchProfile(accessToken: accessToken)

        return AuthUser(
            provider: .naver,
            providerUserId: profile.id,
            displayName: profile.name ?? profile.nickname ?? "네이버 사용자",
            email: profile.email,
            profileImageURL: profile.profile_image,
            accessToken: accessToken,
            idToken: nil
        )
        #else
        throw AuthError.missingNaverSDK
        #endif
    }

    static func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(NidThirdPartyLogin)
        return NidOAuth.shared.handleURL(url)
        #else
        return false
        #endif
    }

    static func signOutIfNeeded(provider: AuthProvider?) {
        #if canImport(NidThirdPartyLogin)
        if provider == .naver {
            NidOAuth.shared.logout()
        }
        #endif
    }

    private static func fetchProfile(accessToken: String) async throws -> NaverProfile {
        guard let url = URL(string: "https://openapi.naver.com/v1/nid/me") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw AuthError.naverProfileUnavailable
        }

        let decoded = try JSONDecoder().decode(NaverProfileResponse.self, from: data)
        return decoded.response
    }
}
