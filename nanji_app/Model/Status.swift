import Foundation

struct ParkingStatus: Codable {
    let parkingName: String
    let availableSpaces: Int
    let congestionLevel: String
}
