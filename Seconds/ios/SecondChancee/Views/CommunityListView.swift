import SwiftUI

struct CommunityListView: View {
    let appState: AppState
    @State private var viewModel = CommunityViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.charcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("Communities")
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(AppTheme.warmWhite)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if viewModel.communities.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 12) {
                                Spacer().frame(height: 40)
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(AppTheme.subtleGray)
                                Text("No communities yet.")
                                    .font(.body)
                                    .foregroundStyle(AppTheme.subtleGray)
                            }
                        }

                        ForEach(viewModel.communities) { community in
                            NavigationLink(value: community.id) {
                                CommunityCard(community: community)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .navigationDestination(for: String.self) { communityId in
                    if let community = viewModel.communities.first(where: { $0.id == communityId }) {
                        CommunityDetailView(appState: appState, community: community)
                    }
                }

                if viewModel.isLoading && viewModel.communities.isEmpty {
                    ProgressView().tint(AppTheme.terracotta)
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.fetchCommunities()
            }
        }
    }
}

struct CommunityCard: View {
    let community: Community

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: iconForCommunity(community.addictionType))
                    .font(.title3)
                    .foregroundStyle(AppTheme.terracotta)

                Text(community.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.warmWhite)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.subtleGray)
            }

            Text(community.description)
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtleGray)
                .lineLimit(2)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
    }

    private func iconForCommunity(_ type: String) -> String {
        switch type {
        case "pornography": return "eye.slash.fill"
        case "gambling": return "dice.fill"
        case "alcohol": return "drop.fill"
        case "nicotine": return "smoke.fill"
        default: return "heart.fill"
        }
    }
}
