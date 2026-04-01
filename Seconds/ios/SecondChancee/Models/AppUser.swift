import Foundation

nonisolated struct AppUser: Codable, Sendable, Identifiable {
    let id: String
    var username: String
    var nickname: String?
    var dateOfBirth: String?
    var joinDate: String?
    var selectedAddictions: [String]
    var reasonForQuitting: String?
    var whoFor: String?
    var isMentor: Bool
    var mentorApproved: Bool
    var onboardingComplete: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case nickname
        case dateOfBirth = "date_of_birth"
        case joinDate = "join_date"
        case selectedAddictions = "selected_addictions"
        case reasonForQuitting = "reason_for_quitting"
        case whoFor = "who_for"
        case isMentor = "is_mentor"
        case mentorApproved = "mentor_approved"
        case onboardingComplete = "onboarding_complete"
    }
}
