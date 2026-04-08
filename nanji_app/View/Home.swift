import SwiftUI

struct HomeView: View {
    @StateObject private var vm = ParkingViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        mainStatusCard
                        quickInfoSection
                        actionSection
                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Parking Forecast")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
                vm.loadCurrentStatus()
            }
        }
    }
}

// MARK: - Sections
private extension HomeView {
    
    var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(.systemGray6),
                Color.white,
                Color(.systemBlue).opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("한강공원 주차장")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(vm.parkingName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            Text("실시간 잔여 주차 공간과 혼잡 예측 정보를 확인하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var mainStatusCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Availability")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                    
                    Text("현재 남은 자리")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                statusBadge
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(vm.availableSpaces)")
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text(statusDescription)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.88))
            }
            
            HStack(spacing: 12) {
                metricPill(
                    title: "혼잡도",
                    value: vm.congestionLevel,
                    icon: congestionIcon
                )
                
                metricPill(
                    title: "예측 상태",
                    value: predictedStatus,
                    icon: "clock.arrow.circlepath"
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.16, blue: 0.28),
                    Color(red: 0.16, green: 0.34, blue: 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.blue.opacity(0.18), radius: 20, x: 0, y: 12)
    }
    
    var quickInfoSection: some View {
        HStack(spacing: 14) {
            glassInfoCard(
                title: "운영 상태",
                value: "정상",
                icon: "checkmark.seal.fill"
            )
            
            glassInfoCard(
                title: "추천 행동",
                value: recommendationText,
                icon: "sparkles"
            )
        }
    }
    
    var actionSection: some View {
        VStack(spacing: 14) {
            NavigationLink {
                PredictionView(vm: vm)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                    
                    Text("예측 결과 보기")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 58)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .blue.opacity(0.18), radius: 12, x: 0, y: 6)
            }
            
            Button {
                vm.reserveNotification()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .font(.headline)
                    
                    Text("혼잡 알림 설정")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 18)
                .frame(height: 58)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
        }
    }
    
    var footerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("서비스 안내")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("실시간 상태와 과거 패턴 기반 예측 결과를 제공하며, 혼잡이 예상될 경우 알림 기능으로 미리 확인할 수 있습니다.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

// MARK: - Components
private extension HomeView {
    
    var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(congestionColor)
                .frame(width: 8, height: 8)
            
            Text(vm.congestionLevel)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.16))
        .clipShape(Capsule())
    }
    
    func metricPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.75))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    func glassInfoCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Derived State
private extension HomeView {
    
    var congestionColor: Color {
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
    
    var congestionIcon: String {
        switch vm.congestionLevel {
        case "여유":
            return "checkmark.circle.fill"
        case "보통":
            return "exclamationmark.triangle.fill"
        case "혼잡":
            return "xmark.octagon.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    var statusDescription: String {
        switch vm.congestionLevel {
        case "여유":
            return "현재 주차 여유가 있어 비교적 원활하게 이용할 수 있습니다."
        case "보통":
            return "혼잡이 증가하는 시간대로, 도착 전 예측 결과 확인을 권장합니다."
        case "혼잡":
            return "현재 혼잡도가 높아 대체 주차장 또는 알림 기능 사용을 권장합니다."
        default:
            return "실시간 데이터를 불러오는 중입니다."
        }
    }
    
    var predictedStatus: String {
        if vm.availableSpaces >= 30 {
            return "안정적"
        } else if vm.availableSpaces >= 10 {
            return "주의"
        } else {
            return "혼잡 예상"
        }
    }
    
    var recommendationText: String {
        if vm.availableSpaces >= 30 {
            return "바로 방문 추천"
        } else if vm.availableSpaces >= 10 {
            return "출발 전 확인"
        } else {
            return "대체 주차장 검토"
        }
    }
}
