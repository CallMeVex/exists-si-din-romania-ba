import Foundation

nonisolated struct MentorApplication: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    var lifeStory: String
    var whatCausedAddiction: String
    var howTheyRecovered: String
    var whyTheyWantToMentor: String
    var status: String
    var submittedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case lifeStory = "life_story"
        case whatCausedAddiction = "what_caused_addiction"
        case howTheyRecovered = "how_they_recovered"
        case whyTheyWantToMentor = "why_they_want_to_mentor"
        case status
        case submittedAt = "submitted_at"
    }
}

nonisolated struct MentorProfile: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    var lifeStory: String
    var whatCausedAddiction: String
    var howTheyRecovered: String
    var whyTheyWantToMentor: String
    var addictionTypes: [String]
    var isActive: Bool
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case lifeStory = "life_story"
        case whatCausedAddiction = "what_caused_addiction"
        case howTheyRecovered = "how_they_recovered"
        case whyTheyWantToMentor = "why_they_want_to_mentor"
        case addictionTypes = "addiction_types"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}
