import SwiftUI

struct CreatePostView: View {
    let appState: AppState
    let communityId: String
    let viewModel: CommunityViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var postType = "general"
    @State private var isPosting = false

    private let postTypes = [
        ("question", "Ask for Support"),
        ("win", "Share a Win"),
        ("relapse_reflection", "Relapse Reflection"),
        ("general", "General")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.charcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.warmWhite)

                            HStack(spacing: 8) {
                                ForEach(postTypes, id: \.0) { type in
                                    Button {
                                        postType = type.0
                                    } label: {
                                        Text(type.1)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(postType == type.0 ? AppTheme.charcoal : AppTheme.warmWhite)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(postType == type.0 ? AppTheme.terracotta : AppTheme.cardBackground)
                                            .clipShape(.capsule)
                                    }
                                }
                            }
                        }

                        AppTextEditor(placeholder: "Share what's on your mind...", text: $content, minHeight: 150)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.subtleGray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createPost() }
                    } label: {
                        if isPosting {
                            ProgressView().tint(AppTheme.terracotta)
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.terracotta)
                        }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
                }
            }
        }
    }

    private func createPost() async {
        guard let userId = appState.currentUser?.id else { return }
        isPosting = true
        do {
            try await viewModel.createPost(
                communityId: communityId,
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                postType: postType,
                userId: userId,
                username: appState.currentUser?.username ?? "Anonymous"
            )
            dismiss()
        } catch {
            // silently fail
        }
        isPosting = false
    }
}
