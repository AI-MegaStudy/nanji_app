import Foundation
import Combine

final class ParkingViewModel: ObservableObject {
    @Published var parkingName: String = "난지 한강공원 주차장"
    @Published var availableSpaces: Int = 0
    @Published var congestionLevel: String = "불러오는 중..."
    
    @Published var oneHourLater: Int = 0
    @Published var twoHoursLater: Int = 0
    @Published var recommendedTime: String = ""
    @Published var busyTime: String = ""
    @Published var freeTime: String = ""
    
    func loadCurrentStatus() {
        APIService.shared.fetchCurrentStatus { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.parkingName = data.parkingName
                    self.availableSpaces = data.availableSpaces
                    self.congestionLevel = data.congestionLevel
                case .failure(let error):
                    print("현재 상태 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadPrediction() {
        APIService.shared.fetchPrediction { result in
            DispatchQueue.main.async {
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
    
    func reserveNotification() {
        NotificationManager.shared.scheduleNotification(
            title: "난지 한강공원 주차장 예측 알림",
            body: "방문 전에 혼잡 예측을 확인하세요.",
            timeInterval: 10
        )
    }
}

