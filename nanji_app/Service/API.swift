import Foundation

struct SocialLoginPayload: Encodable {
    let provider: String
    let providerUserId: String
    let email: String?
    let name: String?
    let profileImageURL: String?
    let accessToken: String?
    let idToken: String?

    enum CodingKeys: String, CodingKey {
        case provider
        case providerUserId = "provider_user_id"
        case email
        case name
        case profileImageURL = "profile_image_url"
        case accessToken = "access_token"
        case idToken = "id_token"
    }
}

final class APIService {
    static let shared = APIService()
    private init() {}
    
    private let baseURL = "http://127.0.0.1:8000"
    private let targetParkingLotID = 1
    private let backendUserIDKey = "auth.backendUserID"

    var currentBackendUserID: Int? {
        let value = UserDefaults.standard.integer(forKey: backendUserIDKey)
        return value > 0 ? value : nil
    }

    func setAuthenticatedUserID(_ userID: Int?) {
        if let userID, userID > 0 {
            UserDefaults.standard.set(userID, forKey: backendUserIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: backendUserIDKey)
        }
    }

    private func authorizedRequest(url: URL, method: String = "GET") throws -> URLRequest {
        guard let userID = currentBackendUserID else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(String(userID), forHTTPHeaderField: "X-User-ID")
        return request
    }
    
    func fetchCurrentStatus(completion: @escaping (Result<ParkingStatus, Error>) -> Void) {
        fetchCurrentStatus(parkingLotID: targetParkingLotID, completion: completion)
    }

