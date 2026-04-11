import Foundation

struct HourlyAnalysisRequest: Codable {
    let parkingZone: String
    let targetTime: String
    let temperature2m: Double
    let relativeHumidity2m: Double
    let weatherCode: Int
    let windGusts10m: Double
    let totalCapacity: Int?

    static let sample = HourlyAnalysisRequest(
        parkingZone: "nanji",
        targetTime: "2026-04-11T15:00:00+09:00",
        temperature2m: 21.4,
        relativeHumidity2m: 54.0,
        weatherCode: 1,
        windGusts10m: 4.8,
        totalCapacity: 800
    )
}

struct HourlyAnalysisResponse: Codable {
    let parkingZone: String
    let targetTime: String
    let generatedAt: String
    let predictedActiveCars: Double
    let hourlyData: [HourlyAnalysisPoint]
    let peakTime: String
    let recommendedTimeWindow: String
    let modelInfo: HourlyAnalysisModelInfo
    let predictedCongestionPercent: Double?
    let predictedAvailableSpaces: Int?

    var targetTimeText: String {
        HourlyAnalysisDateFormatter.displayText(from: targetTime)
    }

    var generatedAtText: String {
        HourlyAnalysisDateFormatter.generatedAtText(from: generatedAt)
    }
}

struct HourlyAnalysisModelInfo: Codable {
    let modelName: String
    let r2: Double
    let rmse: Double
    let mae: Double
    let evaluatedOn: String
}

struct HourlyAnalysisPoint: Codable, Identifiable {
    let id = UUID()
    let time: String
    let predictedActiveCars: Double
    let predictedCongestionPercent: Double?
    let predictedAvailableSpaces: Int?
    let isPrediction: Bool

    enum CodingKeys: String, CodingKey {
        case time
        case predictedActiveCars
        case predictedCongestionPercent
        case predictedAvailableSpaces
        case isPrediction
    }

    var occupancyValue: Int {
        Int(round(predictedCongestionPercent ?? 0))
    }

    var availableSpacesValue: Int {
        predictedAvailableSpaces ?? 0
    }
}

enum HourlyAnalysisDateFormatter {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일 HH:mm 예측"
        return formatter
    }()

    private static let generatedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일 HH:mm 기준"
        return formatter
    }()

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func date(from rawValue: String) -> Date? {
        isoFormatter.date(from: rawValue) ?? fallbackFormatter.date(from: rawValue)
    }

    static func displayText(from rawValue: String) -> String {
        if let date = date(from: rawValue) {
            return displayFormatter.string(from: date)
        }
        return rawValue
    }

    static func generatedAtText(from rawValue: String) -> String {
        if let date = date(from: rawValue) {
            return generatedAtFormatter.string(from: date)
        }
        return rawValue
    }

    static func hourText(from date: Date) -> String {
        hourFormatter.string(from: date)
    }
}
