import SwiftUI

struct ResourcesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(AppTheme.subtleGray)
                    }
                    Spacer()
                    Text("Resources")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(AppTheme.warmWhite)
                    Spacer()
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        Text("These are real people and organizations who can help. The AI in this app is not a substitute for professional support.")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(AppTheme.subtleGray)
                            .multilineTextAlignment(.center)
                            .italic()

                        ResourceSection(title: "Crisis & Mental Health", resources: [
                            ResourceItem(name: "Find A Helpline", url: "https://findahelpline.com", description: "International crisis line directory"),
                        ])

                        ResourceSection(title: "General Addiction", resources: [
                            ResourceItem(name: "Alcoholics Anonymous", url: "https://aa.org", description: "AA worldwide"),
                            ResourceItem(name: "Narcotics Anonymous", url: "https://na.org", description: "NA worldwide"),
                            ResourceItem(name: "SMART Recovery", url: "https://smartrecovery.org", description: "Science-based recovery support"),
                        ])

                        ResourceSection(title: "Gambling", resources: [
                            ResourceItem(name: "GamCare", url: "https://gamcare.org.uk", description: "UK gambling support"),
                            ResourceItem(name: "NCPG", url: "https://ncpgambling.org", description: "National Council on Problem Gambling"),
                        ])

                        ResourceSection(title: "Sexual Compulsivity", resources: [
                            ResourceItem(name: "SAA", url: "https://saa.org", description: "Sex Addicts Anonymous"),
                            ResourceItem(name: "SLAA", url: "https://slaafws.org", description: "Sex & Love Addicts Anonymous"),
                        ])

                        ResourceSection(title: "Nicotine", resources: [
                            ResourceItem(name: "Smokefree.gov", url: "https://smokefree.gov", description: "US smoking cessation"),
                            ResourceItem(name: "WHO Tobacco", url: "https://www.who.int/health-topics/tobacco", description: "World Health Organization"),
                        ])
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

nonisolated struct ResourceItem: Sendable {
    let name: String
    let url: String
    let description: String
}

struct ResourceSection: View {
    let title: String
    let resources: [ResourceItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.warmWhite)

            ForEach(resources, id: \.name) { resource in
                if let url = URL(string: resource.url) {
                    Link(destination: url) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(resource.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.terracotta)
                                Text(resource.description)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.subtleGray)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(AppTheme.subtleGray)
                        }
                        .padding(12)
                        .background(AppTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 10))
                    }
                }
            }
        }
    }
}
