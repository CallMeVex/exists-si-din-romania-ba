import Foundation

nonisolated struct JournalEntry: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    let date: String
    var promptResponses: [String: String]?
    var freeText: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case promptResponses = "prompt_responses"
        case freeText = "free_text"
        case createdAt = "created_at"
    }
}
