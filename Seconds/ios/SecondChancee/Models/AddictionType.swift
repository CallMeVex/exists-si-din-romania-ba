import Foundation

nonisolated enum AddictionType: String, Codable, Sendable, CaseIterable, Identifiable, Hashable {
    case pornography
    case gambling
    case alcohol
    case nicotine

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pornography: "Pornography"
        case .gambling: "Gambling"
        case .alcohol: "Alcohol"
        case .nicotine: "Nicotine"
        }
    }

    var icon: String {
        switch self {
        case .pornography: "eye.slash.fill"
        case .gambling: "dice.fill"
        case .alcohol: "drop.fill"
        case .nicotine: "smoke.fill"
        }
    }

    var communityName: String {
        "\(displayName) Recovery"
    }
}
