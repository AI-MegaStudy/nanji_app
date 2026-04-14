import SwiftUI
import Charts

struct HourlyAnalysisView: View {
    @State private var analysis: HourlyAnalysisResponse?
    @State private var selectedPointID: UUID?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let apiClient = HourlyAnalysisAPI()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                titleCard
                content
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("시간대별 분석")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if analysis == nil && !isLoading {
                APIService.shared.logUserAction(
                    "prediction_view",
                    parkingLotID: 1,
                    actionTarget: "hourly_analysis",
                    sourcePage: "hourly_analysis"
                )
                await loadHourlyAnalysis()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && analysis == nil {
            loadingCard
        } else if let analysis {
            chartCard(analysis: analysis)
            insightSection(analysis: analysis)
            statsSection(analysis: analysis)
        } else {
            errorCard
        }
    }

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("시간대별 혼잡도 분석")
                    .font(.headline)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color(red: 0.49, green: 0.83, blue: 0.99))
            }

            if let analysis {
                Text("\(analysis.parkingZone.uppercased()) · \(analysis.generatedAtText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private var loadingCard: some View {
            VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(.circular)

            Text("시간대별 정보를 불러오고 있어요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private var errorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("데이터를 불러오지 못했습니다")
                .font(.headline)

            Text(errorMessage ?? "잠시 후 다시 시도해 주세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("다시 시도") {
                Task {
                    await loadHourlyAnalysis()
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.49, green: 0.83, blue: 0.99))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private func chartCard(analysis: HourlyAnalysisResponse) -> some View {
        let selectedItem = selectedDataPoint(in: analysis.hourlyData)

        return VStack(spacing: 18) {
            Chart {
                ForEach(analysis.hourlyData) { item in
                    AreaMark(
                        x: .value("시간", item.time),
                        y: .value("혼잡도", item.occupancyValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(chartGradient)

                    LineMark(
                        x: .value("시간", item.time),
                        y: .value("혼잡도", item.occupancyValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color(red: 0.49, green: 0.83, blue: 0.99))
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("시간", item.time),
                        y: .value("혼잡도", item.occupancyValue)
                    )
                    .foregroundStyle(item.isPrediction ? Color.white : Color(red: 0.49, green: 0.83, blue: 0.99))
                    .symbolSize(selectedPointID == item.id ? 80 : 55)
                    .annotation(position: .overlay) {
                        Circle()
                            .stroke(Color(red: 0.49, green: 0.83, blue: 0.99), lineWidth: item.isPrediction ? 2 : 0)
                            .frame(width: item.isPrediction ? 10 : 0, height: item.isPrediction ? 10 : 0)
                    }
                }
            }
            .frame(height: 250)
            .chartYScale(domain: 0 ... 100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(Color(.systemGray5))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: analysis.hourlyData.map(\.time)) { value in
                    AxisValueLabel {
                        if let time = value.as(String.self) {
                            Text(time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if let selectedItem {
                tooltipCard(for: selectedItem)
            }

            timeSelector(data: analysis.hourlyData)
            legendView
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private func tooltipCard(for item: HourlyAnalysisPoint) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.time)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Text(item.isPrediction ? "예측" : "실시간")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(item.isPrediction ? Color(red: 0.30, green: 0.54, blue: 0.84) : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(item.isPrediction ? Color(red: 0.89, green: 0.95, blue: 1.0) : Color(.systemGray6))
                    .clipShape(Capsule())
            }

            HStack(spacing: 4) {
                Text("혼잡도:")
                    .foregroundColor(.secondary)
                Text("\(item.occupancyValue)%")
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.49, green: 0.83, blue: 0.99))
            }
            .font(.caption)

            HStack(spacing: 4) {
                Text("남은 자리:")
                    .foregroundColor(.secondary)
                Text("\(item.availableSpacesValue)대")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .font(.caption)

            HStack(spacing: 4) {
                Text("예상 차량:")
                    .foregroundColor(.secondary)
                Text("\(Int(round(item.predictedActiveCars)))대")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func timeSelector(data: [HourlyAnalysisPoint]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(data) { item in
                    Button {
                        selectedPointID = item.id
                    } label: {
                        VStack(spacing: 4) {
                            Text(item.time)
                                .font(.caption.weight(.semibold))
                            Text("\(item.occupancyValue)%")
                                .font(.caption2)
                        }
                        .foregroundColor(selectedPointID == item.id ? .white : .primary)
                        .frame(width: 62)
                        .padding(.vertical, 10)
                        .background(
                            selectedPointID == item.id
                            ? Color(red: 0.49, green: 0.83, blue: 0.99)
                            : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var legendView: some View {
        HStack(spacing: 22) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(red: 0.49, green: 0.83, blue: 0.99))
                    .frame(width: 12, height: 12)
                Text("실시간")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.white)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.49, green: 0.83, blue: 0.99), lineWidth: 2)
                    )
                    .frame(width: 12, height: 12)
                Text("예측")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func insightSection(analysis: HourlyAnalysisResponse) -> some View {
        VStack(spacing: 12) {
            insightCard(
                title: "피크 타임",
                message: "\(analysis.peakTime)에 가장 혼잡할 것으로 예상됩니다. 해당 시간대는 피하는 것을 권장합니다.",
                accent: Color(red: 0.80, green: 0.39, blue: 0.33),
                background: Color(red: 0.80, green: 0.39, blue: 0.33).opacity(0.10)
            )

            insightCard(
                title: "추천 시간",
                message: "\(analysis.recommendedTimeWindow)에 비교적 여유가 있을 것으로 보입니다.",
                accent: Color(red: 0.44, green: 0.66, blue: 0.35),
                background: Color(red: 0.44, green: 0.66, blue: 0.35).opacity(0.10)
            )
        }
    }

    private func insightCard(title: String, message: String, accent: Color, background: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundColor(accent)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statsSection(analysis: HourlyAnalysisResponse) -> some View {
        HStack(spacing: 12) {
            statCard(
                title: "예측 혼잡도",
                value: congestionText(for: analysis),
                valueColor: .primary
            )
            statCard(
                title: "예상 여유 자리",
                value: availableSpacesText(for: analysis),
                valueColor: Color(red: 0.49, green: 0.83, blue: 0.99)
            )
        }
    }

    private func statCard(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private func loadHourlyAnalysis() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await apiClient.fetchHourlyAnalysis(request: HourlyAnalysisRequest.live)
            analysis = fetched
            selectedPointID = fetched.hourlyData.first(where: { $0.isPrediction })?.id ?? fetched.hourlyData.first?.id
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func congestionText(for analysis: HourlyAnalysisResponse) -> String {
        if let percent = analysis.predictedCongestionPercent {
            return "\(format(percent))%"
        }
        return "정보 없음"
    }

    private func availableSpacesText(for analysis: HourlyAnalysisResponse) -> String {
        if let spaces = analysis.predictedAvailableSpaces {
            return "\(spaces)대"
        }
        return "정보 없음"
    }

    private func format(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.\(digits)f", value)
    }

    private func selectedDataPoint(in data: [HourlyAnalysisPoint]) -> HourlyAnalysisPoint? {
        if let selectedPointID {
            return data.first(where: { $0.id == selectedPointID })
        }
        return data.first(where: { $0.isPrediction }) ?? data.first
    }

    private var chartGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.49, green: 0.83, blue: 0.99).opacity(0.30),
                Color(red: 0.49, green: 0.83, blue: 0.99).opacity(0.02)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    NavigationStack {
        HourlyAnalysisView()
    }
}
