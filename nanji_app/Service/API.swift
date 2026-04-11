import Foundation

struct SocialLoginPayload: Encodable {
    let provider: String
    let providerUserId: String
    let email: String?
    let name: String?
    let profileImageURL: String?
    let accessToken: String?
    let idToken: String?
}

final class APIService {
    static let shared = APIService()
    private init() {}
    
    private let baseURL = "http://127.0.0.1:8000"
    
    func fetchCurrentStatus(completion: @escaping (Result<ParkingStatus, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/current") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(ParkingStatus.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchPrediction(completion: @escaping (Result<PredictionResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/predict") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(PredictionResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func upsertSocialLogin(_ payload: SocialLoginPayload) async throws {
        guard let url = URL(string: "\(baseURL)/auth/social-login") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        // TODO: 백엔드가 준비되면 여기 엔드포인트에서 MySQL에 사용자 정보를 저장하세요.
        // 직접 iOS 앱에서 MySQL에 붙지 말고, 서버(API) -> MySQL 구조로 연결해야 안전합니다.
        // 추천 테이블 예시:
        // users(id, provider, provider_user_id, email, name, profile_image_url, created_at, updated_at)
        // 앱은 provider/providerUserId/email/name/profileImageURL/accessToken/idToken 정도를 보내고,
        // 서버에서 회원 upsert 후 앱 전용 세션/JWT를 내려주도록 구성하면 바로 확장 가능합니다.
    }
}
