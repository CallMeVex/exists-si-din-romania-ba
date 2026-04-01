import SwiftUI

struct RelapseFormView: View {
    let appState: AppState
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAddiction: String = ""
    @State private var urgeLevel: Double = 5
    @State private var whatHappened = ""
    @State private var whatCouldPrevent = ""
    @State private var howToImprove = ""
    @State private var isSubmitting = false
    @State private var submitted = false

    private var addictions: [String] {
        appState.currentUser?.selectedAddictions ?? []
    }

    private var singleAddiction: Bool {
        addictions.count == 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.charcoal.ignoresSafeArea()

                if submitted {
                    submittedView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Log a Setback")
                                    .font(.system(size: 36, weight: .semibold, design: .serif))
                                    .italic()
                                    .foregroundStyle(AppTheme.warmWhite)

                                Text("Honesty is the first step toward reclaiming your path.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.subtleGray)
                                    .lineSpacing(2)
                            }
                            .padding(.top, 8)

                            if !singleAddiction {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("ADDICTION TYPE")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(1.5)
                                        .foregroundStyle(AppTheme.subtleGray)

                                    FlowLayout(spacing: 10) {
                                        ForEach(addictions, id: \.self) { addiction in
                                            Button {
                                                selectedAddiction = addiction
                                            } label: {
                                                Text(addiction.capitalized)
                                                    .font(.subheadline.weight(.medium))
                                                    .foregroundStyle(selectedAddiction == addiction ? AppTheme.charcoal : AppTheme.warmWhite.opacity(0.8))
                                                    .padding(.horizontal, 18)
                                                    .padding(.vertical, 10)
                                                    .background(selectedAddiction == addiction ? AppTheme.terracotta : AppTheme.cardBackground)
                                                    .clipShape(.rect(cornerRadius: 24))
                                            }
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("URGE INTENSITY")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(1.5)
                                        .foregroundStyle(AppTheme.subtleGray)

                                    Spacer()

                                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                                        Text("\(Int(urgeLevel))")
                                            .font(.system(.title2, weight: .bold))
                                            .foregroundStyle(AppTheme.terracotta)
                                        Text("/10")
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.subtleGray)
                                    }
                                }

                                Slider(value: $urgeLevel, in: 1...10, step: 1)
                                    .tint(AppTheme.terracotta)

                                HStack {
                                    Text("MILD")
                                        .font(.system(size: 10, weight: .medium))
                                        .tracking(1)
                                        .foregroundStyle(AppTheme.subtleGray)
                                    Spacer()
                                    Text("SEVERE")
                                        .font(.system(size: 10, weight: .medium))
                                        .tracking(1)
                                        .foregroundStyle(AppTheme.subtleGray)
                                }
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("WHAT WAS HAPPENING?")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(AppTheme.subtleGray)

                                AppTextEditor(
                                    placeholder: "Describe the environment, your feelings, or the triggers...",
                                    text: $whatHappened,
                                    minHeight: 100
                                )
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("WHAT COULD YOU HAVE DONE DIFFERENTLY?")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(AppTheme.subtleGray)

                                AppTextEditor(
                                    placeholder: "What actions or choices could have changed the outcome?",
                                    text: $whatCouldPrevent,
                                    minHeight: 80
                                )
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("HOW CAN YOU IMPROVE?")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(AppTheme.subtleGray)

                                AppTextEditor(
                                    placeholder: "What will you carry forward from this moment?",
                                    text: $howToImprove,
                                    minHeight: 80
                                )
                            }

                            VStack(spacing: 12) {
                                Button {
                                    Task { await submitRelapse() }
                                } label: {
                                    Group {
                                        if isSubmitting {
                                            ProgressView().tint(AppTheme.charcoal)
                                        } else {
                                            Text("Log This")
                                                .font(.body.weight(.semibold))
                                        }
                                    }
                                    .foregroundStyle(AppTheme.charcoal)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(canSubmit ? AppTheme.terracotta : AppTheme.terracotta.opacity(0.4))
                                    .clipShape(.rect(cornerRadius: 28))
                                }
                                .disabled(!canSubmit || isSubmitting)

                                Text("\"Logging this takes honesty. That matters.\"")
                                    .font(.caption)
                                    .italic()
                                    .foregroundStyle(AppTheme.subtleGray)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.bottom, 32)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .foregroundStyle(AppTheme.warmWhite)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Second Chance")
                        .font(.system(.subheadline, design: .serif, weight: .medium))
                        .foregroundStyle(AppTheme.warmWhite)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if singleAddiction, let first = addictions.first {
                selectedAddiction = first
            }
        }
    }

    private var canSubmit: Bool {
        !selectedAddiction.isEmpty
    }

    private var submittedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.terracotta.opacity(0.55))

            VStack(spacing: 10) {
                Text("One moment doesn't erase everything you've built.")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(AppTheme.warmWhite)
                    .multilineTextAlignment(.center)

                Text("You're still here, and that matters.")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AppTheme.subtleGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Button {
                onComplete()
                dismiss()
            } label: {
                Text("Close")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.charcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.terracotta)
                    .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    private func submitRelapse() async {
        isSubmitting = true
        var parts: [String] = []
        if !whatHappened.isEmpty { parts.append("What happened: \(whatHappened)") }
        if !whatCouldPrevent.isEmpty { parts.append("Could have done: \(whatCouldPrevent)") }
        if !howToImprove.isEmpty { parts.append("How to improve: \(howToImprove)") }
        let combined = parts.isEmpty ? nil : parts.joined(separator: "\n\n")

        do {
            try await appState.logRelapse(
                addictionType: selectedAddiction,
                urgeLevel: Int(urgeLevel),
                reflection: combined
            )
            submitted = true
        } catch {
        }
        isSubmitting = false
    }
}
