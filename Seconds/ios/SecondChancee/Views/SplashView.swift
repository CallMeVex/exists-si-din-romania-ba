import SwiftUI

struct SplashView: View {
    @State private var showAuth = false
    @State private var showSignUp = false
    @State private var showLogin = false
    let appState: AppState

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.terracotta)

                    Text("Second Chance")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundStyle(AppTheme.warmWhite)

                    Text("You don't have to do this alone.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(AppTheme.subtleGray)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Sign Up") {
                        showSignUp = true
                    }
                    .buttonStyle(AppButtonStyle())

                    Button("Log In") {
                        showLogin = true
                    }
                    .buttonStyle(AppButtonStyle(filled: false))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView(appState: appState)
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(appState: appState)
        }
    }
}
