import SwiftUI
import RevenueCat

struct PaywallView: View {
    @State private var offerings: Offerings?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isPurchasing = false
    @State private var selectedPackage: Package?

    let onSuccess: () -> Void

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // Top bar
                    HStack {
                        Text("SECOND CHANCE")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(AppTheme.terracotta)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 56)
                    .padding(.bottom, 40)

                    // Header
                    VStack(spacing: 16) {
                        Text("Become a Supporter")
                            .font(.system(size: 34, weight: .semibold, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.warmWhite)

                        Text("Help us keep Second Chance a private, ad-free sanctuary for everyone on the path to recovery.")
                            .font(.system(size: 16, weight: .regular))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.subtleGray)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)

                    // Feature rows
                    VStack(spacing: 12) {
                        FeatureCard(
                            icon: "message.fill",
                            title: "UNLIMITED COMPANION SUPPORT",
                            subtitle: "Chat with the AI whenever you need"
                        )
                        FeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "ADVANCED JOURNEY ANALYSIS",
                            subtitle: "Deeper insights into your check-ins"
                        )
                        FeatureCard(
                            icon: "person.3.fill",
                            title: "COMMUNITY SUPPORT",
                            subtitle: "Help keep our collective sanctuary thriving."
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                    // Packages
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.terracotta)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            if let offering = offerings?.current {
                                ForEach(offering.availablePackages, id: \.identifier) { package in
                                    PricingCard(
                                        package: package,
                                        isSelected: selectedPackage?.identifier == package.identifier,
                                        onTap: { selectedPackage = package }
                                    )
                                }
                            } else {
                                // Fallback placeholder cards while loading
                                PlaceholderPricingCard(
                                    label: "MONTHLY SUPPORT",
                                    price: "$4.99",
                                    period: "/month",
                                    badge: nil
                                )
                                PlaceholderPricingCard(
                                    label: "YEARLY SANCTUARY",
                                    price: "$39.99",
                                    period: "/year",
                                    badge: "MOST SUSTAINABLE"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(AppTheme.terracotta)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 12)
                    }

                    // CTA Button
                    Button {
                        guard let pkg = selectedPackage ?? offerings?.current?.availablePackages.first else { return }
                        purchase(package: pkg)
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(AppTheme.charcoal)
                            } else {
                                Text("SUPPORT THE SANCTUARY")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.charcoal)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)

                    // Footer links
                    HStack(spacing: 32) {
                        Button("RESTORE PURCHASE") {
                            restore()
                        }
                        Button("PRIVACY POLICY") {
                            // open privacy policy URL if you have one
                        }
                    }
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(AppTheme.subtleGray)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .task {
            await loadOfferings()
        }
    }

    private func loadOfferings() async {
        isLoading = true
        offerings = await SubscriptionService.shared.fetchOfferings()
        // Auto-select the first package
        selectedPackage = offerings?.current?.availablePackages.first
        isLoading = false
    }

    private func purchase(package: Package) {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                try await SubscriptionService.shared.purchase(package: package)
                if SubscriptionService.shared.isSubscribed {
                    onSuccess()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }

    private func restore() {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                try await SubscriptionService.shared.restorePurchases()
                if SubscriptionService.shared.isSubscribed {
                    onSuccess()
                } else {
                    errorMessage = "No active subscription found."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }
}

// MARK: - Subviews

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppTheme.terracotta)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.warmWhite)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(AppTheme.subtleGray)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppTheme.terracotta.opacity(0.25), lineWidth: 1)
        )
    }
}

struct PricingCard: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void

    var isYearly: Bool {
        package.packageType == .annual
    }

    var label: String {
        isYearly ? "YEARLY SANCTUARY" : "MONTHLY SUPPORT"
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(AppTheme.subtleGray)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(package.localizedPriceString)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppTheme.warmWhite)
                        Text(isYearly ? "/year" : "/month")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.subtleGray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isSelected ? AppTheme.terracotta : AppTheme.terracotta.opacity(0.2),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )

                if isYearly {
                    Text("MOST SUSTAINABLE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.charcoal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.top, -1)
                        .padding(.trailing, 16)
                }
            }
        }
    }
}

struct PlaceholderPricingCard: View {
    let label: String
    let price: String
    let period: String
    let badge: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(AppTheme.subtleGray)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.warmWhite)
                    Text(period)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.subtleGray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(AppTheme.terracotta.opacity(0.2), lineWidth: 1)
            )

            if let badge {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.charcoal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.terracotta)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.top, -1)
                    .padding(.trailing, 16)
            }
        }
    }
}