import Foundation
import AuthenticationServices

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
    case missingNaverSDK
    case missingNaverClientID
    case missingNaverClientSecret
    case missingNaverURLScheme
    case naverTokenUnavailable
    case naverProfileUnavailable
    case appleCredentialUnavailable
    case appleIdentityTokenUnavailable
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
        case .missingNaverSDK:
            return "네이버 iOS SDK가 아직 프로젝트에 추가되지 않았습니다."
        case .missingNaverClientID:
            return "네이버 Client ID 설정이 비어 있습니다."
        case .missingNaverClientSecret:
            return "네이버 Client Secret 설정이 비어 있습니다."
        case .missingNaverURLScheme:
            return "네이버 URL Scheme 설정이 비어 있습니다."
        case .naverTokenUnavailable:
            return "네이버 토큰을 가져오지 못했습니다."
        case .naverProfileUnavailable:
            return "네이버 사용자 정보를 읽지 못했습니다."
        case .appleCredentialUnavailable:
            return "Apple 로그인 자격 정보를 읽지 못했습니다."
        case .appleIdentityTokenUnavailable:
            return "Apple identity token을 가져오지 못했습니다."
        case .unsupportedProvider:
            return "아직 실제 연동이 준비되지 않은 로그인 방식입니다."
        }
    }
}

struct NaverProfileResponse: Decodable {
    let resultcode: String
    let message: String
    let response: NaverProfile
}

struct NaverProfile: Decodable {
    let id: String
    let email: String?
    let name: String?
    let nickname: String?
    let profile_image: String?
}

enum AuthErrorMessageMapper {
    static func message(for error: Error, provider: AuthProvider? = nil) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }

        if let appleError = error as? ASAuthorizationError {
            switch appleError.code {
            case .canceled:
                return "Apple 로그인을 취소했습니다."
            case .failed:
                return "Apple 로그인에 실패했습니다."
            case .invalidResponse:
                return "Apple 로그인 응답이 올바르지 않습니다."
            case .notHandled:
                return "Apple 로그인 요청이 처리되지 않았습니다."
            case .unknown:
                return "Apple 로그인 중 알 수 없는 오류가 발생했습니다."
            @unknown default:
                return "Apple 로그인 중 오류가 발생했습니다."
            }
        }

        let nsError = error as NSError

        if provider == .google || nsError.domain.contains("GIDSignIn") {
            if nsError.code == -5 {
                return "Google 로그인을 취소했습니다."
            }
            return "Google 로그인 중 오류가 발생했습니다."
        }

        if provider == .kakao {
            let message = nsError.localizedDescription.lowercased()
            if message.contains("cancel") || message.contains("canceled") {
                return "카카오 로그인을 취소했습니다."
            }
            return "카카오 로그인 중 오류가 발생했습니다."
        }

        if provider == .naver {
            let message = nsError.localizedDescription.lowercased()
            if message.contains("cancel") || message.contains("canceled") {
                return "네이버 로그인을 취소했습니다."
            }
            return "네이버 로그인 중 오류가 발생했습니다."
        }

        if provider == .apple {
            let message = nsError.localizedDescription.lowercased()
            if message.contains("cancel") || message.contains("canceled") {
                return "Apple 로그인을 취소했습니다."
            }
            return "Apple 로그인 중 오류가 발생했습니다."
        }

        let message = nsError.localizedDescription.lowercased()
        if message.contains("cancel") || message.contains("canceled") {
            return "로그인을 취소했습니다."
        }

        return "로그인 중 오류가 발생했습니다."
    }
}

enum PrivacyMasker {
    static func maskedName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return value }

        let characters = Array(trimmed)

        if characters.count == 1 {
            return "\(characters[0])*"
        }

        if characters.count == 2 {
            return "\(characters[0])*"
        }

        let first = String(characters.first!)
        let last = String(characters.last!)
        let middleMask = String(repeating: "*", count: max(characters.count - 2, 1))
        return first + middleMask + last
    }

    static func maskedEmail(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.split(separator: "@", maxSplits: 1).map(String.init)

        guard components.count == 2 else { return maskedName(trimmed) }

        let localPart = components[0]
        let domainPart = components[1]

        return maskedLocalPart(localPart) + "@" + maskedDomainPart(domainPart)
    }

    private static func maskedLocalPart(_ value: String) -> String {
        let characters = Array(value)

        switch characters.count {
        case 0:
            return ""
        case 1:
            return "\(characters[0])*"
        case 2:
            return "\(characters[0])*"
        default:
            let prefix = String(characters.prefix(2))
            let mask = String(repeating: "*", count: max(characters.count - 2, 2))
            return prefix + mask
        }
    }

    private static func maskedDomainPart(_ value: String) -> String {
        let sections = value.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard let firstSection = sections.first else { return value }

        let maskedFirstSection: String
        let characters = Array(firstSection)

        switch characters.count {
        case 0:
            maskedFirstSection = ""
        case 1:
            maskedFirstSection = "\(characters[0])*"
        case 2:
            maskedFirstSection = "\(characters[0])*"
        default:
            maskedFirstSection = String(characters.prefix(2)) + String(repeating: "*", count: max(characters.count - 2, 2))
        }

        if sections.count == 1 {
            return maskedFirstSection
        }

        return ([maskedFirstSection] + sections.dropFirst()).joined(separator: ".")
    }
}
