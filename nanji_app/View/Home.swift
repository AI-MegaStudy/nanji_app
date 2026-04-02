import SwiftUI

struct HomeView: View {
    @StateObject private var vm = ParkingViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.12),
                        Color.white,
                        Color.green.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // 상단 타이틀 영역
                        VStack(alignment: .leading, spacing: 8) {
                            Text("한강공원 주차장 예측")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("실시간 현황과 1시간 후 예측 정보를 확인하세요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 메인 상태 카드
                        VStack(spacing: 18) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(vm.parkingName)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Text("현재 운영 상태")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(vm.congestionLevel)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(congestionColor.opacity(0.15))
                                    .foregroundColor(congestionColor)
                                    .clipShape(Capsule())
                            }
                            
                            Divider()
                            
                            VStack(spacing: 8) {
                                Text("현재 남은 자리")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(vm.availableSpaces)")
                                    .font(.system(size: 54, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text(statusMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                infoCard(
                                    title: "혼잡도",
                                    value: vm.congestionLevel,
                                    systemImage: "car.fill"
                                )
                                
                                infoCard(
                                    title: "예상 상태",
                                    value: predictedStatusText,
                                    systemImage: "clock.arrow.circlepath"
                                )
                            }
                        }
                        .padding(24)
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                        
                        // 액션 버튼 영역
                        VStack(spacing: 14) {
                            NavigationLink {
                                PredictionView(vm: vm)
                            } label: {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                    Text("예측 결과 보기")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            Button {
                                vm.reserveNotification()
                            } label: {
                                HStack {
                                    Image(systemName: "bell.badge")
                                    Text("혼잡 알림 설정")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.95))
                                .foregroundColor(.primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                NotificationManager.shared.requestPermission()
                vm.loadCurrentStatus()
            }
        }
    }
    
    // 혼잡도 색상
    private var congestionColor: Color {
        switch vm.congestionLevel {
        case "여유":
            return .green
        case "보통":
            return .orange
        case "혼잡":
            return .red
        default:
            return .gray
        }
    }
    
    // 상태 메시지
    private var statusMessage: String {
        switch vm.congestionLevel {
        case "여유":
            return "비교적 원활하게 주차 가능합니다"
        case "보통":
            return "혼잡이 증가하는 시간대입니다"
        case "혼잡":
            return "대체 주차장 확인을 권장합니다"
        default:
            return "실시간 상태를 불러오는 중입니다"
        }
    }
    
    // 예측용 텍스트
    private var predictedStatusText: String {
        if vm.availableSpaces >= 30 {
            return "안정적"
        } else if vm.availableSpaces >= 10 {
            return "주의"
        } else {
            return "혼잡 예상"
        }
    }
    
    // 작은 정보 카드
    @ViewBuilder
    private func infoCard(title: String, value: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
