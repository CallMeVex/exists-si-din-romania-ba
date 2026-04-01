import Foundation

nonisolated struct Community: Codable, Sendable, Identifiable {
    let id: String
    var name: String
    var addictionType: String
    var description: String
    var createdBy: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case addictionType = "addiction_type"
        case description
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}
