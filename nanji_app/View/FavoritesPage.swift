import SwiftUI
import MapKit
import CoreLocation
import Combine

struct FavoritesPage: View {
    @StateObject private var locationManager = LocationManager()
    private let previewOrigin = CLLocation(latitude: 37.5499, longitude: 126.9136)

    @State private var parkingLots: [ParkingLotAPIItem] = []
    @State private var statusByLotID: [Int: ParkingStatus] = [:]
    @State private var routeInfoByLotID: [Int: FavoriteRouteInfo] = [:]

    @State private var favoriteIDs: [Int] = []
    @State private var notificationIDs: Set<Int> = []
    @State private var showAddFavoritesSheet = false
    @State private var addingFavoriteIDs: Set<Int> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                infoBanner

                if favoriteLots.isEmpty {
                    emptyStateCard
                } else {
                    favoritesList
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("즐겨찾기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !parkingLots.isEmpty {
                    Button {
                        showAddFavoritesSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFavoritesSheet) {
            addFavoritesSheet
        }
        .onAppear {
            loadParkingLots()
            loadFavoriteIDs()
            loadNotificationIDs()
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            updateRouteInfo(from: normalizedOriginLocation(locationManager.currentLocation))
        }
        .onReceive(locationManager.$currentLocation.compactMap { $0 }) { location in
            updateRouteInfo(from: normalizedOriginLocation(location))
        }
        .onChange(of: favoriteIDs) { _ in
            updateRouteInfo(from: normalizedOriginLocation(locationManager.currentLocation))
        }
        .onChange(of: parkingLots.map(\.pID)) { _ in
            updateRouteInfo(from: normalizedOriginLocation(locationManager.currentLocation))
        }
    }

    private var favoriteLots: [ParkingLotAPIItem] {
        parkingLots.filter { favoriteIDs.contains($0.pID) }
    }

    private var availableLotsToAdd: [ParkingLotAPIItem] {
        parkingLots.filter { !favoriteIDs.contains($0.pID) }
    }

    private var infoBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 0.49, green: 0.83, blue: 0.99))

            Text("즐겨찾기한 주차장의 현재 상태와 이동 정보를 빠르게 확인할 수 있어요")
                .font(.subheadline)
                .foregroundStyle(Color(.darkGray))

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.49, green: 0.83, blue: 0.99).opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(red: 0.49, green: 0.83, blue: 0.99).opacity(0.22), lineWidth: 1)
        )
    }

    private var favoritesList: some View {
        VStack(spacing: 12) {
            ForEach(favoriteLots, id: \.pID) { lot in
                favoriteCard(for: lot)
            }
        }
    }

    private func favoriteCard(for lot: ParkingLotAPIItem) -> some View {
        let status = statusByLotID[lot.pID]
        let route = routeInfoByLotID[lot.pID]
        let badge = favoriteStatus(for: status)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.49, green: 0.83, blue: 0.99))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(lot.pDisplayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(lot.pAddress ?? lot.pName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        toggleNotification(for: lot.pID)
                    } label: {
                        Image(systemName: notificationIDs.contains(lot.pID) ? "bell.fill" : "bell.slash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(notificationIDs.contains(lot.pID) ? Color(red: 0.49, green: 0.83, blue: 0.99) : .gray)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(notificationIDs.contains(lot.pID) ? "알림 끄기" : "알림 켜기")

                    Button(role: .destructive) {
                        deleteFavorite(withID: lot.pID)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("삭제")
                }
            }

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)

                    Text(badge.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(badge.color)
                .clipShape(Capsule())

                Text(remainingText(for: lot, status: status))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                statCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "혼잡도",
                    value: occupancyText(for: status)
                )
                statCard(
                    icon: "location.fill",
                    title: "거리",
                    value: route.map { String(format: "%.1fkm", $0.distanceKilometers) } ?? "계산 중"
                )
                statCard(
                    icon: "clock.fill",
                    title: "도착",
                    value: route.map { formattedTravelTime($0.travelMinutes) } ?? "계산 중"
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.49, green: 0.83, blue: 0.99))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "star")
                .font(.system(size: 46))
                .foregroundStyle(Color(.systemGray3))

            Text("즐겨찾기에 추가된 주차장이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button {
                showAddFavoritesSheet = true
            } label: {
                Text("주차장 추가하기")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.49, green: 0.83, blue: 0.99))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
    }

    private var addFavoritesSheet: some View {
        NavigationStack {
            Group {
                if availableLotsToAdd.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(Color(red: 0.44, green: 0.66, blue: 0.35))

                        Text("추가할 수 있는 주차장을 모두 담았어요")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        ForEach(availableLotsToAdd, id: \.pID) { lot in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(lot.pDisplayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text(lot.pAddress ?? lot.pName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Button {
                                    addFavorite(withID: lot.pID)
                                } label: {
                                    if addingFavoriteIDs.contains(lot.pID) {
                                        ProgressView()
                                            .tint(.white)
                                            .frame(width: 18, height: 18)
                                    } else {
                                        Text("추가")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(red: 0.49, green: 0.83, blue: 0.99))
                                )
                                .disabled(addingFavoriteIDs.contains(lot.pID))
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Color.white)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("주차장 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        showAddFavoritesSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func loadParkingLots() {
        APIService.shared.fetchParkingLots { result in
            Task { @MainActor in
                switch result {
                case .success(let items):
                    self.parkingLots = items
                    self.loadStatuses(for: items)
                case .failure(let error):
                    print("즐겨찾기 주차장 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadFavoriteIDs() {
        APIService.shared.fetchFavoriteParkingLotIDs { result in
            Task { @MainActor in
                switch result {
                case .success(let ids):
                    self.favoriteIDs = ids
                case .failure(let error):
                    print("즐겨찾기 목록 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadNotificationIDs() {
        APIService.shared.fetchNotificationParkingLotIDs { result in
            Task { @MainActor in
                switch result {
                case .success(let ids):
                    self.notificationIDs = ids
                case .failure(let error):
                    print("알림 설정 로드 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadStatuses(for lots: [ParkingLotAPIItem]) {
        for lot in lots {
            APIService.shared.fetchCurrentStatus(parkingLotID: lot.pID) { result in
                if case .success(let status) = result {
                    Task { @MainActor in
                        statusByLotID[lot.pID] = status
                    }
                }
            }
        }
    }

    private func updateRouteInfo(from location: CLLocation) {
        for lot in favoriteLots {
            let destinationLocation = CLLocation(latitude: lot.pLatitude, longitude: lot.pLongitude)
            let directDistanceKilometers = location.distance(from: destinationLocation) / 1000
            let fallbackMinutes = fallbackTravelMinutes(for: directDistanceKilometers)

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            request.destination = MKMapItem(
                placemark: MKPlacemark(
                    coordinate: CLLocationCoordinate2D(
                        latitude: lot.pLatitude,
                        longitude: lot.pLongitude
                    )
                )
            )
            request.transportType = .automobile

            MKDirections(request: request).calculateETA { response, _ in
                let route: FavoriteRouteInfo

                if let response {
                    route = FavoriteRouteInfo(
                        distanceKilometers: response.distance / 1000,
                        travelMinutes: max(Int(round(response.expectedTravelTime / 60)), 1)
                    )
                } else {
                    route = FavoriteRouteInfo(
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

    private func formattedTravelTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)시간"
            }
            return "\(hours)시간 \(remainingMinutes)분"
        }

        return "\(minutes)분"
    }

    private func deleteFavorite(withID id: Int) {
        APIService.shared.toggleFavorite(parkingLotID: id) { result in
            Task { @MainActor in
                switch result {
                case .success:
                    favoriteIDs.removeAll { $0 == id }
                case .failure(let error):
                    print("즐겨찾기 해제 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    private func toggleNotification(for id: Int) {
        let nextEnabled = !notificationIDs.contains(id)
        APIService.shared.updateNotificationSetting(parkingLotID: id, isEnabled: nextEnabled) { result in
            Task { @MainActor in
                switch result {
                case .success(let enabled):
                    if enabled {
                        notificationIDs.insert(id)
                    } else {
                        notificationIDs.remove(id)
                    }
                case .failure(let error):
                    print("알림 설정 저장 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    private func addFavorite(withID lotID: Int) {
        guard !favoriteIDs.contains(lotID) else { return }
        addingFavoriteIDs.insert(lotID)

        APIService.shared.toggleFavorite(parkingLotID: lotID) { result in
            Task { @MainActor in
                addingFavoriteIDs.remove(lotID)

                switch result {
                case .success(let isFavorite):
                    if isFavorite, !favoriteIDs.contains(lotID) {
                        favoriteIDs.append(lotID)
                    }
                    updateRouteInfo(from: normalizedOriginLocation(locationManager.currentLocation))
                case .failure(let error):
                    print("즐겨찾기 추가 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    private func remainingText(for lot: ParkingLotAPIItem, status: ParkingStatus?) -> String {
        guard let status, status.hasData else {
            return "잔여 정보 준비 중"
        }
        return "잔여: \(status.availableSpaces)대 / \(max(status.totalSpaces, lot.pTotalSpaces))대"
    }

    private func occupancyText(for status: ParkingStatus?) -> String {
        guard let status, status.hasData, status.totalSpaces > 0 else {
            return "정보 없음"
        }
        let percent = Int(round((Double(status.occupiedSpaces) / Double(status.totalSpaces)) * 100))
        return "\(percent)%"
    }

    private func favoriteStatus(for status: ParkingStatus?) -> FavoriteStatus {
        guard let status, status.hasData else { return .pending }

        switch status.congestionLevel {
        case "여유":
            return .available
        case "보통":
            return .moderate
        case "혼잡":
            return .crowded
        case "매우 혼잡":
            return .full
        default:
            return .pending
        }
    }
}

private struct FavoriteRouteInfo {
    let distanceKilometers: Double
    let travelMinutes: Int
}

private enum FavoriteStatus {
    case available
    case moderate
    case crowded
    case full
    case pending

    var title: String {
        switch self {
        case .available:
            return "여유"
        case .moderate:
            return "보통"
        case .crowded:
            return "혼잡"
        case .full:
            return "만차"
        case .pending:
            return "정보 준비 중"
        }
    }

    var color: Color {
        switch self {
        case .available:
            return Color(red: 0.44, green: 0.66, blue: 0.35)
        case .moderate:
            return Color(red: 0.91, green: 0.85, blue: 0.47)
        case .crowded:
            return Color(red: 0.85, green: 0.58, blue: 0.35)
        case .full:
            return Color(red: 0.80, green: 0.39, blue: 0.33)
        case .pending:
            return Color.gray
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesPage()
    }
}
