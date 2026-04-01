import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var hasCheckedAuth = false
    @State private var selectedTab = 0
    @State private var showCheckedIn = true
    // NEW
    @State private var subscriptionChecked = false

    var body: some View {
        Group {
            if !hasCheckedAuth || !subscriptionChecked {
                // Loading
                ZStack {
                    AppTheme.charcoal.ignoresSafeArea()
                    ProgressView()
                        .tint(AppTheme.terracotta)
                }
            } else if !appState.isAuthenticated {
                SplashView(appState: appState)
            } else if appState.needsOnboarding {
                OnboardingView(appState: appState)
            } else if !SubscriptionService.shared.isSubscribed {
                // PAYWALL GATE — after sign up/onboarding, before app
                PaywallView {
                    // onSuccess: subscription confirmed, nothing needed,
                    // the isSubscribed flag flipping will re-evaluate the view
                }
            } else if !appState.hasCheckedInToday {
                UrgeTrackerView(appState: appState)
            } else if showCheckedIn && !appState.navigateToAIFromUrge {
                CheckedInView(appState: appState) {
                    showCheckedIn = false
                }
            } else {
                MainTabView(appState: appState, selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await appState.checkAuth()
            hasCheckedAuth = true
            // Check subscription after auth
            await SubscriptionService.shared.checkSubscriptionStatus()
            subscriptionChecked = true
        }
        .onChange(of: appState.hasCheckedInToday) { _, newValue in
            if newValue && appState.navigateToAIFromUrge {
                showCheckedIn = false
                selectedTab = 2
                appState.navigateToAIFromUrge = false
            }
        }
        .onChange(of: appState.isAuthenticated) { _, newValue in
            if !newValue {
                showCheckedIn = true
                selectedTab = 0
            }
        }
        // Re-check subscription when user authenticates
        .onChange(of: appState.isAuthenticated) { _, newValue in
            if newValue {
                Task {
                    await SubscriptionService.shared.checkSubscriptionStatus()
                }
            }
        }
    }
}

// MainTabView stays exactly the same — no changes needed
struct MainTabView: View {
    let appState: AppState
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView(appState: appState, selectedTab: $selectedTab)
            }
            Tab("Community", systemImage: "person.3.fill", value: 1) {
                CommunityListView(appState: appState)
            }
            Tab("Companion", systemImage: "message.fill", value: 2) {
                AICompanionView(appState: appState)
            }
            Tab("Profile", systemImage: "person.fill", value: 3) {
                ProfileView(appState: appState)
            }
        }
        .tint(AppTheme.terracotta)
    }
}