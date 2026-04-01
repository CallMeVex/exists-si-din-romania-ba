import Foundation

nonisolated struct StreakTracker: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    var addictionType: String
    var currentStreak: Int
    var longestStreak: Int
    var totalCleanDays: Int
    var lastCheckinDate: String?
    var relapseCount: Int
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case addictionType = "addiction_type"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalCleanDays = "total_clean_days"
        case lastCheckinDate = "last_checkin_date"
        case relapseCount = "relapse_count"
        case updatedAt = "updated_at"
    }
}
