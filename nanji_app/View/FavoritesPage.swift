import SwiftUI

struct FavoritesPage: View {
    @State private var favorites: [FavoriteParking] = FavoriteParking.sampleData

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                infoBanner

                if favorites.isEmpty {
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
    }

    private var infoBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 0.49, green: 0.83, blue: 0.99))

            Text("자주 방문하는 주차장을 즐겨찾기에 추가하고 실시간 현황을 확인하세요")
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
            ForEach(favorites) { favorite in
                favoriteCard(for: favorite)
            }
        }
    }

    private func favoriteCard(for favorite: FavoriteParking) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.49, green: 0.83, blue: 0.99))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(favorite.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(favorite.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        toggleNotification(for: favorite.id)
                    } label: {
                        Image(systemName: favorite.notificationEnabled ? "bell.fill" : "bell.slash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(favorite.notificationEnabled ? Color(red: 0.49, green: 0.83, blue: 0.99) : .gray)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(favorite.notificationEnabled ? "알림 끄기" : "알림 켜기")

                    Button(role: .destructive) {
                        deleteFavorite(withID: favorite.id)
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

                    Text(favorite.status.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(favorite.status.color)
                .clipShape(Capsule())

                Text("잔여: \(favorite.availableSpots)대 / \(favorite.totalSpots)대")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                statCard(icon: "chart.line.uptrend.xyaxis", title: "혼잡도", value: "\(favorite.currentOccupancy)%")
                statCard(icon: "location.fill", title: "거리", value: favorite.distance)
                statCard(icon: "clock.fill", title: "도착", value: favorite.eta)
            }

            Button {
            } label: {
                Text("자세히 보기")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.49, green: 0.83, blue: 0.99))
                    )
            }
            .buttonStyle(.plain)
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

    private func deleteFavorite(withID id: String) {
        favorites.removeAll { $0.id == id }
    }

    private func toggleNotification(for id: String) {
        guard let index = favorites.firstIndex(where: { $0.id == id }) else { return }
        favorites[index].notificationEnabled.toggle()
    }
}

private struct FavoriteParking: Identifiable {
    let id: String
    let name: String
    let location: String
    let currentOccupancy: Int
    let availableSpots: Int
    let totalSpots: Int
    let distance: String
    let eta: String
    let status: FavoriteStatus
    var notificationEnabled: Bool

    static let sampleData: [FavoriteParking] = [
        FavoriteParking(
            id: "1",
            name: "난지 주차장",
            location: "한강공원 난지",
            currentOccupancy: 45,
            availableSpots: 137,
            totalSpots: 250,
            distance: "2.3km",
            eta: "7분",
            status: .available,
            notificationEnabled: true
        ),
        FavoriteParking(
            id: "2",
            name: "하늘공원 주차장",
            location: "월드컵공원",
            currentOccupancy: 78,
            availableSpots: 55,
            totalSpots: 250,
            distance: "3.5km",
            eta: "12분",
            status: .crowded,
            notificationEnabled: false
        ),
        FavoriteParking(
            id: "3",
            name: "뚝섬 주차장",
            location: "한강공원 뚝섬",
            currentOccupancy: 62,
            availableSpots: 95,
            totalSpots: 250,
            distance: "5.8km",
            eta: "18분",
            status: .moderate,
            notificationEnabled: true
        )
    ]
}

private enum FavoriteStatus {
    case available
    case moderate
    case crowded
    case full

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
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesPage()
    }
}
