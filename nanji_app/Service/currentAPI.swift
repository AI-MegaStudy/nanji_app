import Foundation

struct DepartureTimingOption: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let departureTimeText: String
    let arrivalTimeText: String
    let availableSpaces: Int
    let statusText: String
    let message: String
}

struct CurrentParkingStatusResponse: Codable, Equatable {
    let parkingLotID: Int
    let parkingLotName: String
    let supportsRealtimeCongestion: Bool
    let hasData: Bool
    let item: CurrentParkingStatusItem?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case parkingLotID = "parking_lot_id"
        case parkingLotName = "parking_lot_name"
        case supportsRealtimeCongestion = "supports_realtime_congestion"
        case hasData = "has_data"
        case item
        case message
    }
}

struct CurrentParkingStatusItem: Codable, Equatable {
    let psID: Int
    let psParkingLotID: Int
    let psRecordedAt: String
    let psOccupiedSpaces: Int
    let psAvailableSpaces: Int
    let psOccupancyRate: String
    let psCongestionLevel: String
    let psSourceType: String

    enum CodingKeys: String, CodingKey {
        case psID = "ps_id"
        case psParkingLotID = "ps_parking_lot_id"
        case psRecordedAt = "ps_recorded_at"
        case psOccupiedSpaces = "ps_occupied_spaces"
        case psAvailableSpaces = "ps_available_spaces"
        case psOccupancyRate = "ps_occupancy_rate"
        case psCongestionLevel = "ps_congestion_level"
        case psSourceType = "ps_source_type"
    }
}

struct ParkingPredictionListResponse: Codable, Equatable {
    let count: Int
    let items: [ParkingPredictionItem]
}

struct PredictionResponse: Codable, Equatable {
    let oneHourLater: Int
    let twoHoursLater: Int
    let recommendedTime: String
    let busyTime: String
    let freeTime: String
}

struct ParkingPredictionItem: Codable, Equatable {
    let ppID: Int
    let ppParkingLotID: Int
    let ppBaseTime: String
    let ppPredictedTime: String
    let ppPredictionHorizonMinutes: Int
    let ppPredictedOccupiedSpaces: Int
    let ppPredictedAvailableSpaces: Int
    let ppPredictedOccupancyRate: String
    let ppPredictedCongestionLevel: String
    let ppConfidenceScore: String?
    let ppModelVersion: String?

    enum CodingKeys: String, CodingKey {
        case ppID = "pp_id"
        case ppParkingLotID = "pp_parking_lot_id"
        case ppBaseTime = "pp_base_time"
        case ppPredictedTime = "pp_predicted_time"
        case ppPredictionHorizonMinutes = "pp_prediction_horizon_minutes"
        case ppPredictedOccupiedSpaces = "pp_predicted_occupied_spaces"
        case ppPredictedAvailableSpaces = "pp_predicted_available_spaces"
        case ppPredictedOccupancyRate = "pp_predicted_occupancy_rate"
        case ppPredictedCongestionLevel = "pp_predicted_congestion_level"
        case ppConfidenceScore = "pp_confidence_score"
        case ppModelVersion = "pp_model_version"
    }
}

struct ParkingLotListAPIResponse: Codable, Equatable {
    let count: Int
    let items: [ParkingLotAPIItem]
}

struct FavoriteParkingLotAPIItem: Codable, Equatable {
    let parkingLotID: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case parkingLotID = "parking_lot_id"
        case createdAt = "created_at"
    }
}

struct MyProfileAPIResponse: Codable, Equatable {
    let userID: Int
    let provider: String
    let name: String
    let email: String?
    let favoriteCount: Int
    let enabledNotificationCount: Int

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case provider
        case name
        case email
        case favoriteCount = "favorite_count"
        case enabledNotificationCount = "enabled_notification_count"
    }
}

struct SocialLoginAPIResponse: Codable, Equatable {
    let userID: Int
    let provider: String
    let providerUserID: String
    let email: String?
    let name: String
    let isNewUser: Bool

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case provider
        case providerUserID = "provider_user_id"
        case email
        case name
        case isNewUser = "is_new_user"
    }
}

