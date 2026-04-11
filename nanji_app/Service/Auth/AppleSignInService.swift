import AuthenticationServices
import UIKit

enum AppleSignInService {
    @MainActor
    private static var activeCoordinator: AppleSignInCoordinator?

    @MainActor
    static func signIn(existingName: String?, existingEmail: String?) async throws -> AuthUser {
        let authorization = ASAuthorizationAppleIDProvider().createRequest()
        authorization.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [authorization])
        let coordinator = AppleSignInCoordinator(controller: controller)
        activeCoordinator = coordinator
        defer { activeCoordinator = nil }

        let credential = try await coordinator.performSignIn()

        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              !identityToken.isEmpty else {
            throw AuthError.appleIdentityTokenUnavailable
        }

        let userID = credential.user
        let fullName = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
        let resolvedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = resolvedName.isEmpty ? (existingName ?? "Apple 사용자") : resolvedName
        let finalEmail = credential.email ?? existingEmail

        return AuthUser(
            provider: .apple,
            providerUserId: userID,
            displayName: finalName,
            email: finalEmail,
            profileImageURL: nil,
            accessToken: nil,
            idToken: identityToken
        )
    }
}

@MainActor
private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let controller: ASAuthorizationController
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    init(controller: ASAuthorizationController) {
        self.controller = controller
        super.init()
        self.controller.delegate = self
        self.controller.presentationContextProvider = self
    }

    func performSignIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthError.appleCredentialUnavailable)
            continuation = nil
            return
        }

        continuation?.resume(returning: credential)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
