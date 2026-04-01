import Foundation
import RevenueCat

@Observable
class SubscriptionService {
    static let shared = SubscriptionService()

    var isSubscribed = false
    var isLoading = false

    // Replace with your actual RC Apple API key (appl_...)
    static let apiKey = "appl_REPLACE_WITH_YOUR_KEY"

    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Self.apiKey)
    }

    func checkSubscriptionStatus() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isSubscribed = customerInfo.entitlements["premium"]?.isActive == true
        } catch {
            isSubscribed = false
        }
    }

    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        isSubscribed = result.customerInfo.entitlements["premium"]?.isActive == true
    }

    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        isSubscribed = customerInfo.entitlements["premium"]?.isActive == true
    }

    func fetchOfferings() async -> Offerings? {
        try? await Purchases.shared.offerings()
    }
}