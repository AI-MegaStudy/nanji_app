import SwiftUI

struct HomeView: View {
    @StateObject private var vm = ParkingViewModel()
    @State private var showDataNotice = false
    @State private var hideDataNoticePermanently = false
    @AppStorage("hide_home_data_notice") private var hideHomeDataNotice = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    topBar

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            mainStatusCard
                            futureSection
                            actionSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                }

                if showDataNotice {
                    Color.black.opacity(0.24)
                        .ignoresSafeArea()

                    dataNoticeOverlay
                        .padding(.horizontal, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                NotificationManager.shared.requestPermission()
                vm.loadCurrentStatus()
                vm.loadPrediction()
                vm.loadParkingLots()
                if !hideHomeDataNotice && !showDataNotice {
                    showDataNotice = true
                }
            }
        }
    }

    private var dataNoticeOverlay: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.30, green: 0.62, blue: 0.96).opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(red: 0.30, green: 0.62, blue: 0.96))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("서비스 안내")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("예측 기반 정보가 포함되어 있어요")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                noticeLine(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "예측 수치는 현재 예측 데이터 기준으로 제공됩니다."
                )
                noticeLine(
                    icon: "clock.badge.exclamationmark",
                    text: "일부 주차장 정보는 아직 준비 중이며 추후 반영될 예정입니다."
                )
            }

            Toggle(isOn: $hideDataNoticePermanently) {
                Text("다시 보지 않기")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .tint(Color(red: 0.30, green: 0.62, blue: 0.96))

            Button {
                if hideDataNoticePermanently {
                    hideHomeDataNotice = true
                }
                showDataNotice = false
            } label: {
                Text("확인")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.30, green: 0.62, blue: 0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 12)
    }

    private func noticeLine(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color(red: 0.30, green: 0.62, blue: 0.96))
                .frame(width: 18)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            Text("자리난지")
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
                Text(vm.parkingName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                statusTag(title: vm.congestionLevel, color: congestionTagBackground, textColor: congestionTagTextColor)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(vm.availableSpaces)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.08, green: 0.13, blue: 0.24))

                Text("/ \(vm.totalSpaces)대")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Text("현재 남은 자리")
                .font(.subheadline)
                .foregroundColor(.secondary)

            progressBar

            if !vm.currentStatusMessage.isEmpty {
                Text(vm.currentStatusMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
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
                    .frame(width: proxy.size.width * vm.occupancyProgress, height: 12)
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

                        Text("\(vm.oneHourLater)대")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.08, green: 0.13, blue: 0.24))
                    }

                    Spacer()

                    statusTag(title: predictedStatus, color: predictedStatusBackground, textColor: predictedStatusTextColor)
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

                        Text(vm.busyTime.isEmpty ? "데이터 준비 중" : vm.busyTime)
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
            NavigationLink {
                RecommendPage(parkingLots: vm.alternativeParkingLots)
            } label: {
                actionRow(icon: "location.fill", title: "대체 주차장 보기", subtitle: "")
            }
            .buttonStyle(.plain)

            NavigationLink {
                TimingPage(vm: vm)
            } label: {
                actionRow(icon: "clock.fill", title: "출발 타이밍 추천", subtitle: "언제 출발해야 할까요?")
            }
            .buttonStyle(.plain)

            NavigationLink {
                HourlyAnalysisView()
            } label: {
                actionRow(icon: "chart.bar.fill", title: "시간대별 분석", subtitle: "예측 그래프 보기")
            }
            .buttonStyle(.plain)
        }
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
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
        if vm.oneHourLater >= 100 {
            return "안정적"
        } else if vm.oneHourLater >= 30 {
            return "주의"
        } else {
            return "혼잡 예상"
        }
    }

    var recommendationText: String {
        if vm.oneHourLater >= 100 {
            return "바로 방문 추천"
        } else if vm.oneHourLater >= 30 {
            return "출발 전 확인"
        } else {
            return "대체 주차장 검토"
        }
    }

    var congestionTagBackground: Color {
        switch vm.congestionLevel {
        case "여유":
            return Color.green.opacity(0.18)
        case "보통":
            return Color.orange.opacity(0.18)
        case "혼잡", "매우 혼잡":
            return Color.red.opacity(0.16)
        default:
            return Color.gray.opacity(0.15)
        }
    }

    var congestionTagTextColor: Color {
        switch vm.congestionLevel {
        case "여유":
            return .green
        case "보통":
            return .orange
        case "혼잡", "매우 혼잡":
            return .red
        default:
            return .gray
        }
    }

    var predictedStatusBackground: Color {
        switch predictedStatus {
        case "안정적":
            return Color.green.opacity(0.18)
        case "주의":
            return Color.orange.opacity(0.18)
        default:
            return Color.red.opacity(0.16)
        }
    }

    var predictedStatusTextColor: Color {
        switch predictedStatus {
        case "안정적":
            return .green
        case "주의":
            return .orange
        default:
            return .red
        }
    }
}
