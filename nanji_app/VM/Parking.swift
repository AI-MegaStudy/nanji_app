import Foundation
import Combine

final class ParkingViewModel: ObservableObject {
    @Published var parkingName: String = "난지 메인 주차장"
    @Published var availableSpaces: Int = 0
    @Published var occupiedSpaces: Int = 0
    @Published var totalSpaces: Int = 0
    @Published var congestionLevel: String = "불러오는 중..."
    @Published var currentStatusMessage: String = ""
    
    @Published var oneHourLater: Int = 0
    @Published var twoHoursLater: Int = 0
    @Published var recommendedTime: String = ""
    @Published var busyTime: String = ""
    @Published var freeTime: String = ""
    @Published var alternativeParkingLots: [ParkingLotAPIItem] = []
    @Published var departureTimingOptions: [DepartureTimingOption] = []
    
    func loadCurrentStatus() {
        APIService.shared.fetchCurrentStatus { result in
            Task { @MainActor in
                switch result {
                case .success(let data):
                    self.parkingName = data.parkingName
                    self.availableSpaces = data.availableSpaces
                    self.occupiedSpaces = data.occupiedSpaces
                    self.totalSpaces = data.totalSpaces
                    self.congestionLevel = data.congestionLevel
                    self.currentStatusMessage = data.message ?? ""
                case .failure(let error):
                    print("현재 상태 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadPrediction() {
        APIService.shared.fetchPrediction { result in
            Task { @MainActor in
                switch result {
                case .success(let data):
                    self.oneHourLater = data.oneHourLater
                    self.twoHoursLater = data.twoHoursLater
                    self.recommendedTime = data.recommendedTime
                    self.busyTime = data.busyTime
                    self.freeTime = data.freeTime
                case .failure(let error):
                    print("예측 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadParkingLots() {
        APIService.shared.fetchParkingLots { result in
            Task { @MainActor in
                switch result {
                case .success(let items):
                    self.alternativeParkingLots = items.filter { $0.pID != 1 }
                case .failure(let error):
                    print("주차장 목록 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadDepartureTimingOptions() {
        APIService.shared.fetchDepartureTimingOptions { result in
            Task { @MainActor in
                switch result {
                case .success(let items):
                    self.departureTimingOptions = items
                case .failure(let error):
                    print("출발 타이밍 옵션 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func reserveNotification() {
        NotificationManager.shared.scheduleNotification(
            title: "자리난지 주차 예측 알림",
            body: "방문 전에 혼잡 예측을 확인하세요.",
            timeInterval: 10
        )
    }

    var occupancyProgress: Double {
        guard totalSpaces > 0 else { return 0 }
        return min(max(Double(occupiedSpaces) / Double(totalSpaces), 0), 1)
    }

    var alternativeParkingSummary: String {
        let names = alternativeParkingLots.prefix(3).map(\.pDisplayName)
        return names.isEmpty ? "주변 주차장 추천" : names.joined(separator: " · ")
    }
}
