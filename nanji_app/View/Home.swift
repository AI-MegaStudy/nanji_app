import SwiftUI

struct HomeView: View {
    @StateObject private var vm = ParkingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        mainStatusCard
                        futureSection
                        actionSection
                        favoriteSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                NotificationManager.shared.requestPermission()
                vm.loadCurrentStatus()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            Text("한강공원 주차장")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 42, height: 42)

                    Image(systemName: "bell")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                colors: [Color(red: 0.67, green: 0.88, blue: 0.99), Color(red: 0.44, green: 0.72, blue: 0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var mainStatusCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                Text("난지 주차장")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                statusTag(title: "혼잡", color: Color(red: 0.98, green: 0.82, blue: 0.72), textColor: Color(red: 0.80, green: 0.40, blue: 0.20))
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("42")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.08, green: 0.13, blue: 0.24))

                Text("/ 250대")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Text("현재 남은 자리")
                .font(.subheadline)
                .foregroundColor(.secondary)

            progressBar
        }
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 12)

                Capsule()
                    .fill(Color(red: 0.94, green: 0.60, blue: 0.34))
                    .frame(width: proxy.size.width * 0.168, height: 12)
            }
        }
        .frame(height: 12)
    }

    private var futureSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.right")
                    .font(.title3)
                    .foregroundColor(Color(red: 0.30, green: 0.62, blue: 0.96))

                Text("미래 예측")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1시간 후")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("18대")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.08, green: 0.13, blue: 0.24))
                    }

                    Spacer()

                    statusTag(title: "매우 혼잡", color: Color(red: 0.99, green: 0.88, blue: 0.86), textColor: Color(red: 0.78, green: 0.29, blue: 0.17))
                }
                .padding(18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(Color(red: 0.86, green: 0.32, blue: 0.23))
                        .frame(width: 36, height: 36)
                        .background(Color(red: 0.99, green: 0.92, blue: 0.90))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘 가장 혼잡한 시간")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("17:00")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.86, green: 0.32, blue: 0.23))
                    }

                    Spacer()
                }
                .padding(18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(red: 0.99, green: 0.92, blue: 0.90), lineWidth: 1)
                )
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            actionRow(icon: "location.fill", title: "대체 주차장 보기", subtitle: "주변 주차장 추천")
            actionRow(icon: "clock.fill", title: "출발 타이밍 추천", subtitle: "언제 출발해야 할까요?")
            actionRow(icon: "chart.bar.fill", title: "시간대별 분석", subtitle: "예측 그래프 보기")
        }
    }

    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("즐겨찾기")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text("설정")
                    .font(.footnote)
                    .foregroundColor(Color.blue)
            }

            Text("자주 가는 주차장을 저장하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }

    private func statusTag(title: String, color: Color, textColor: Color) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
    }

    private func actionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
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
