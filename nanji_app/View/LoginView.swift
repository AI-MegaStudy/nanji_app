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

                    Text("한강공원 주차장")
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
                    Text("소셜 로그인은 MVVM 구조로 분리되어 동작합니다")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.82))

                    Text("설정이 빠진 항목이 있으면 앱에서 바로 에러 안내가 뜹니다")
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
            PlaceholderTab(title: "대체 주차장")
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("대체주차장")
                }
                .tag(0)

            PlaceholderTab(title: "출발 타이밍")
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

            PlaceholderTab(title: "즐겨찾기")
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

    var body: some View {
        NavigationStack {
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

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("마이페이지")
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
        guard let email = authStore.currentUserEmail else { return nil }
        return PrivacyMasker.maskedEmail(email)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthStore())
    }
}
