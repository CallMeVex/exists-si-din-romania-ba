import Foundation

nonisolated struct CommunityPost: Codable, Sendable, Identifiable {
    let id: String
    let communityId: String
    let userId: String
    var content: String
    var postType: String
    var createdAt: String?
    var username: String?
    var isMentor: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case communityId = "community_id"
        case userId = "user_id"
        case content
        case postType = "post_type"
        case createdAt = "created_at"
        case username
        case isMentor = "is_mentor"
    }
}

nonisolated struct CommunityReply: Codable, Sendable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    var content: String
    var createdAt: String?
    var username: String?
    var isMentor: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case username
        case isMentor = "is_mentor"
    }
}
