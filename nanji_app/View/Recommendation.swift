import SwiftUI

struct RecommendationView: View {
    @ObservedObject var vm: ParkingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("방문 추천")
                .font(.title)
                .bold()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("추천 방문 시간: \(vm.recommendedTime)")
                Text("혼잡 예상 시간: \(vm.busyTime)")
                Text("여유 예상 시간: \(vm.freeTime)")
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
    }
}
