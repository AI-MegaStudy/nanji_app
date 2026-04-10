import SwiftUI

struct LoginView: View {
    @State private var didTapContinue = false

    var body: some View {
        if didTapContinue {
            MainTabView()
        } else {
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

                        Text("AI 기반 주차 예측 서비스")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 14) {
                        AuthButton(
                            title: "Google로 계속하기",
                            backgroundColor: .white,
                            foregroundColor: .black,
                            icon: .text("G"),
                            action: continueAction
                        )

                        AuthButton(
                            title: "카카오로 계속하기",
                            backgroundColor: Color(red: 0.99, green: 0.87, blue: 0.22),
                            foregroundColor: .black,
                            icon: .system(name: "bubble.left.fill"),
                            action: continueAction
                        )

                        AuthButton(
                            title: "네이버로 계속하기",
                            backgroundColor: Color(red: 0.00, green: 0.63, blue: 0.35),
                            foregroundColor: .white,
                            icon: .text("N"),
                            action: continueAction
                        )

                        AuthButton(
                            title: "Apple로 계속하기",
                            backgroundColor: .black,
                            foregroundColor: .white,
                            icon: .system(name: "applelogo"),
                            action: continueAction
                        )
                    }
                    .padding(.horizontal, 24)

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

    private func continueAction() {
        withAnimation(.easeInOut) {
            didTapContinue = true
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconView
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(iconBackgroundOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
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

            PlaceholderTab(title: "마이페이지")
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
