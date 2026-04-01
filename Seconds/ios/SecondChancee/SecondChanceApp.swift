import SwiftUI
import RevenueCat

@main
struct SecondChanceApp: App {
    init() {
        SubscriptionService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .errorModal()
        }
    }
}