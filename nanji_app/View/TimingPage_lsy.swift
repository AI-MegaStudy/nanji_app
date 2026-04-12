import SwiftUI

struct TimingPage: View {
    @ObservedObject var vm: ParkingViewModel

    private var summaryCards: [TimingInsightCard] {
        [
            TimingInsightCard(
                title: "추천 출발 시간",
                timeText: vm.recommendedTime.isEmpty ? "데이터 준비 중" : vm.recommendedTime,
                message: "가장 여유로운 시간대로 안내합니다.",
                status: .best
            ),
            TimingInsightCard(
                title: "혼잡 예상 시간",
                timeText: vm.busyTime.isEmpty ? "데이터 준비 중" : vm.busyTime,
                message: "이 시간대는 혼잡할 가능성이 높아요.",
                status: .avoid
            ),
            TimingInsightCard(
                title: "여유 예상 시간",
                timeText: vm.freeTime.isEmpty ? "데이터 준비 중" : vm.freeTime,
                message: "비교적 편하게 주차할 수 있는 시간대예요.",
                status: .good
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("자리난지")
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

                        Text("언제 출발하면 더 편할지 안내해드려요.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 3)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color(hex: "#7DD3FC"))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("지금 추천")
                                .fontWeight(.semibold)

                            Text(vm.recommendedTime.isEmpty ? "추천 시간을 준비하고 있어요." : "\(vm.recommendedTime)에 맞춰 움직이면 더 수월해요.")
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

                    if !vm.departureTimingOptions.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(vm.departureTimingOptions) { option in
                                DepartureTimingCard(option: option)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(summaryCards) { card in
                                TimingCard(card: card)
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color(hex: "#7DD3FC"))

                        Text("현재는 난지 메인 주차장 기준으로 추천 시간을 안내하고 있어요.")
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
        .onAppear {
            vm.loadPrediction()
            vm.loadDepartureTimingOptions()
        }
    }
}

private struct TimingInsightCard: Identifiable {
    let id = UUID()
    let title: String
    let timeText: String
    let message: String
    let status: Status

    enum Status {
        case best
        case good
        case avoid
    }
}

private struct TimingCard: View {
    let card: TimingInsightCard

    var body: some View {
        let style = styleFor(card.status)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    Text(style.icon)
                        .frame(width: 40, height: 40)
                        .background(style.badge)
                        .foregroundColor(.white)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .fontWeight(.bold)
                        Text(card.message)
                            .font(.subheadline)
                            .foregroundColor(style.text)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(card.timeText)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("예상 시간")
                        .font(.caption)
                        .foregroundColor(.gray)
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

    private func styleFor(_ status: TimingInsightCard.Status) -> (
        bg: Color,
        border: Color,
        text: Color,
        badge: Color,
        icon: String
    ) {
        switch status {
        case .best:
            return (Color.green.opacity(0.12), Color.green.opacity(0.3), .green, .green, "✓")
        case .good:
            return (Color.blue.opacity(0.10), Color.blue.opacity(0.25), .blue, .blue, "○")
        case .avoid:
            return (Color.red.opacity(0.10), Color.red.opacity(0.25), .red, .red, "!")
        }
    }
}

private struct DepartureTimingCard: View {
    let option: DepartureTimingOption

    var body: some View {
        let style = styleFor(option.statusText)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    Text(style.icon)
                        .frame(width: 40, height: 40)
                        .background(style.badge)
                        .foregroundColor(.white)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .fontWeight(.bold)
                        Text(option.message)
                            .font(.subheadline)
                            .foregroundColor(style.text)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(option.availableSpaces)")
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
                        Text(option.departureTimeText)
                            .fontWeight(.semibold)
                    }

                    Text("→")
                        .foregroundColor(.gray)

                    VStack {
                        Text("도착")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(option.arrivalTimeText)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                VStack {
                    Text("상태")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(option.statusText)
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

    private func styleFor(_ status: String) -> (
        bg: Color,
        border: Color,
        text: Color,
        badge: Color,
        icon: String
    ) {
        switch status {
        case "여유":
            return (Color.green.opacity(0.12), Color.green.opacity(0.3), .green, .green, "✓")
        case "보통":
            return (Color.blue.opacity(0.10), Color.blue.opacity(0.25), .blue, .blue, "○")
        case "혼잡", "매우 혼잡":
            return (Color.red.opacity(0.10), Color.red.opacity(0.25), .red, .red, "!")
        default:
            return (Color.gray.opacity(0.10), Color.gray.opacity(0.25), .gray, .gray, "·")
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
    TimingPage(vm: ParkingViewModel())
}
