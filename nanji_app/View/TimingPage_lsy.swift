import SwiftUI

struct TimingOption: Identifiable {
    let id = UUID()
    let time: String
    let departure: String
    let arrival: String
    let available: Int
    let status: Status
    let message: String
    let traffic: String

    enum Status {
        case best
        case good
        case caution
        case avoid
    }
}

struct TimingPage: View {
    private let timingOptions: [TimingOption] = [
        TimingOption(time: "지금 출발", departure: "14:00", arrival: "14:15", available: 42, status: .good, message: "주차 가능해요", traffic: "원활"),
        TimingOption(time: "30분 후 출발", departure: "14:30", arrival: "14:45", available: 35, status: .caution, message: "조금 붐빌 수 있어요", traffic: "보통"),
        TimingOption(time: "1시간 후 출발", departure: "15:00", arrival: "15:15", available: 28, status: .caution, message: "자리가 많지 않아요", traffic: "보통"),
        TimingOption(time: "2시간 후 출발", departure: "16:00", arrival: "16:15", available: 15, status: .avoid, message: "주차 어려워요", traffic: "혼잡"),
        TimingOption(time: "3시간 후 출발", departure: "17:00", arrival: "17:15", available: 8, status: .avoid, message: "피크타임 - 피하세요", traffic: "매우 혼잡")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("한강공원 주차장")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 18)
            .background(
                Color(hex: "#7DD3FC")
                    .ignoresSafeArea(edges: .top)
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Color(hex: "#7DD3FC"))

                            Text("출발 타이밍 추천")
                                .font(.headline)
                        }

                        Text("언제 출발하면 주차하기 좋을까요?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 3)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(Color(hex: "#7DD3FC"))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("추천 시간")
                                .fontWeight(.semibold)

                            Text("지금 출발하시면 주차하기 좋아요!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(hex: "#7DD3FC").opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#7DD3FC").opacity(0.3))
                    )
                    .cornerRadius(12)

                    VStack(spacing: 12) {
                        ForEach(timingOptions) { option in
                            TimingCard(option: option)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(Color(hex: "#7DD3FC"))

                        Text("실시간 교통 상황과 과거 데이터를 분석하여 최적의 출발 시간을 추천해드립니다.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2))
                    )
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct TimingCard: View {
    let option: TimingOption

    var body: some View {
        let style = getStyle(option.status)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    Text(style.icon)
                        .frame(width: 40, height: 40)
                        .background(style.badge)
                        .foregroundColor(.white)
                        .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(option.time)
                            .fontWeight(.bold)

                        Text(option.message)
                            .font(.subheadline)
                            .foregroundColor(style.text)
                    }
                }

                Spacer()

                VStack {
                    Text("\(option.available)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("예상 자리")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            HStack {
                HStack(spacing: 12) {
                    VStack {
                        Text("출발")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(option.departure)
                            .fontWeight(.semibold)
                    }

                    Text("→")
                        .foregroundColor(.gray)

                    VStack {
                        Text("도착")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(option.arrival)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                VStack {
                    Text("교통")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(option.traffic)
                        .font(.caption)
                        .foregroundColor(style.text)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.bg)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style.border, lineWidth: 2)
        )
        .cornerRadius(12)
    }

    func getStyle(_ status: TimingOption.Status) -> (
        bg: Color,
        border: Color,
        text: Color,
        badge: Color,
        icon: String
    ) {
        switch status {
        case .best:
            return (.green, .green, .white, .green, "✓")
        case .good:
            return (Color.green.opacity(0.1), Color.green.opacity(0.3), .green, .green, "✓")
        case .caution:
            return (Color.yellow.opacity(0.2), Color.yellow.opacity(0.5), .orange, .orange, "!")
        case .avoid:
            return (Color.red.opacity(0.1), Color.red.opacity(0.3), .red, .red, "✕")
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = (int >> 16) & 0xFF
        let g = (int >> 8) & 0xFF
        let b = int & 0xFF

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

#Preview {
    TimingPage()
}
