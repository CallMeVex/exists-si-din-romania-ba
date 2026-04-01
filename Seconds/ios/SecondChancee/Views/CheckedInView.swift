import SwiftUI

struct CheckedInView: View {
    let appState: AppState
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.terracotta.opacity(0.7))

                Text("You checked in today.")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(AppTheme.warmWhite)

                Text("Keep going.")
                    .font(.body)
                    .foregroundStyle(AppTheme.subtleGray)

                Spacer()

                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(AppButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
