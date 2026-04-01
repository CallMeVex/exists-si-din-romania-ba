import SwiftUI

struct CommunityDetailView: View {
    let appState: AppState
    let community: Community
    @State private var viewModel = CommunityViewModel()
    @State private var selectedFilter: String?
    @State private var showCreatePost = false
    @State private var showRules = false

    private let filters = [
        ("All", nil as String?),
        ("Support", "question"),
        ("Wins", "win"),
        ("Reflections", "relapse_reflection"),
        ("General", "general")
    ]

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.0) { filter in
                            Button {
                                selectedFilter = filter.1
                                Task { await viewModel.fetchPosts(communityId: community.id, filter: filter.1) }
                            } label: {
                                Text(filter.0)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(selectedFilter == filter.1 ? AppTheme.charcoal : AppTheme.warmWhite)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter.1 ? AppTheme.terracotta : AppTheme.cardBackground)
                                    .clipShape(.capsule)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .contentMargins(.horizontal, 0)
                .padding(.vertical, 12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.posts.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 12) {
                                Spacer().frame(height: 40)
                                Text("Nothing here yet. Whenever you're ready.")
                                    .font(.body)
                                    .foregroundStyle(AppTheme.subtleGray)
                            }
                        }

                        ForEach(viewModel.posts) { post in
                            NavigationLink {
                                PostDetailView(appState: appState, post: post)
                            } label: {
                                PostCard(post: post, appState: appState, viewModel: viewModel, communityId: community.id)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(community.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showRules = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(AppTheme.subtleGray)
                    }
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(AppTheme.terracotta)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchPosts(communityId: community.id)
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(appState: appState, communityId: community.id, viewModel: viewModel)
        }
        .alert("Community Rules", isPresented: $showRules) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("No explicit descriptions of addictive behaviors or relapse details.\nNo judgment or shaming.\nNo medical advice.\nNo promotion of any product or service.\nSupporters are here to listen and share — not to counsel professionally.")
        }
    }
}

struct PostCard: View {
    let post: CommunityPost
    let appState: AppState
    let viewModel: CommunityViewModel
    let communityId: String
    @State private var showReport = false
    @State private var showDeleteConfirm = false

    private let reportReasons = ["Harmful advice", "Triggering content", "Inappropriate behavior", "Spam"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Text(post.username ?? "Anonymous")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.warmWhite)
                    if post.isMentor == true {
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.terracotta)
                    }
                }

                Spacer()

                PostTypeBadge(type: post.postType)

                Menu {
                    Button("Report Post") {
                        showReport = true
                    }

                    if post.userId == appState.currentUser?.id {
                        Button("Delete Post", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleGray)
                }
                .buttonStyle(.plain)
            }

            Text(post.content)
                .font(.body)
                .foregroundStyle(AppTheme.warmWhite.opacity(0.85))
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            if let createdAt = post.createdAt {
                Text(formatDate(createdAt))
                    .font(.caption)
                    .foregroundStyle(AppTheme.subtleGray)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .confirmationDialog("Report this post", isPresented: $showReport, titleVisibility: .visible) {
            ForEach(reportReasons, id: \.self) { reason in
                Button(reason) {
                    Task {
                        guard let userId = appState.currentUser?.id else { return }
                        try? await viewModel.reportContent(reportedBy: userId, contentId: post.id, contentType: "post", reason: reason.lowercased().replacingOccurrences(of: " ", with: "_"), details: nil)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete this post?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    guard let currentUserId = appState.currentUser?.id else { return }
                    try? await viewModel.deletePost(postId: post.id, communityId: communityId, currentUserId: currentUserId)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "" }
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }
}

struct PostTypeBadge: View {
    let type: String

    private var label: String {
        switch type {
        case "question": "Support"
        case "win": "Win"
        case "relapse_reflection": "Reflection"
        default: "General"
        }
    }

    private var color: Color {
        switch type {
        case "question": Color(red: 0.4, green: 0.6, blue: 0.7)
        case "win": Color(red: 0.5, green: 0.7, blue: 0.5)
        case "relapse_reflection": AppTheme.terracotta
        default: AppTheme.subtleGray
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(.capsule)
    }
}
