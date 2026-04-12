import Foundation

struct ParkingStatus: Codable {
    let parkingName: String
    let availableSpaces: Int
    let occupiedSpaces: Int
    let totalSpaces: Int
    let congestionLevel: String
    let hasData: Bool
    let message: String?
}
