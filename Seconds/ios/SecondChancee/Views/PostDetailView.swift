import SwiftUI

struct PostDetailView: View {
    let appState: AppState
    let post: CommunityPost
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CommunityViewModel()
    @State private var replyText = ""
    @State private var isSending = false
    @State private var showReport = false
    @State private var showDeleteConfirm = false

    private let reportReasons = ["Harmful advice", "Triggering content", "Inappropriate behavior", "Spam"]

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Text(post.username ?? "Anonymous")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.warmWhite)
                                if post.isMentor == true {
                                    Image(systemName: "leaf.fill")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.terracotta)
                                }
                                Spacer()
                                PostTypeBadge(type: post.postType)
                            }

                            Text(post.content)
                                .font(.body)
                                .foregroundStyle(AppTheme.warmWhite.opacity(0.9))
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(AppTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 12))

                        if viewModel.replies.isEmpty && !viewModel.isLoading {
                            Text("No replies yet.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.subtleGray)
                                .padding(.top, 8)
                        }

                        ForEach(viewModel.replies) { reply in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Text(reply.username ?? "Anonymous")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.warmWhite)
                                    if reply.isMentor == true {
                                        Image(systemName: "leaf.fill")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.terracotta)
                                    }
                                }
                                Text(reply.content)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.warmWhite.opacity(0.85))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.surfaceBackground)
                            .clipShape(.rect(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }

                Divider().background(AppTheme.cardBackground)

                HStack(spacing: 12) {
                    TextField("", text: $replyText, prompt: Text("Reply...").foregroundStyle(AppTheme.subtleGray), axis: .vertical)
                        .font(.body)
                        .foregroundStyle(AppTheme.warmWhite)
                        .lineLimit(1...3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 18))

                    Button {
                        Task { await sendReply() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.subtleGray : AppTheme.terracotta)
                    }
                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.surfaceBackground)
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppTheme.subtleGray)
                }
            }
        }
        .task {
            await viewModel.fetchReplies(postId: post.id)
        }
        .confirmationDialog("Report this post", isPresented: $showReport, titleVisibility: .visible) {
            ForEach(reportReasons, id: \.self) { reason in
                Button(reason) {
                    Task {
                        guard let userId = appState.currentUser?.id else { return }
                        try? await viewModel.reportContent(
                            reportedBy: userId,
                            contentId: post.id,
                            contentType: "post",
                            reason: reason.lowercased().replacingOccurrences(of: " ", with: "_"),
                            details: nil
                        )
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete this post?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    guard let currentUserId = appState.currentUser?.id else { return }
                    try? await viewModel.deletePost(postId: post.id, communityId: post.communityId, currentUserId: currentUserId)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func sendReply() async {
        guard let userId = appState.currentUser?.id else { return }
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSending = true
        do {
            try await viewModel.createReply(
                postId: post.id,
                content: text,
                userId: userId,
                username: appState.currentUser?.username ?? "Anonymous"
            )
            replyText = ""
        } catch {
            // silently fail
        }
        isSending = false
    }
}
