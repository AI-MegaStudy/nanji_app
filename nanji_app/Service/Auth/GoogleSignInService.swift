import UIKit

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

enum GoogleSignInService {
    @MainActor
    static func signIn() async throws -> AuthUser {
        guard !GoogleAuthConfig.clientID.isEmpty else {
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

extension UIApplication {
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
