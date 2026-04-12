import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authStore: AuthStore
    @State private var isLoading = false
    @State private var selectedProvider: AuthProvider?
    @State private var showAuthAlert = false

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                MainTabView()
            } else {
                loginScreen
            }
        }
        .animation(.easeInOut, value: authStore.isLoggedIn)
        .onChange(of: authStore.errorMessage) { _, newValue in
            showAuthAlert = newValue != nil
        }
        .alert("로그인 안내", isPresented: $showAuthAlert, actions: {
            Button("확인", role: .cancel) {
                authStore.errorMessage = nil
            }
        }, message: {
            Text(authStore.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        })
    }

    private var loginScreen: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 18) {
                    iconCard

                    Text("자리난지")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("AI 기반 주차 예측 서비스를 시작해보세요")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 14) {
                    AuthButton(
                        title: AuthProvider.google.buttonTitle,
                        backgroundColor: .white,
                        foregroundColor: .black,
                        icon: .text("G"),
                        isLoading: isLoading && selectedProvider == .google,
                        action: { signIn(with: .google) }
                    )

                    AuthButton(
                        title: AuthProvider.kakao.buttonTitle,
                        backgroundColor: Color(red: 0.99, green: 0.87, blue: 0.22),
                        foregroundColor: .black,
                        icon: .system(name: "bubble.left.fill"),
                        isLoading: isLoading && selectedProvider == .kakao,
                        action: { signIn(with: .kakao) }
                    )

                    AuthButton(
                        title: AuthProvider.naver.buttonTitle,
                        backgroundColor: Color(red: 0.00, green: 0.63, blue: 0.35),
                        foregroundColor: .white,
                        icon: .text("N"),
                        isLoading: isLoading && selectedProvider == .naver,
                        action: { signIn(with: .naver) }
                    )

                    AuthButton(
                        title: AuthProvider.apple.buttonTitle,
                        backgroundColor: .black,
                        foregroundColor: .white,
                        icon: .system(name: "applelogo"),
                        isLoading: isLoading && selectedProvider == .apple,
                        action: { signIn(with: .apple) }
                    )
                }
                .padding(.horizontal, 24)
                .disabled(isLoading)

                VStack(spacing: 8) {
                    Text("간편 로그인으로 바로 서비스를 이용할 수 있어요")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.82))

                    Text("로그인 중 문제가 생기면 안내 메시지로 바로 알려드릴게요")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.74))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                Text("로그인하면 서비스 이용약관과 개인정보 처리방침에 동의하는 것으로 간주됩니다")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 32)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.80, green: 0.93, blue: 0.99), Color(red: 0.64, green: 0.82, blue: 0.99)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var iconCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .frame(width: 96, height: 96)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private func signIn(with provider: AuthProvider) {
        guard !isLoading else { return }

        selectedProvider = provider
        isLoading = true

        Task {
            await authStore.signIn(with: provider)
            isLoading = false
            selectedProvider = nil
        }
    }
}

private struct AuthButton: View {
    enum IconType {
        case system(name: String)
        case text(String)
    }

    let title: String
    let backgroundColor: Color
    let foregroundColor: Color
    let icon: IconType
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .frame(width: 34, height: 34)
                } else {
                    iconView
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(iconBackgroundOpacity))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Text(isLoading ? "로그인 중..." : title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
    }

    private var iconBackgroundOpacity: Double {
        switch icon {
        case .system: return 0.12
        case .text: return 0.15
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case let .system(name):
            Image(systemName: name)
                .font(.headline)
        case let .text(value):
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}

struct MainTabView: View {
    @State private var selection = 2

    var body: some View {
        TabView(selection: $selection) {
            AlternativeParkingTabView()
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("대체주차장")
                }
                .tag(0)

            TimingTabContainerView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("출발타이밍")
                }
                .tag(1)

            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(2)

            NavigationStack {
                FavoritesPage()
            }
                .tabItem {
                    Image(systemName: "star")
                    Text("즐겨찾기")
                }
                .tag(3)

            MyPageView()
                .tabItem {
                    Image(systemName: "person")
                    Text("마이페이지")
                }
                .tag(4)
        }
        .tint(Color.blue)
    }
}

private struct AlternativeParkingTabView: View {
    @StateObject private var vm = ParkingViewModel()

    var body: some View {
        NavigationStack {
            RecommendPage(parkingLots: vm.alternativeParkingLots)
                .onAppear {
                    vm.loadParkingLots()
                }
        }
    }
}

private struct TimingTabContainerView: View {
    @StateObject private var vm = ParkingViewModel()

    var body: some View {
        NavigationStack {
            TimingPage(vm: vm)
                .onAppear {
                    vm.loadPrediction()
                    vm.loadDepartureTimingOptions()
                }
        }
    }
}

private struct PlaceholderTab: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text("준비 중인 화면입니다")
                .foregroundColor(.secondary)
                .padding(.top, 6)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
    }
}

