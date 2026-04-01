import Foundation

@Observable
class CommunityViewModel {
    var communities: [Community] = []
    var posts: [CommunityPost] = []
    var replies: [CommunityReply] = []
    var isLoading = false
    var selectedFilter: String?

    private let supabase = SupabaseService()

    init() {
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            supabase.accessToken = token
        }
        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            supabase.currentUserId = userId
        }
    }

    func fetchCommunities() async {
        isLoading = true
        defer { isLoading = false }
        do {
            communities = try await supabase.fetchCommunities()
        } catch {
            // silently fail
        }
    }

    func fetchPosts(communityId: String, filter: String? = nil) async {
        isLoading = true
        defer { isLoading = false }
        do {
            posts = try await supabase.fetchPosts(communityId: communityId, postType: filter)
        } catch {
            // silently fail
        }
    }

    func createPost(communityId: String, content: String, postType: String, userId: String, username: String) async throws {
        let post = CommunityPost(
            id: UUID().uuidString,
            communityId: communityId,
            userId: userId,
            content: content,
            postType: postType,
            username: username
        )
        try await supabase.createPost(post)
        await fetchPosts(communityId: communityId, filter: selectedFilter)
    }

    func fetchReplies(postId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            replies = try await supabase.fetchReplies(postId: postId)
        } catch {
            // silently fail
        }
    }

    func createReply(postId: String, content: String, userId: String, username: String) async throws {
        let reply = CommunityReply(
            id: UUID().uuidString,
            postId: postId,
            userId: userId,
            content: content,
            username: username
        )
        try await supabase.createReply(reply)
        await fetchReplies(postId: postId)
    }

    func reportContent(reportedBy: String, contentId: String, contentType: String, reason: String, details: String?) async throws {
        try await supabase.createReport(reportedBy: reportedBy, contentId: contentId, contentType: contentType, reason: reason, details: details)
    }

    func deletePost(postId: String, communityId: String, currentUserId: String) async throws {
        try await supabase.deletePost(postId: postId, userId: currentUserId)
        await fetchPosts(communityId: communityId, filter: selectedFilter)
    }
}
