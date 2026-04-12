import Foundation

struct HourlyAnalysisAPI {
    var baseURL: URL = URL(string: "http://127.0.0.1:8000")!
    var session: URLSession = .shared

    func fetchHourlyAnalysis(request: HourlyAnalysisRequest = .sample) async throws -> HourlyAnalysisResponse {
        let requestURL = baseURL.appendingPathComponent("predict")
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encode(request)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            try validate(response: response)
            return try decode(data)
        } catch {
            // FastAPI 예시 서버가 아직 연결되지 않았어도 화면 구성을 이어갈 수 있도록 예시 응답을 사용한다.
            return try decode(Self.samplePayload)
        }
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func encode(_ request: HourlyAnalysisRequest) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(request)
    }

    private func decode(_ data: Data) throws -> HourlyAnalysisResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(HourlyAnalysisResponse.self, from: data)
    }
}

extension HourlyAnalysisAPI {
    // 주신 FastAPI `/predict` 예시 코드에 맞춘 응답 예시 형태.
    static let samplePayload = Data("""
    {
      "parking_zone": "nanji",
      "target_time": "2026-04-11T15:00:00+09:00",
      "generated_at": "2026-04-11T14:30:00+09:00",
      "predicted_active_cars": 412.3,
      "hourly_data": [
        {
          "time": "15:00",
          "predicted_active_cars": 285.0,
          "predicted_congestion_percent": 35.6,
          "predicted_available_spaces": 515,
          "is_prediction": false
        },
        {
          "time": "16:00",
          "predicted_active_cars": 338.0,
          "predicted_congestion_percent": 42.3,
          "predicted_available_spaces": 462,
          "is_prediction": true
        },
        {
          "time": "17:00",
          "predicted_active_cars": 412.3,
          "predicted_congestion_percent": 51.5,
          "predicted_available_spaces": 388,
          "is_prediction": true
        },
        {
          "time": "18:00",
          "predicted_active_cars": 468.0,
          "predicted_congestion_percent": 58.5,
          "predicted_available_spaces": 332,
          "is_prediction": true
        },
        {
          "time": "19:00",
          "predicted_active_cars": 441.0,
          "predicted_congestion_percent": 55.1,
          "predicted_available_spaces": 359,
          "is_prediction": true
        },
        {
          "time": "20:00",
          "predicted_active_cars": 376.0,
          "predicted_congestion_percent": 47.0,
          "predicted_available_spaces": 424,
          "is_prediction": true
        }
      ],
      "peak_time": "18:00",
      "recommended_time_window": "15:00 around",
      "model_info": {
        "model_name": "weather_only_extended_final",
        "r2": 0.7655,
        "rmse": 55.0747,
        "mae": 27.9298,
        "evaluated_on": "test"
      },
      "predicted_congestion_percent": 51.5,
      "predicted_available_spaces": 388
    }
    """.utf8)
}
