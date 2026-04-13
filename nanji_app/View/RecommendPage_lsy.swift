import SwiftUI
import MapKit
import CoreLocation
import Combine
import UserNotifications

struct RecommendPage: View {
    let parkingLots: [ParkingLotAPIItem]
    private let previewOrigin = CLLocation(latitude: 37.5499, longitude: 126.9136)

    @StateObject private var locationManager = LocationManager()
    @State private var selectedLotID: Int?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5686, longitude: 126.8789),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @State private var routeInfoByLotID: [Int: AlternativeRouteInfo] = [:]
    @State private var statusByLotID: [Int: ParkingStatus] = [:]
    
    @State private var notifyWhenSelectedBecomesAvailable: Bool = true
    @State private var notifyWhenNearSelectedLot: Bool = true
    @State private var lowAvailabilityThreshold: Double = 0.1 // 10%
    @State private var lastNotifiedNearLotID: Int?
    @State private var lastETAByLotID: [Int: Int] = [:]
    @State private var lastHasDataByLotID: [Int: Bool] = [:]

    private var displayLots: [AlternativeParkingLotItem] {
        let mapped = parkingLots.enumerated().map { index, lot in
            AlternativeParkingLotItem.make(
                from: lot,
                index: index,
                routeInfo: routeInfoByLotID[lot.pID],
                status: statusByLotID[lot.pID]
            )
        }

        if !mapped.isEmpty {
            return mapped
        }

        return [
            AlternativeParkingLotItem(
                id: 2,
                name: "난지 캠핑장 주차장",
                address: "서울특별시 마포구 상암동 난지한강공원 일대",
                distance: 0.8,
                available: 89,
                total: 150,
                estimatedTime: 2,
                coordinate: CLLocationCoordinate2D(latitude: 37.5700, longitude: 126.8795),
                hasCurrentData: false,
                currentMessage: nil,
                statusLabel: nil
            ),
            AlternativeParkingLotItem(
                id: 3,
                name: "하늘공원 주차장",
                address: "서울특별시 마포구 하늘공원로 일대",
                distance: 1.2,
                available: 45,
                total: 120,
                estimatedTime: 3,
                coordinate: CLLocationCoordinate2D(latitude: 37.5697, longitude: 126.8780),
                hasCurrentData: false,
                currentMessage: nil,
                statusLabel: nil
            ),
            AlternativeParkingLotItem(
                id: 4,
                name: "월드컵공원 주차장",
                address: "서울특별시 마포구 월드컵로 일대",
                distance: 1.5,
                available: 12,
                total: 180,
                estimatedTime: 4,
                coordinate: CLLocationCoordinate2D(latitude: 37.5710, longitude: 126.8810),
                hasCurrentData: false,
                currentMessage: nil,
                statusLabel: nil
            )
        ]
    }

    private var selectedLot: AlternativeParkingLotItem? {
        let id = selectedLotID ?? displayLots.first?.id
        guard let id else { return nil }
        return displayLots.first { $0.id == id }
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
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("혼잡 → 여유 알림", isOn: $notifyWhenSelectedBecomesAvailable)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#7DD3FC")))
                Toggle("주차장 근접 알림", isOn: $notifyWhenNearSelectedLot)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#7DD3FC")))
                HStack {
                    Text("여유 임계치")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $lowAvailabilityThreshold, in: 0.05...0.5, step: 0.05)
                    Text("\(Int(lowAvailabilityThreshold * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                Button {
                    let name = selectedLot?.name ?? "주차장"
                    NotificationManager.shared.scheduleNotification(
                        id: "test_notification",
                        title: "알림 테스트",
                        body: "\(name) 알림이 정상 동작합니다."
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge")
                        Text("알림 테스트 보내기")
                    }
                    .font(.footnote)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

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
                            ForEach(displayLots) { lot in
                                ParkingCard(
                                    lot: lot,
                                    isSelected: lot.id == (selectedLotID ?? displayLots.first?.id),
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
                            ForEach(displayLots) { lot in
                                Marker(lot.name, coordinate: lot.coordinate)
                                    .tint(lot.id == (selectedLotID ?? displayLots.first?.id) ? .red : .blue)
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
            NotificationManager.shared.requestAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            loadAlternativeStatuses()
            updateRouteInfo(from: normalizedOriginLocation(locationManager.currentLocation))
            if let selectedLot {
                focus(on: selectedLot, animated: false)
            }
        }
        .onReceive(locationManager.$currentLocation.compactMap { $0 }) { location in
            updateRouteInfo(from: normalizedOriginLocation(location))
        }
        .onChange(of: statusByLotID) { oldValue, newValue in
            guard notifyWhenSelectedBecomesAvailable, let selectedID = selectedLotID ?? displayLots.first?.id else { return }
            let oldStatus = oldValue[selectedID]
            let newStatus = newValue[selectedID]
            // Only notify when transitioning to available ("여유") from non-available and when we have current data
            if let newStatus, newStatus.hasData, newStatus.congestionLevel == "여유" {
                let wasAvailable = (oldStatus?.congestionLevel == "여유")
                if !wasAvailable {
                    let lotName = displayLots.first(where: { $0.id == selectedID })?.name ?? "주차장"
                    NotificationManager.shared.scheduleNotification(
                        id: "lot_available_\(selectedID)",
                        title: "주차 가능해요",
                        body: "\(lotName)이(가) 지금 여유 상태입니다."
                    )
                }
            }
            // Low availability threshold alert
            if let selected = selectedLot, let status = newStatus, status.hasData {
                let total = max(status.totalSpaces, 1)
                let ratio = Double(status.availableSpaces) / Double(total)
                let threshold = lowAvailabilityThreshold
                let wasLow = {
                    if let old = oldStatus, old.hasData {
                        let ot = max(old.totalSpaces, 1)
                        return Double(old.availableSpaces) / Double(ot) <= threshold
                    }
                    return false
                }()
                if ratio <= threshold, !wasLow {
                    NotificationManager.shared.scheduleNotification(
                        id: "lot_low_\(selected.id)",
                        title: "자리 빠르게 줄고 있어요",
                        body: "\(selected.name) 남은 자리가 임계치(\(Int(threshold*100))%) 이하입니다."
                    )
                }
            }

            // Data availability lost/restored
            if let selectedID = selectedLotID ?? displayLots.first?.id {
                let oldHas = oldStatus?.hasData ?? false
                let newHas = newStatus?.hasData ?? false
                if oldHas != newHas {
                    if newHas {
                        NotificationManager.shared.scheduleNotification(
                            id: "lot_data_restored_\(selectedID)",
                            title: "실시간 정보 복구",
                            body: "선택한 주차장의 실시간 정보가 다시 제공됩니다."
                        )
                    } else {
                        NotificationManager.shared.scheduleNotification(
                            id: "lot_data_lost_\(selectedID)",
                            title: "실시간 정보 없음",
                            body: "선택한 주차장의 실시간 정보가 일시 중단되었습니다."
                        )
                    }
                }
            }
        }
        .onChange(of: routeInfoByLotID) { oldValue, newValue in
            guard let selectedID = selectedLotID ?? displayLots.first?.id,
                  let newETA = newValue[selectedID]?.travelMinutes else { return }
            let oldETA = oldValue[selectedID]?.travelMinutes ?? lastETAByLotID[selectedID]
            lastETAByLotID[selectedID] = newETA
            if let oldETA, newETA - oldETA >= 5 {
                let name = displayLots.first(where: { $0.id == selectedID })?.name ?? "주차장"
                NotificationManager.shared.scheduleNotification(
                    id: "lot_eta_spike_\(selectedID)",
                    title: "예상 소요시간 증가",
                    body: "\(name)까지 예상 시간이 \(newETA - oldETA)분 늘어났어요."
                )
            }
        }
        .onReceive(locationManager.$currentLocation.compactMap { $0 }) { location in
            guard notifyWhenNearSelectedLot, let selected = selectedLot else { return }
            let userCoord = location.coordinate
            let current = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
            let destCoord = selected.coordinate
            let dest = CLLocation(latitude: destCoord.latitude, longitude: destCoord.longitude)
            let distance = current.distance(from: dest)
            if distance <= 1000 {
                if lastNotifiedNearLotID != selected.id {
                    lastNotifiedNearLotID = selected.id
                    let meters = Int(distance)
                    NotificationManager.shared.scheduleProximityNotification(
                        id: "lot_near_\(selected.id)",
                        title: "주차장 근처에 도착",
                        body: "\(selected.name)까지 약 \(meters)m 남았어요."
                    )
                }
            } else if lastNotifiedNearLotID == selected.id {
                // moved away; allow future notification again when re-entering
                lastNotifiedNearLotID = nil
            }
        }
        .navigationBarBackButtonHidden(false)
    }

    private func focus(on lot: AlternativeParkingLotItem, animated: Bool = true) {
        selectedLotID = lot.id
        
        NotificationManager.shared.cancelNotification(id: "lot_near_\(lot.id)")

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

    private func updateRouteInfo(from location: CLLocation) {
        for lot in parkingLots {
            let destinationLocation = CLLocation(latitude: lot.pLatitude, longitude: lot.pLongitude)
            let directDistanceKilometers = location.distance(from: destinationLocation) / 1000
            let fallbackMinutes = fallbackTravelMinutes(for: directDistanceKilometers)
            let destinationCoordinate = CLLocationCoordinate2D(latitude: lot.pLatitude, longitude: lot.pLongitude)
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculateETA { response, _ in
                let route: AlternativeRouteInfo

                if let response {
                    route = AlternativeRouteInfo(
                        distanceKilometers: response.distance / 1000,
                        travelMinutes: max(Int(round(response.expectedTravelTime / 60)), 1)
                    )
                } else {
                    route = AlternativeRouteInfo(
                        distanceKilometers: directDistanceKilometers,
                        travelMinutes: fallbackMinutes
                    )
                }

                Task { @MainActor in
                    routeInfoByLotID[lot.pID] = route
                }
            }
        }
    }

    private func normalizedOriginLocation(_ location: CLLocation?) -> CLLocation {
        guard let location else { return previewOrigin }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        if latitude == 0, longitude == 0 {
            return previewOrigin
        }

        if location.horizontalAccuracy < 0 {
            return previewOrigin
        }

        if location.distance(from: previewOrigin) > 30_000 {
            return previewOrigin
        }

        return location
    }

    private func fallbackTravelMinutes(for distanceKilometers: Double) -> Int {
        max(Int(round((distanceKilometers / 30.0) * 60.0)), 1)
    }

    private func loadAlternativeStatuses() {
        for lot in parkingLots {
            APIService.shared.fetchCurrentStatus(parkingLotID: lot.pID) { result in
                switch result {
                case .success(let status):
                    Task { @MainActor in
                        statusByLotID[lot.pID] = status
                    }
                case .failure:
                    break
                }
            }
        }
    }
}

private struct AlternativeParkingLotItem: Identifiable {
    let id: Int
    let name: String
    let address: String?
    let distance: Double
    let available: Int
    let total: Int
    let estimatedTime: Int
    let coordinate: CLLocationCoordinate2D
    let hasCurrentData: Bool
    let currentMessage: String?
    let statusLabel: String?

    static func make(
        from lot: ParkingLotAPIItem,
        index: Int,
        routeInfo: AlternativeRouteInfo?,
        status: ParkingStatus?
    ) -> AlternativeParkingLotItem {
        let presetAvailable = [89, 45, 12][min(index, 2)]
        let fallbackTotal = max(lot.pTotalSpaces, [150, 120, 180][min(index, 2)])
        let available = status?.hasData == true ? (status?.availableSpaces ?? 0) : presetAvailable
        let total = status?.hasData == true ? max(status?.totalSpaces ?? 0, lot.pTotalSpaces) : fallbackTotal

        return AlternativeParkingLotItem(
            id: lot.pID,
            name: lot.pDisplayName,
            address: lot.pAddress,
            distance: routeInfo?.distanceKilometers ?? 0,
            available: available,
            total: total,
            estimatedTime: routeInfo?.travelMinutes ?? 0,
            coordinate: CLLocationCoordinate2D(latitude: lot.pLatitude, longitude: lot.pLongitude),
            hasCurrentData: status?.hasData ?? false,
            currentMessage: status?.message,
            statusLabel: status?.congestionLevel
        )
    }

    var status: ParkingLotStatus {
        guard hasCurrentData else { return .pending }

        if let statusLabel {
            return ParkingLotStatus(label: statusLabel)
        }

        let ratio = Double(available) / Double(total)
        if ratio > 0.5 { return .available }
        if ratio > 0.2 { return .moderate }
        return .busy
    }
}

private struct AlternativeRouteInfo {
    let distanceKilometers: Double
    let travelMinutes: Int
}

private enum ParkingLotStatus {
    case available
    case moderate
    case busy
    case pending

    init(label: String) {
        switch label {
        case "여유":
            self = .available
        case "보통":
            self = .moderate
        case "혼잡", "매우 혼잡":
            self = .busy
        case "정보 준비 중":
            self = .pending
        default:
            self = .moderate
        }
    }

    var label: String {
        switch self {
        case .available:
            return "여유"
        case .moderate:
            return "보통"
        case .busy:
            return "혼잡"
        case .pending:
            return "정보 준비 중"
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
        case .pending:
            return Color.gray
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
    let lot: AlternativeParkingLotItem
    let isSelected: Bool
    let onTap: () -> Void

    private var occupancyRate: Double {
        Double(lot.available) / Double(lot.total)
    }

    private func formattedTravelTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "약 \(hours)시간"
            }
            return "약 \(hours)시간 \(remainingMinutes)분"
        }

        return "약 \(minutes)분"
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
                            Label(
                                lot.distance > 0 ? "\(lot.distance, specifier: "%.1f")km" : "거리 계산 중",
                                systemImage: "location"
                            )
                            Label(
                                lot.estimatedTime > 0 ? formattedTravelTime(lot.estimatedTime) : "시간 계산 중",
                                systemImage: "clock"
                            )
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

                    if lot.hasCurrentData {
                        Text("\(lot.available) / \(lot.total)")
                            .font(.headline)
                            .foregroundColor(.primary)
                    } else {
                        Text("정보 준비 중")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if lot.hasCurrentData {
                    ProgressView(value: occupancyRate)
                        .tint(lot.status.color)
                }
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
    RecommendPage(
        parkingLots: [
            ParkingLotAPIItem(
                pID: 2,
                pName: "난지캠핑장",
                pDisplayName: "난지 캠핑장 주차장",
                pAddress: "서울특별시 마포구 상암동 난지한강공원 일대",
                pLatitude: 37.5700,
                pLongitude: 126.8795,
                pTotalSpaces: 300,
                pSupportsPrediction: false
            ),
            ParkingLotAPIItem(
                pID: 3,
                pName: "하늘공원",
                pDisplayName: "하늘공원 주차장",
                pAddress: "서울특별시 마포구 하늘공원로 일대",
                pLatitude: 37.5697,
                pLongitude: 126.8780,
                pTotalSpaces: 250,
                pSupportsPrediction: false
            ),
            ParkingLotAPIItem(
                pID: 4,
                pName: "월드컵공원",
                pDisplayName: "월드컵공원 주차장",
                pAddress: "서울특별시 마포구 월드컵로 일대",
                pLatitude: 37.5710,
                pLongitude: 126.8810,
                pTotalSpaces: 250,
                pSupportsPrediction: false
            )
        ]
    )
}
