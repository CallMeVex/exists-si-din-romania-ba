import Foundation

nonisolated struct RelapseLog: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    var addictionType: String
    var loggedAt: String?
    var reflection: String?
    var urgeLevelAtTime: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case addictionType = "addiction_type"
        case loggedAt = "logged_at"
        case reflection
        case urgeLevelAtTime = "urge_level_at_time"
    }
}
