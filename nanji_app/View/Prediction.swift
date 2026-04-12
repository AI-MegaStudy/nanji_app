import SwiftUI

struct PredictionView: View {
    @ObservedObject var vm: ParkingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("예측 결과")
                .font(.title)
                .bold()
            
            VStack(spacing: 12) {
                Text("1시간 후 예상 남은 자리: \(vm.oneHourLater)")
                Text("2시간 후 예상 남은 자리: \(vm.twoHoursLater)")
                Text("추천 방문 시간: \(vm.recommendedTime)")
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            
            NavigationLink("추천 방문 시간 보기") {
                RecommendationView(vm: vm)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .onAppear {
            vm.loadPrediction()
        }
    }
}
