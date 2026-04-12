import SwiftUI
import MapKit

struct RecommendPage: View {
    private let parkingLots: [ParkingLotItem] = [
        ParkingLotItem(
            id: "1",
            name: "난지 캠핑장 주차장",
            distance: 0.8,
            available: 89,
            total: 150,
            estimatedTime: 2,
            coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.8760)
        ),
        ParkingLotItem(
            id: "2",
            name: "하늘공원 주차장",
            distance: 1.2,
            available: 45,
            total: 120,
            estimatedTime: 3,
            coordinate: CLLocationCoordinate2D(latitude: 37.5684, longitude: 126.8787)
        ),
        ParkingLotItem(
            id: "3",
            name: "월드컵공원 주차장",
            distance: 1.5,
            available: 12,
            total: 180,
            estimatedTime: 4,
            coordinate: CLLocationCoordinate2D(latitude: 37.5702, longitude: 126.8815)
        )
    ]

    @State private var selectedLotID: String = "1"
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.8760),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    private var selectedLot: ParkingLotItem? {
        parkingLots.first { $0.id == selectedLotID }
    }

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
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "mappin")
                                .foregroundColor(Color(hex: "#7DD3FC"))

                            Text("대체 주차장")
                                .font(.headline)
                        }

                        VStack(spacing: 12) {
                            ForEach(parkingLots) { lot in
                                ParkingCard(
                                    lot: lot,
                                    isSelected: lot.id == selectedLotID,
                                    onTap: {
                                        focus(on: lot)
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 4)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("지도")
                                .font(.headline)

                            Spacer()

                            if let selectedLot {
                                Text(selectedLot.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Map(position: $cameraPosition) {
                            ForEach(parkingLots) { lot in
                                Marker(lot.name, coordinate: lot.coordinate)
                                    .tint(lot.id == selectedLotID ? .red : .blue)
                            }
                        }
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 4)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            if let selectedLot {
                focus(on: selectedLot, animated: false)
            }
        }
    }

    private func focus(on lot: ParkingLotItem, animated: Bool = true) {
        selectedLotID = lot.id

        let nextPosition = MapCameraPosition.region(
            MKCoordinateRegion(
                center: lot.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
            )
        )

        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                cameraPosition = nextPosition
            }
        } else {
            cameraPosition = nextPosition
        }
    }
}

private struct ParkingLotItem: Identifiable {
    let id: String
    let name: String
    let distance: Double
    let available: Int
    let total: Int
    let estimatedTime: Int
    let coordinate: CLLocationCoordinate2D

    var status: ParkingLotStatus {
        let ratio = Double(available) / Double(total)
        if ratio > 0.5 { return .available }
        if ratio > 0.2 { return .moderate }
        return .busy
    }
}

private enum ParkingLotStatus {
    case available
    case moderate
    case busy

    var label: String {
        switch self {
        case .available:
            return "여유"
        case .moderate:
            return "보통"
        case .busy:
            return "혼잡"
        }
    }

    var color: Color {
        switch self {
        case .available:
            return Color(hex: "#6FA858")
        case .moderate:
            return Color(hex: "#E8D878")
        case .busy:
            return Color(hex: "#CD6355")
        }
    }

    var background: Color {
        color.opacity(0.1)
    }

    var border: Color {
        color.opacity(0.3)
    }
}

private struct ParkingCard: View {
    let lot: ParkingLotItem
    let isSelected: Bool
    let onTap: () -> Void

    private var occupancyRate: Double {
        Double(lot.available) / Double(lot.total)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lot.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            Label("\(lot.distance, specifier: "%.1f")km", systemImage: "location")
                            Label("약 \(lot.estimatedTime)분", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        .labelStyle(ParkingInfoLabelStyle())
                    }

                    Spacer()

                    Text(lot.status.label)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(lot.status.background)
                        .foregroundColor(lot.status.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(lot.status.border, lineWidth: 1)
                        )
                        .cornerRadius(20)
                }

                HStack {
                    Text("남은 자리")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Spacer()

                    Text("\(lot.available) / \(lot.total)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                ProgressView(value: occupancyRate)
                    .tint(lot.status.color)
            }
            .padding()
            .background(isSelected ? Color(hex: "#EEF8FD") : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color(hex: "#7DD3FC") : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct ParkingInfoLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .foregroundColor(Color(hex: "#7DD3FC"))
            configuration.title
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
    RecommendPage()
}
