import Foundation

struct HourlyAnalysisAPI {
    var baseURL: URL = URL(string: "http://127.0.0.1:8000")!
    var session: URLSession = .shared
    var parkingLotID: Int = 1

    func fetchHourlyAnalysis(request: HourlyAnalysisRequest = .sample) async throws -> HourlyAnalysisResponse {
        let requestURL = baseURL.appendingPathComponent("api/v1/predictions/\(parkingLotID)")
        let urlRequest = URLRequest(url: requestURL)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            try validate(response: response)
            let decoded = try decodePredictionList(data)
            return buildHourlyAnalysis(from: decoded)
        } catch {
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

    private func decode(_ data: Data) throws -> HourlyAnalysisResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(HourlyAnalysisResponse.self, from: data)
    }

    private func decodePredictionList(_ data: Data) throws -> ParkingPredictionListResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(ParkingPredictionListResponse.self, from: data)
    }

    private func buildHourlyAnalysis(from response: ParkingPredictionListResponse) -> HourlyAnalysisResponse {
        let sortedItems = response.items.sorted { $0.ppPredictedTime < $1.ppPredictedTime }
        let selectedItems = selectForecastWindow(from: sortedItems)
        let syntheticDatesByID = syntheticTimelineByPredictionID(for: selectedItems)

        let hourlyData = selectedItems.map { item in
            let date = syntheticDatesByID[item.ppID] ?? Self.predictionDateFormatter.date(from: item.ppPredictedTime) ?? Date()
            return HourlyAnalysisPoint(
                time: HourlyAnalysisDateFormatter.hourText(from: date),
                predictedActiveCars: Double(item.ppPredictedOccupiedSpaces),
                predictedCongestionPercent: Double(item.ppPredictedOccupancyRate) ?? 0,
                predictedAvailableSpaces: item.ppPredictedAvailableSpaces,
                isPrediction: true
            )
        }

        let peakItem = hourlyData.max { lhs, rhs in
            lhs.occupancyValue < rhs.occupancyValue
        }

        let bestItem = hourlyData.max { lhs, rhs in
            lhs.availableSpacesValue < rhs.availableSpacesValue
        }

        let firstItem = hourlyData.first

        return HourlyAnalysisResponse(
            parkingZone: "난지 메인 주차장",
            targetTime: Self.isoOutputFormatter.string(from: syntheticDatesByID[selectedItems.first?.ppID ?? -1] ?? Date()),
            generatedAt: Self.isoOutputFormatter.string(from: Date()),
            predictedActiveCars: firstItem?.predictedActiveCars ?? 0,
            hourlyData: hourlyData,
            peakTime: peakItem?.time ?? "데이터 준비 중",
            recommendedTimeWindow: bestItem?.time ?? "데이터 준비 중",
            modelInfo: HourlyAnalysisModelInfo(
                modelName: selectedItems.first?.ppModelVersion ?? "weighted_core_v1_test_import",
                r2: 0.0,
                rmse: 0.0,
                mae: 0.0,
                evaluatedOn: "prediction_import"
            ),
            predictedCongestionPercent: firstItem?.predictedCongestionPercent,
            predictedAvailableSpaces: firstItem?.predictedAvailableSpaces
        )
    }

    private func selectForecastWindow(from items: [ParkingPredictionItem]) -> [ParkingPredictionItem] {
        guard !items.isEmpty else { return [] }

        let parsedItems = items.compactMap { item -> (ParkingPredictionItem, Date)? in
            guard let date = Self.predictionDateFormatter.date(from: item.ppPredictedTime) else { return nil }
            return (item, date)
        }

        guard !parsedItems.isEmpty else {
            return Array(items.prefix(24))
        }

        let now = Date()

        if let futureIndex = parsedItems.firstIndex(where: { $0.1 >= now }) {
            return Array(parsedItems[futureIndex..<min(futureIndex + 24, parsedItems.count)]).map(\.0)
        }

        let nextHour = (Calendar.current.component(.hour, from: now) + 1) % 24
        if let nearestByHourIndex = parsedItems.firstIndex(where: {
            Calendar.current.component(.hour, from: $0.1) >= nextHour
        }) {
            return Array(parsedItems[nearestByHourIndex..<min(nearestByHourIndex + 24, parsedItems.count)]).map(\.0)
        }

        return Array(parsedItems.prefix(24)).map(\.0)
    }

    private func syntheticTimelineByPredictionID(for items: [ParkingPredictionItem]) -> [Int: Date] {
        guard !items.isEmpty else { return [:] }

        let calendar = Calendar.current
        let now = Date()
        let startOfCurrentHour = calendar.date(
            bySettingHour: calendar.component(.hour, from: now),
            minute: 0,
            second: 0,
            of: now
        ) ?? now
        let firstDisplayDate = calendar.date(byAdding: .hour, value: 1, to: startOfCurrentHour) ?? now

        return Dictionary(uniqueKeysWithValues: items.enumerated().map { index, item in
            let displayDate = calendar.date(byAdding: .hour, value: index, to: firstDisplayDate) ?? firstDisplayDate
            return (item.ppID, displayDate)
        })
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

    private static let predictionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let isoOutputFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()
}
