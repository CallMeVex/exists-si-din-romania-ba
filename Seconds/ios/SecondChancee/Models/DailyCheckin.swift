import Foundation

nonisolated struct DailyCheckin: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    let date: String
    var urgeLevel: Int
    var urgeReason: String?
    var mood: Int?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case urgeLevel = "urge_level"
        case urgeReason = "urge_reason"
        case mood
        case createdAt = "created_at"
    }
}