struct FavoriteParkingLotListAPIResponse: Codable, Equatable {
    let userID: Int
    let count: Int
    let items: [FavoriteParkingLotAPIItem]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case count
        case items
    }
}

struct FavoriteParkingLotToggleRequest: Encodable {
    let parkingLotID: Int

    enum CodingKeys: String, CodingKey {
        case parkingLotID = "parking_lot_id"
    }
}

struct FavoriteParkingLotToggleAPIResponse: Codable, Equatable {
    let userID: Int
    let parkingLotID: Int
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case parkingLotID = "parking_lot_id"
        case isFavorite = "is_favorite"
    }
}

struct NotificationSettingAPIItem: Codable, Equatable {
    let parkingLotID: Int
    let notificationType: String
    let isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case parkingLotID = "parking_lot_id"
        case notificationType = "notification_type"
        case isEnabled = "is_enabled"
    }
}

struct NotificationSettingListAPIResponse: Codable, Equatable {
    let userID: Int
    let count: Int
    let items: [NotificationSettingAPIItem]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case count
        case items
    }
}

struct NotificationSettingUpsertRequest: Encodable {
    let parkingLotID: Int
    let notificationType: String
    let isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case parkingLotID = "parking_lot_id"
        case notificationType = "notification_type"
        case isEnabled = "is_enabled"
    }
}

struct NotificationSettingUpsertAPIResponse: Codable, Equatable {
    let userID: Int
    let parkingLotID: Int
    let notificationType: String
    let isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case parkingLotID = "parking_lot_id"
        case notificationType = "notification_type"
        case isEnabled = "is_enabled"
    }
}

struct ParkingLotAPIItem: Codable, Equatable, Identifiable {
    let pID: Int
    let pName: String
    let pDisplayName: String
    let pAddress: String?
    let pLatitude: Double
    let pLongitude: Double
    let pTotalSpaces: Int
    let pSupportsPrediction: Bool

    var id: Int { pID }

    enum CodingKeys: String, CodingKey {
        case pID = "p_id"
        case pName = "p_name"
        case pDisplayName = "p_display_name"
        case pAddress = "p_address"
        case pLatitude = "p_latitude"
        case pLongitude = "p_longitude"
        case pTotalSpaces = "p_total_spaces"
        case pSupportsPrediction = "p_supports_prediction"
    }

    init(
        pID: Int,
        pName: String,
        pDisplayName: String,
        pAddress: String?,
        pLatitude: Double,
        pLongitude: Double,
        pTotalSpaces: Int,
        pSupportsPrediction: Bool
    ) {
        self.pID = pID
        self.pName = pName
        self.pDisplayName = pDisplayName
        self.pAddress = pAddress
        self.pLatitude = pLatitude
        self.pLongitude = pLongitude
        self.pTotalSpaces = pTotalSpaces
        self.pSupportsPrediction = pSupportsPrediction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        pID = try container.decode(Int.self, forKey: .pID)
        pName = try container.decode(String.self, forKey: .pName)
        pDisplayName = try container.decode(String.self, forKey: .pDisplayName)
        pAddress = try container.decodeIfPresent(String.self, forKey: .pAddress)
        pLatitude = try container.decodeFlexibleDouble(forKey: .pLatitude)
        pLongitude = try container.decodeFlexibleDouble(forKey: .pLongitude)
        pTotalSpaces = try container.decode(Int.self, forKey: .pTotalSpaces)
        pSupportsPrediction = try container.decodeFlexibleBool(forKey: .pSupportsPrediction)
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }

        if let value = try? decode(String.self, forKey: key),
           let doubleValue = Double(value) {
            return doubleValue
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Double 또는 Double 문자열 형식이 아닙니다."
        )
    }

    func decodeFlexibleBool(forKey key: Key) throws -> Bool {
        if let value = try? decode(Bool.self, forKey: key) {
            return value
        }

        if let value = try? decode(Int.self, forKey: key) {
            return value != 0
        }

        if let value = try? decode(String.self, forKey: key) {
            switch value.lowercased() {
            case "true", "1":
                return true
            case "false", "0":
                return false
            default:
                break
            }
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Bool 또는 Bool 호환 형식이 아닙니다."
        )
    }
}
