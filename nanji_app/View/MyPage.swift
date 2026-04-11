import SwiftUI

struct MyPage: View {
    @State private var notifications = NotificationSetting.sampleData
    private let chartData = ParkingTrendPoint.sampleData

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                analysisSection
                notificationSection
                settingsSection
                versionSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("마이페이지")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var analysisSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("시간대별 혼잡도 분석")
                        .font(.title3)
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(themeColor)
                }

                Text("AI 기반 예측 데이터")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(cardBackground)

            VStack(spacing: 18) {
                occupancyChart
                chartLegend
            }
            .padding(20)
            .background(cardBackground)

            VStack(spacing: 12) {
                insightCard(
                    title: "피크 타임",
                    message: "17:00 - 19:00에 가장 혼잡합니다. 이 시간대는 피하는 것을 권장합니다.",
                    accentColor: Color(red: 0.80, green: 0.39, blue: 0.33)
                )

                insightCard(
                    title: "추천 시간",
                    message: "오전 6시 - 10시 또는 밤 10시 이후가 여유롭습니다.",
                    accentColor: Color(red: 0.44, green: 0.66, blue: 0.35)
                )
            }

            HStack(spacing: 12) {
                summaryCard(title: "평균 혼잡도", value: "68%", color: .primary)
                summaryCard(title: "예측 정확도", value: "94%", color: themeColor)
            }
        }
    }

    private var occupancyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            GeometryReader { geometry in
                ZStack {
                    chartGrid(size: geometry.size)
                    chartArea(size: geometry.size)
                    chartLine(size: geometry.size)
                    chartPoints(size: geometry.size)
                    chartXAxis(size: geometry.size)
                    chartYAxis(size: geometry.size)
                }
            }
            .frame(height: 250)
        }
    }

    private var chartLegend: some View {
        HStack(spacing: 20) {
            legendItem(title: "실시간", color: themeColor, bordered: false)
            legendItem(title: "예측", color: themeColor.opacity(0.60), bordered: true)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("알림 설정")
                    .font(.title3)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "bell.fill")
                    .foregroundStyle(themeColor)
            }

            VStack(spacing: 12) {
                ForEach($notifications) { $notification in
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(notification.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $notification.enabled)
                            .labelsHidden()
                            .tint(themeColor)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("기타 설정")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 4) {
                settingsRow(title: "앱 정보")
                settingsRow(title: "이용 약관")
                settingsRow(title: "개인정보 처리방침")
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var versionSection: some View {
        Text("버전 1.0.0")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
    }

    private func insightCard(title: String, message: String, accentColor: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(accentColor.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
    }

    private func settingsRow(title: String) -> some View {
        Button {
        } label: {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func legendItem(title: String, color: Color, bordered: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .overlay {
                    if bordered {
                        Circle()
                            .stroke(themeColor, lineWidth: 2)
                    }
                }
                .frame(width: 10, height: 10)

            Text(title)
        }
    }

    private func chartGrid(size: CGSize) -> some View {
        ZStack {
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                Path { path in
                    let y = (1 - fraction) * (size.height - 24)
                    path.move(to: CGPoint(x: 28, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
    }

    private func chartArea(size: CGSize) -> some View {
        let points = chartPoints(in: size)

        return Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.x, y: size.height - 24))
            for point in points {
                path.addLine(to: point)
            }
            if let last = points.last {
                path.addLine(to: CGPoint(x: last.x, y: size.height - 24))
            }
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [themeColor.opacity(0.30), themeColor.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func chartLine(size: CGSize) -> some View {
        let points = chartPoints(in: size)

        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(themeColor, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
    }

    private func chartPoints(size: CGSize) -> some View {
        let points = chartPoints(in: size)

        return ZStack {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(themeColor, lineWidth: 3)
                    )
                    .position(point)
            }
        }
    }

    private func chartXAxis(size: CGSize) -> some View {
        let points = chartPoints(in: size)

        return ZStack {
            ForEach(Array(chartData.enumerated()), id: \.offset) { index, item in
                Text(item.time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: points[index].x, y: size.height - 10)
            }
        }
    }

    private func chartYAxis(size: CGSize) -> some View {
        let labels = [100, 75, 50, 25, 0]

        return ZStack {
            ForEach(labels, id: \.self) { label in
                let fraction = CGFloat(label) / 100
                let y = (1 - fraction) * (size.height - 24)
                Text("\(label)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: 12, y: y)
            }
        }
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        let chartHeight = size.height - 24
        let chartWidth = size.width - 32
        let stepX = chartData.count > 1 ? chartWidth / CGFloat(chartData.count - 1) : 0

        return chartData.enumerated().map { index, point in
            let x = 28 + stepX * CGFloat(index)
            let normalized = CGFloat(point.occupancy) / 100
            let y = chartHeight - normalized * chartHeight
            return CGPoint(x: x, y: y)
        }
    }

    private var themeColor: Color {
        Color(red: 0.49, green: 0.83, blue: 0.99)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
    }
}

private struct NotificationSetting: Identifiable {
    let id: String
    let title: String
    let description: String
    var enabled: Bool

    static let sampleData: [NotificationSetting] = [
        NotificationSetting(
            id: "1",
            title: "혼잡도 알림",
            description: "혼잡율 90% 이상일 때 알림을 보내드립니다",
            enabled: true
        ),
        NotificationSetting(
            id: "2",
            title: "출발 시간 알림",
            description: "최적 출발 시간 30분 전에 알려드려요",
            enabled: true
        ),
        NotificationSetting(
            id: "3",
            title: "대체 주차장 추천",
            description: "만차 예상 시 대체 주차장을 추천해드려요",
            enabled: false
        )
    ]
}

private struct ParkingTrendPoint: Identifiable {
    let id = UUID()
    let time: String
    let occupancy: Int
    let available: Int

    static let sampleData: [ParkingTrendPoint] = [
        ParkingTrendPoint(time: "06:00", occupancy: 20, available: 200),
        ParkingTrendPoint(time: "08:00", occupancy: 45, available: 137),
        ParkingTrendPoint(time: "10:00", occupancy: 65, available: 87),
        ParkingTrendPoint(time: "12:00", occupancy: 85, available: 37),
        ParkingTrendPoint(time: "14:00", occupancy: 75, available: 62),
        ParkingTrendPoint(time: "16:00", occupancy: 88, available: 30),
        ParkingTrendPoint(time: "18:00", occupancy: 92, available: 20),
        ParkingTrendPoint(time: "20:00", occupancy: 78, available: 55),
        ParkingTrendPoint(time: "22:00", occupancy: 45, available: 137)
    ]
}

#Preview {
    NavigationStack {
        MyPage()
    }
}
