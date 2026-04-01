import SwiftUI

struct UrgeTrackerView: View {
    let appState: AppState
    @State private var urgeLevel: Double = 3
    @State private var urgeReason = ""
    @State private var mood: Int?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var urgeLevelInt: Int { Int(urgeLevel) }
    private var requiresReason: Bool { urgeLevelInt >= 6 }

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("How are you holding up today?")
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(AppTheme.warmWhite)
                            .multilineTextAlignment(.center)

                        Text(todayFormatted)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.subtleGray)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        Text("\(urgeLevelInt)")
                            .font(.system(size: 72, weight: .bold, design: .serif))
                            .foregroundStyle(AppTheme.urgeColor(for: urgeLevelInt))
                            .contentTransition(.numericText())
                            .animation(.easeOut(duration: 0.2), value: urgeLevelInt)

                        Slider(value: $urgeLevel, in: 1...10, step: 1)
                            .tint(AppTheme.urgeColor(for: urgeLevelInt))
                            .padding(.horizontal, 8)
                            .sensoryFeedback(.selection, trigger: urgeLevelInt)

                        HStack {
                            Text("Calm")
                                .font(.caption)
                                .foregroundStyle(AppTheme.subtleGray)
                            Spacer()
                            Text("Intense")
                                .font(.caption)
                                .foregroundStyle(AppTheme.subtleGray)
                        }
                        .padding(.horizontal, 8)
                    }

                    if !requiresReason {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How's your mood?")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.warmWhite)

                            HStack(spacing: 8) {
                                ForEach(1...10, id: \.self) { value in
                                    Button {
                                        mood = mood == value ? nil : value
                                    } label: {
                                        Text("\(value)")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(mood == value ? AppTheme.charcoal : AppTheme.warmWhite)
                                            .frame(width: 30, height: 30)
                                            .background(mood == value ? AppTheme.terracotta : AppTheme.cardBackground)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                    }

                    if requiresReason {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's driving this right now?")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.warmWhite)

                            AppTextEditor(placeholder: "You don't need to have the right words...", text: $urgeReason, minHeight: 100)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anything on your mind?")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.warmWhite.opacity(0.7))

                            AppTextEditor(placeholder: "Optional reflection...", text: $urgeReason, minHeight: 80)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.8))
                    }

                    Button {
                        Task { await submitCheckin() }
                    } label: {
                        if isSubmitting {
                            ProgressView().tint(AppTheme.charcoal)
                        } else {
                            Text("Log Check-In")
                        }
                    }
                    .buttonStyle(AppButtonStyle())
                    .disabled((requiresReason && urgeReason.trimmingCharacters(in: .whitespaces).isEmpty) || isSubmitting)
                    .opacity((requiresReason && urgeReason.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.5 : 1)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func submitCheckin() async {
        isSubmitting = true
        errorMessage = nil
        do {
            try await appState.submitCheckin(
                urgeLevel: urgeLevelInt,
                urgeReason: urgeReason.isEmpty ? nil : urgeReason,
                mood: mood
            )
        } catch {
            errorMessage = "Something went wrong. Try again."
        }
        isSubmitting = false
    }
}
