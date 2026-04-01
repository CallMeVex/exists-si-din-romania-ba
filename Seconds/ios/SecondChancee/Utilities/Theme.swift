import SwiftUI

enum AppTheme {
    static let charcoal = Color(red: 0.102, green: 0.102, blue: 0.102)
    static let charcoalLight = Color(red: 0.129, green: 0.129, blue: 0.129)
    static let warmWhite = Color(red: 0.941, green: 0.925, blue: 0.894)
    static let terracotta = Color(red: 0.753, green: 0.478, blue: 0.353)
    static let terracottaDark = Color(red: 0.6, green: 0.35, blue: 0.25)
    static let subtleGray = Color(red: 0.45, green: 0.43, blue: 0.41)
    static let cardBackground = Color(red: 0.145, green: 0.145, blue: 0.145)
    static let surfaceBackground = Color(red: 0.118, green: 0.118, blue: 0.118)

    static func urgeColor(for level: Int) -> Color {
        switch level {
        case 1...4: return Color(red: 0.55, green: 0.65, blue: 0.6)
        case 5...7: return terracotta.opacity(0.8)
        case 8...10: return Color(red: 0.75, green: 0.35, blue: 0.3)
        default: return subtleGray
        }
    }
}

struct AppButtonStyle: ButtonStyle {
    let filled: Bool

    init(filled: Bool = true) {
        self.filled = filled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(filled ? AppTheme.charcoal : AppTheme.terracotta)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(filled ? AppTheme.terracotta : Color.clear)
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.terracotta.opacity(0.5), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
