import Foundation

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
}