private struct MyPageView: View {
    @EnvironmentObject private var authStore: AuthStore
    @State private var profile: MyProfileAPIResponse?
    @State private var profileLoadError: String?
    @State private var isLoadingProfile = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(maskedUserName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(loginMethodText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let maskedEmail {
                            Text(maskedEmail)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }

                        if let profile {
                            Text("회원 번호 \(profile.userID)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    HStack(spacing: 12) {
                        summaryCard(
                            title: "즐겨찾기",
                            value: "\(profile?.favoriteCount ?? 0)개",
                            icon: "star.fill",
                            color: Color(red: 0.98, green: 0.75, blue: 0.21)
                        )

                        summaryCard(
                            title: "알림 사용",
                            value: "\(profile?.enabledNotificationCount ?? 0)개",
                            icon: "bell.fill",
                            color: Color(red: 0.49, green: 0.83, blue: 0.99)
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(Color(red: 0.49, green: 0.83, blue: 0.99))
                            Text("계정 정보")
                                .font(.headline)
                        }

                        infoRow(title: "로그인 방식", value: loginMethodText)
                        infoRow(title: "이름", value: profile?.name ?? authStore.currentUserName)
                        infoRow(title: "이메일", value: profile?.email ?? authStore.currentUserEmail ?? "정보 없음")
                        infoRow(title: "상태", value: isLoadingProfile ? "불러오는 중" : "이용 가능")

                        if let profileLoadError {
                            Text(profileLoadError)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("기타 설정")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        VStack(spacing: 4) {
                            settingsRow(
                                title: "앱 정보",
                                destination: AnyView(
                                    SettingsDetailView(
                                        title: "앱 정보",
                                        sections: [
                                            SettingsSection(title: "앱 버전", body: appVersionText),
                                            SettingsSection(title: "서비스 소개", body: "자리난지는 주차장의 현재 상황과 예측 정보를 확인하고, 출발 타이밍과 대체 주차장 정보를 함께 살펴볼 수 있는 서비스입니다.")
                                        ]
                                    )
                                )
                            )
                            settingsRow(
                                title: "이용 약관",
                                destination: AnyView(
                                    SettingsDetailView(
                                        title: "이용 약관",
                                        sections: [
                                            SettingsSection(title: "서비스 이용", body: "본 서비스는 주차 정보를 보다 편리하게 확인할 수 있도록 제공됩니다. 서비스에서 안내하는 정보는 참고용이며 현장 상황과 차이가 있을 수 있습니다."),
                                            SettingsSection(title: "계정 및 알림", body: "로그인한 사용자는 즐겨찾기와 알림 설정을 저장할 수 있으며, 관련 기능은 언제든지 앱에서 변경할 수 있습니다."),
                                            SettingsSection(title: "운영 안내", body: "서비스 품질 향상을 위해 일부 기능과 화면 구성은 변경될 수 있으며, 중요한 변경 사항은 앱 업데이트를 통해 반영됩니다.")
                                        ]
                                    )
                                )
                            )
                            settingsRow(
                                title: "개인정보 처리방침",
                                destination: AnyView(
                                    SettingsDetailView(
                                        title: "개인정보 처리방침",
                                        sections: [
                                            SettingsSection(title: "수집 정보", body: "로그인 과정에서 이름, 이메일 등 기본 계정 정보가 저장될 수 있으며, 즐겨찾기와 알림 설정은 서비스 이용 편의를 위해 보관됩니다."),
                                            SettingsSection(title: "이용 목적", body: "수집된 정보는 로그인 유지, 개인화된 주차장 정보 제공, 즐겨찾기 및 알림 기능 제공을 위해 사용됩니다."),
                                            SettingsSection(title: "보관 및 관리", body: "개인정보는 서비스 운영 목적 범위 내에서만 사용되며, 관련 법령과 내부 기준에 따라 안전하게 관리됩니다.")
                                        ]
                                    )
                                )
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Button(role: .destructive) {
                        authStore.signOut()
                    } label: {
                        Text("로그아웃")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.89, green: 0.32, blue: 0.28))

                    Text("버전 \(appVersionText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("마이페이지")
            .onAppear {
                loadProfile()
            }
        }
    }

    private var loginMethodText: String {
        guard let provider = authStore.provider else {
            return "로그인 정보가 없습니다"
        }

        return "\(provider.title) 계정으로 로그인됨"
    }

    private var maskedUserName: String {
        PrivacyMasker.maskedName(authStore.currentUserName)
    }

    private var maskedEmail: String? {
        let source = profile?.email ?? authStore.currentUserEmail
        guard let email = source else { return nil }
        return PrivacyMasker.maskedEmail(email)
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func loadProfile() {
        isLoadingProfile = true
        profileLoadError = nil

        APIService.shared.fetchMyProfile { result in
            Task { @MainActor in
                isLoadingProfile = false

                switch result {
                case .success(let response):
                    profile = response
                case .failure:
                    profileLoadError = "일부 계정 정보는 잠시 후 다시 반영될 수 있어요."
                }
            }
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func settingsRow(title: String, destination: AnyView) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.vertical, 14)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

private struct SettingsDetailView: View {
    let title: String
    let sections: [SettingsSection]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(section.body)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthStore())
    }
}
