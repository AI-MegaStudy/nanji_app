import Foundation

struct HourlyAnalysisAPI {
    var baseURL: URL = URL(string: "http://127.0.0.1:8000")!
    var session: URLSession = .shared
    var parkingLotID: Int = 1

    func fetchHourlyAnalysis(request: HourlyAnalysisRequest = .sample) async throws -> HourlyAnalysisResponse {
        let targetDate = HourlyAnalysisDateFormatter.date(from: request.targetTime) ?? Date()

        do {
            async let predictionResponse = fetchPredictionList(for: targetDate)
            async let statusHistoryResponse = fetchStatusHistory(for: targetDate)
            let predictions = try await predictionResponse
            let statusHistory = try await statusHistoryResponse
            return buildHourlyAnalysis(from: predictions, statusHistory: statusHistory)
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

    private func decodeStatusHistory(_ data: Data) throws -> ParkingStatusHistoryResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(ParkingStatusHistoryResponse.self, from: data)
    }

    private func buildHourlyAnalysis(
        from response: ParkingPredictionListResponse,
        statusHistory: ParkingStatusHistoryResponse
    ) -> HourlyAnalysisResponse {
        let sortedItems = response.items.sorted { $0.ppPredictedTime < $1.ppPredictedTime }
        let hourlyData = mergeTimeline(predictions: sortedItems, actuals: statusHistory.items)

        let peakItem = hourlyData.max { lhs, rhs in
            lhs.occupancyValue < rhs.occupancyValue
        }

        let bestItem = hourlyData.max { lhs, rhs in
            lhs.availableSpacesValue < rhs.availableSpacesValue
        }

        let firstFutureItem = hourlyData.first(where: { $0.isPrediction }) ?? hourlyData.last

        return HourlyAnalysisResponse(
            parkingZone: statusHistory.parkingLotName,
            targetTime: Self.isoOutputFormatter.string(from: firstFutureItem?.date ?? Date()),
            generatedAt: Self.isoOutputFormatter.string(from: Date()),
            predictedActiveCars: firstFutureItem?.predictedActiveCars ?? 0,
            hourlyData: hourlyData,
            peakTime: peakItem?.time ?? "데이터 준비 중",
            recommendedTimeWindow: bestItem?.time ?? "데이터 준비 중",
            modelInfo: HourlyAnalysisModelInfo(
                modelName: sortedItems.first?.ppModelVersion ?? "weighted_core_v1_test_import",
                r2: 0.0,
                rmse: 0.0,
                mae: 0.0,
                evaluatedOn: statusHistory.targetDate
            ),
            predictedCongestionPercent: firstFutureItem?.predictedCongestionPercent,
            predictedAvailableSpaces: firstFutureItem?.predictedAvailableSpaces
        )
    }

    private func mergeTimeline(
        predictions: [ParkingPredictionItem],
        actuals: [CurrentParkingStatusItem]
    ) -> [HourlyAnalysisPoint] {
        let calendar = Self.seoulCalendar
        let currentHour = calendar.dateInterval(of: .hour, for: Date())?.start ?? Date()
        let latestActualByHour = actuals.reduce(into: [Date: CurrentParkingStatusItem]()) { partialResult, item in
            guard let recordedAt = Self.predictionDateFormatter.date(from: item.psRecordedAt),
                  let hourStart = calendar.dateInterval(of: .hour, for: recordedAt)?.start else {
                return
            }
            partialResult[hourStart] = item
        }
        let predictionByHour = predictions.reduce(into: [Date: ParkingPredictionItem]()) { partialResult, item in
            guard let date = Self.predictionDateFormatter.date(from: item.ppPredictedTime),
                  let hourStart = calendar.dateInterval(of: .hour, for: date)?.start else {
                return
            }
            partialResult[hourStart] = item
        }

        let allHours = Set(latestActualByHour.keys).union(predictionByHour.keys).sorted()

        return allHours.compactMap { hourStart in
            if hourStart <= currentHour, let actual = latestActualByHour[hourStart] {
                return HourlyAnalysisPoint(
                    time: HourlyAnalysisDateFormatter.hourText(from: hourStart),
                    predictedActiveCars: Double(actual.psOccupiedSpaces),
                    predictedCongestionPercent: Double(actual.psOccupancyRate) ?? 0,
                    predictedAvailableSpaces: actual.psAvailableSpaces,
                    isPrediction: false,
                    date: hourStart
                )
            }

            guard let item = predictionByHour[hourStart] else {
                return nil
            }

            return HourlyAnalysisPoint(
                time: HourlyAnalysisDateFormatter.hourText(from: hourStart),
                predictedActiveCars: Double(item.ppPredictedOccupiedSpaces),
                predictedCongestionPercent: Double(item.ppPredictedOccupancyRate) ?? 0,
                predictedAvailableSpaces: item.ppPredictedAvailableSpaces,
                isPrediction: true,
                date: hourStart
            )
        }
    }

    private func fetchPredictionList(for targetDate: Date) async throws -> ParkingPredictionListResponse {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("api/v1/predictions/\(parkingLotID)"),
            resolvingAgainstBaseURL: false
        ) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "target_date", value: Self.apiDateFormatter.string(from: targetDate))
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(for: URLRequest(url: url))
        try validate(response: response)
        return try decodePredictionList(data)
    }

    private func fetchStatusHistory(for targetDate: Date) async throws -> ParkingStatusHistoryResponse {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("api/v1/parking/history/\(parkingLotID)"),
            resolvingAgainstBaseURL: false
        ) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "target_date", value: Self.apiDateFormatter.string(from: targetDate))
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(for: URLRequest(url: url))
        try validate(response: response)
        return try decodeStatusHistory(data)
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
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let seoulCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }()

    private static let isoOutputFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()
}
