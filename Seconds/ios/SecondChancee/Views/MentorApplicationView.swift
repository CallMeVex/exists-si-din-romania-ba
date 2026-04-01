import SwiftUI

struct MentorApplicationView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var lifeStory = ""
    @State private var whatCaused = ""
    @State private var howRecovered = ""
    @State private var whyMentor = ""
    @State private var isSubmitting = false
    @State private var submitted = false

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(AppTheme.subtleGray)
                    }
                    Spacer()
                    Text("Become a Supporter")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(AppTheme.warmWhite)
                    Spacer()
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        if submitted {
                            VStack(spacing: 16) {
                                Spacer().frame(height: 40)
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AppTheme.terracotta)
                                Text("Application submitted.")
                                    .font(.system(.title3, design: .serif, weight: .semibold))
                                    .foregroundStyle(AppTheme.warmWhite)
                                Text("We'll review your application and get back to you. Thank you for wanting to help.")
                                    .font(.body)
                                    .foregroundStyle(AppTheme.subtleGray)
                                    .multilineTextAlignment(.center)
                            }
                        } else if appState.currentUser?.isMentor == true {
                            VStack(spacing: 12) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(AppTheme.terracotta)
                                Text("You're already a supporter.")
                                    .font(.body)
                                    .foregroundStyle(AppTheme.warmWhite)
                            }
                            .padding(.top, 40)
                        } else {
                            Text("If you've been walking this road and want to support others just starting out, you can apply. Your story \u{2014} not a title or a number \u{2014} is what qualifies you.")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(AppTheme.subtleGray)
                                .lineSpacing(3)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your story")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.warmWhite)
                                AppTextEditor(placeholder: "What your life with this addiction looked like...", text: $lifeStory, minHeight: 100)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("What led to it")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.warmWhite)
                                AppTextEditor(placeholder: "What caused or triggered your addiction...", text: $whatCaused, minHeight: 80)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("How you've been recovering")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.warmWhite)
                                AppTextEditor(placeholder: "What's helped, what you've learned...", text: $howRecovered, minHeight: 80)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Why you want to support others")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.warmWhite)
                                AppTextEditor(placeholder: "What motivates you to help...", text: $whyMentor, minHeight: 80)
                            }

                            Button {
                                Task { await submitApplication() }
                            } label: {
                                if isSubmitting {
                                    ProgressView().tint(AppTheme.charcoal)
                                } else {
                                    Text("Submit Application")
                                }
                            }
                            .buttonStyle(AppButtonStyle())
                            .disabled(!canSubmit || isSubmitting)
                            .opacity(canSubmit ? 1 : 0.5)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    private var canSubmit: Bool {
        !lifeStory.trimmingCharacters(in: .whitespaces).isEmpty &&
        !whatCaused.trimmingCharacters(in: .whitespaces).isEmpty &&
        !howRecovered.trimmingCharacters(in: .whitespaces).isEmpty &&
        !whyMentor.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submitApplication() async {
        guard let userId = appState.currentUser?.id else { return }
        isSubmitting = true
        let application = MentorApplication(
            id: UUID().uuidString,
            userId: userId,
            lifeStory: lifeStory,
            whatCausedAddiction: whatCaused,
            howTheyRecovered: howRecovered,
            whyTheyWantToMentor: whyMentor,
            status: "pending"
        )
        do {
            try await appState.supabase.submitMentorApplication(application)
            submitted = true
        } catch {
            // silently fail
        }
        isSubmitting = false
    }
}