    func fetchCurrentStatus(parkingLotID: Int, completion: @escaping (Result<ParkingStatus, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/parking/current/\(parkingLotID)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(CurrentParkingStatusResponse.self, from: data)
                let item = response.item
                let occupiedSpaces = item?.psOccupiedSpaces ?? 0
                let availableSpaces = item?.psAvailableSpaces ?? 0
                let status = ParkingStatus(
                    parkingName: response.parkingLotName,
                    availableSpaces: availableSpaces,
                    occupiedSpaces: occupiedSpaces,
                    totalSpaces: response.totalSpaces,
                    congestionLevel: Self.localizedCongestion(response.item?.psCongestionLevel),
                    hasData: response.hasData,
                    message: response.message
                )
                completion(.success(status))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchPrediction(completion: @escaping (Result<PredictionResponse, Error>) -> Void) {
        fetchPredictionList(targetDate: Date()) { result in
            do {
                let response = try result.get()
                let sortedItems = response.items.sorted { $0.ppPredictedTime < $1.ppPredictedTime }
                let forecastWindow = self.selectForecastWindow(from: sortedItems)
                let syntheticTimesByID = self.syntheticTimelineByPredictionID(for: forecastWindow)
                let oneHourLater = forecastWindow.first?.ppPredictedAvailableSpaces ?? 0
                let twoHoursLater = forecastWindow.dropFirst().first?.ppPredictedAvailableSpaces ?? 0

                let sortedByMostAvailable = forecastWindow.sorted {
                    $0.ppPredictedAvailableSpaces > $1.ppPredictedAvailableSpaces
                }
                let sortedByLeastAvailable = forecastWindow.sorted {
                    $0.ppPredictedAvailableSpaces < $1.ppPredictedAvailableSpaces
                }

                let freeItems = sortedByMostAvailable.filter {
                    Self.localizedCongestion($0.ppPredictedCongestionLevel) == "여유"
                }
                let busyItems = sortedByLeastAvailable.filter {
                    let localized = Self.localizedCongestion($0.ppPredictedCongestionLevel)
                    return localized == "혼잡" || localized == "매우 혼잡"
                }

                let result = PredictionResponse(
                    oneHourLater: oneHourLater,
                    twoHoursLater: twoHoursLater,
                    recommendedTime: self.displayPredictionTime(for: freeItems.first ?? sortedByMostAvailable.first, syntheticTimesByID: syntheticTimesByID) ?? "데이터 준비 중",
                    busyTime: self.displayPredictionTime(for: busyItems.first ?? sortedByLeastAvailable.first, syntheticTimesByID: syntheticTimesByID) ?? "데이터 준비 중",
                    freeTime: self.displayPredictionTime(for: freeItems.first ?? sortedByMostAvailable.first, syntheticTimesByID: syntheticTimesByID) ?? "데이터 준비 중"
                )
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchParkingLots(completion: @escaping (Result<[ParkingLotAPIItem], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/parking/lots") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data else { return }

            do {
                let response = try JSONDecoder().decode(ParkingLotListAPIResponse.self, from: data)
                completion(.success(response.items))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchDepartureTimingOptions(completion: @escaping (Result<[DepartureTimingOption], Error>) -> Void) {
        let group = DispatchGroup()

        var currentStatusResult: Result<ParkingStatus, Error>?
        var predictionListResult: Result<ParkingPredictionListResponse, Error>?

        group.enter()
        fetchCurrentStatus { result in
            currentStatusResult = result
            group.leave()
        }

        group.enter()
        fetchPredictionList(targetDate: Date()) { result in
            predictionListResult = result
            group.leave()
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            do {
                let currentStatus = try currentStatusResult?.get()
                let predictionList = try predictionListResult?.get()

                guard let predictionList else {
                    throw URLError(.badServerResponse)
                }

                let sortedItems = predictionList.items.sorted { $0.ppPredictedTime < $1.ppPredictedTime }
                let forecastWindow = self.selectForecastWindow(from: sortedItems)
                let syntheticTimesByID = self.syntheticTimelineByPredictionID(for: forecastWindow)

                var options: [DepartureTimingOption] = []
                let now = Date()

                if let currentStatus, currentStatus.hasData {
                    options.append(
                        DepartureTimingOption(
                            title: "지금 출발",
                            departureTimeText: self.clockText(from: now),
                            arrivalTimeText: self.clockText(from: Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now),
                            availableSpaces: currentStatus.availableSpaces,
                            statusText: currentStatus.congestionLevel,
                            message: self.departureMessage(
                                congestion: currentStatus.congestionLevel,
                                availableSpaces: currentStatus.availableSpaces
                            )
                        )
                    )
                }

                let futureOffsets: [(String, Int, Int)] = [
                    ("30분 후 출발", 30, 0),
                    ("1시간 후 출발", 60, 0),
                    ("2시간 후 출발", 120, 1),
                    ("3시간 후 출발", 180, 2)
                ]

                for (title, offsetMinutes, itemIndex) in futureOffsets {
                    guard forecastWindow.indices.contains(itemIndex) else { continue }
                    let item = forecastWindow[itemIndex]
                    let departureDate = Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: now) ?? now
                    let arrivalDate = Calendar.current.date(byAdding: .minute, value: 15, to: departureDate) ?? departureDate
                    let statusText = Self.localizedCongestion(item.ppPredictedCongestionLevel)

                    options.append(
                        DepartureTimingOption(
                            title: title,
                            departureTimeText: self.clockText(from: departureDate),
                            arrivalTimeText: self.clockText(from: arrivalDate),
                            availableSpaces: item.ppPredictedAvailableSpaces,
                            statusText: statusText,
                            message: self.departureMessage(
                                congestion: statusText,
                                availableSpaces: item.ppPredictedAvailableSpaces
                            )
                        )
                    )
                }

                completion(.success(options))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchFavoriteParkingLotIDs(completion: @escaping (Result<[Int], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/me/favorites") else { return }
        let request: URLRequest
        do {
            request = try authorizedRequest(url: url)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data else { return }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                let message = String(data: data, encoding: .utf8) ?? "unknown"
                print("즐겨찾기 목록 응답 실패 [\(httpResponse.statusCode)]: \(message)")
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let response = try JSONDecoder().decode(FavoriteParkingLotListAPIResponse.self, from: data)
                completion(.success(response.items.map(\.parkingLotID)))
            } catch {
                print("즐겨찾기 목록 디코딩 실패: \(String(data: data, encoding: .utf8) ?? "empty")")
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchMyProfile(completion: @escaping (Result<MyProfileAPIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/me/profile") else { return }
        let request: URLRequest
        do {
            request = try authorizedRequest(url: url)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data else { return }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                let message = String(data: data, encoding: .utf8) ?? "unknown"
                print("마이페이지 프로필 응답 실패 [\(httpResponse.statusCode)]: \(message)")
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let response = try JSONDecoder().decode(MyProfileAPIResponse.self, from: data)
                completion(.success(response))
            } catch {
                print("마이페이지 프로필 디코딩 실패: \(String(data: data, encoding: .utf8) ?? "empty")")
                completion(.failure(error))
            }
        }.resume()
    }

    func toggleFavorite(parkingLotID: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/me/favorites/toggle") else { return }
        var request: URLRequest
        do {
            request = try authorizedRequest(url: url, method: "POST")
        } catch {
            completion(.failure(error))
            return
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(
                FavoriteParkingLotToggleRequest(parkingLotID: parkingLotID)
            )
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data else { return }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                let message = String(data: data, encoding: .utf8) ?? "unknown"
                print("즐겨찾기 토글 응답 실패 [\(httpResponse.statusCode)]: \(message)")
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let response = try JSONDecoder().decode(FavoriteParkingLotToggleAPIResponse.self, from: data)
                completion(.success(response.isFavorite))
            } catch {
                print("즐겨찾기 토글 디코딩 실패: \(String(data: data, encoding: .utf8) ?? "empty")")
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchNotificationParkingLotIDs(completion: @escaping (Result<Set<Int>, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/me/notifications") else { return }
        let request: URLRequest
        do {
            request = try authorizedRequest(url: url)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data else { return }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                let message = String(data: data, encoding: .utf8) ?? "unknown"
                print("알림 설정 목록 응답 실패 [\(httpResponse.statusCode)]: \(message)")
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let response = try JSONDecoder().decode(NotificationSettingListAPIResponse.self, from: data)
                let ids = Set(response.items.filter(\.isEnabled).map(\.parkingLotID))
                completion(.success(ids))
            } catch {
                print("알림 설정 목록 디코딩 실패: \(String(data: data, encoding: .utf8) ?? "empty")")
                completion(.failure(error))
            }
        }.resume()
    }

    func updateNotificationSetting(parkingLotID: Int, isEnabled: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/me/notifications") else { return }
        var request: URLRequest
        do {
            request = try authorizedRequest(url: url, method: "POST")
        } catch {
            completion(.failure(error))
            return
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(
                NotificationSettingUpsertRequest(
                    parkingLotID: parkingLotID,
                    notificationType: "parking_status",
                    isEnabled: isEnabled
                )
            )
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data else { return }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                let message = String(data: data, encoding: .utf8) ?? "unknown"
                print("알림 설정 저장 응답 실패 [\(httpResponse.statusCode)]: \(message)")
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let response = try JSONDecoder().decode(NotificationSettingUpsertAPIResponse.self, from: data)
                completion(.success(response.isEnabled))
            } catch {
                print("알림 설정 저장 디코딩 실패: \(String(data: data, encoding: .utf8) ?? "empty")")
                completion(.failure(error))
            }
        }.resume()
    }

    func upsertSocialLogin(_ payload: SocialLoginPayload) async throws -> SocialLoginAPIResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/social-login") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "empty"
            print("소셜 로그인 연동 응답 실패 [\(httpResponse.statusCode)]: \(body)")

            if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = payload["detail"] as? String {
                throw NSError(
                    domain: "APIService",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: detail]
                )
            }

            throw NSError(
                domain: "APIService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "계정 연동 요청이 실패했습니다."]
            )
        }

        let decoded = try JSONDecoder().decode(SocialLoginAPIResponse.self, from: data)
        setAuthenticatedUserID(decoded.userID)
        return decoded
    }

    private static func localizedCongestion(_ value: String?) -> String {
        switch value {
        case "free":
            return "여유"
        case "normal":
            return "보통"
        case "busy":
            return "혼잡"
        case "full":
            return "매우 혼잡"
        default:
            return "알 수 없음"
        }
    }

    private func formatPredictionTime(_ value: String?) -> String? {
        guard let value else { return nil }
        guard let date = Self.predictionDateFormatter.date(from: value) else {
            return value
        }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.dateFormat = "M월 d일 HH:mm"
        return outputFormatter.string(from: date)
    }

    private func displayPredictionTime(
        for item: ParkingPredictionItem?,
        syntheticTimesByID: [Int: Date]
    ) -> String? {
        guard let item else { return nil }

        if let syntheticDate = syntheticTimesByID[item.ppID] {
            return self.formatRelativePredictionTime(syntheticDate)
        }

        return self.formatPredictionTime(item.ppPredictedTime)
    }

    private func formatRelativePredictionTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"

        if calendar.isDateInToday(date) {
            return "오늘 \(formatter.string(from: date))"
        }

        if calendar.isDateInTomorrow(date) {
            return "내일 \(formatter.string(from: date))"
        }

        let fullFormatter = DateFormatter()
        fullFormatter.locale = Locale(identifier: "ko_KR")
        fullFormatter.dateFormat = "M월 d일 HH:mm"
        return fullFormatter.string(from: date)
    }

    private func departureMessage(congestion: String, availableSpaces: Int) -> String {
        switch congestion {
        case "여유":
            return "주차가 비교적 수월할 가능성이 높아요."
        case "보통":
            return "조금 붐빌 수 있지만 진입 가능성이 있어요."
        case "혼잡", "매우 혼잡":
            return "주차가 어려울 수 있어 대체 주차장도 함께 보세요."
        default:
            if availableSpaces > 0 {
                return "예측 데이터를 바탕으로 계산한 결과예요."
            }
            return "데이터 준비 중"
        }
    }

    private func clockText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func selectForecastWindow(from items: [ParkingPredictionItem]) -> [ParkingPredictionItem] {
        guard !items.isEmpty else { return [] }

        let now = Date()
        let parsedItems = items.compactMap { item -> (ParkingPredictionItem, Date)? in
            guard let date = Self.predictionDateFormatter.date(from: item.ppPredictedTime) else { return nil }
            return (item, date)
        }

        guard !parsedItems.isEmpty else {
            return Array(items.prefix(24))
        }

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

    private func fetchPredictionList(
        targetDate: Date? = nil,
        completion: @escaping (Result<ParkingPredictionListResponse, Error>) -> Void
    ) {
        guard var components = URLComponents(string: "\(baseURL)/api/v1/predictions/\(targetParkingLotID)") else { return }
        if let targetDate {
            components.queryItems = [
                URLQueryItem(name: "target_date", value: Self.apiDateFormatter.string(from: targetDate))
            ]
        }
        guard let url = components.url else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data else { return }

            do {
                let response = try JSONDecoder().decode(ParkingPredictionListResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
