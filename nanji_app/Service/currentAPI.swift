import Foundation

// MARK: - Models matching the API payloads
struct CurrentParkingStatus: Codable, Equatable {
    let parkingName: String
    let availableSpaces: Int
    let congestionLevel: String
}

struct PredictionResponse: Codable, Equatable {
    let oneHourLater: Int
    let twoHoursLater: Int
    let recommendedTime: String
    let busyTime: String
    let freeTime: String
}

// MARK: - A lightweight provider to supply data (stub/mock)
// Replace implementations with real networking later if needed.
enum CurrentAPI {
    static func fetchCurrent() async throws -> CurrentParkingStatus {
        // Stubbed data equivalent to the original FastAPI response
        return CurrentParkingStatus(
            parkingName: "난지 한강공원 주차장",
            availableSpaces: 42,
            congestionLevel: "보통"
        )
    }

    static func fetchPrediction() async throws -> PredictionResponse {
        // Stubbed data equivalent to the original FastAPI response
        return PredictionResponse(
            oneHourLater: 30,
            twoHoursLater: 18,
            recommendedTime: "오전 10시 전후",
            busyTime: "오후 2시~4시",
            freeTime: "오전 9시~11시"
        )
    }
}
