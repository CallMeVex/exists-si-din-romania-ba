import SwiftUI

struct OnboardingView: View {
    let appState: AppState
    @State private var step = 0
    @State private var nickname = ""
    @State private var dateOfBirth = Date()
    @State private var hasSetDOB = false
    @State private var selectedAddictions: Set<AddictionType> = []
    @State private var reasonForQuitting = ""
    @State private var whoFor = ""
    @State private var initialUrge: Double = 3
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let totalSteps = 5

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? AppTheme.terracotta : AppTheme.cardBackground)
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 32) {
                        switch step {
                        case 0: nicknameStep
                        case 1: addictionsStep
                        case 2: reasonStep
                        case 3: whoForStep
                        case 4: urgePreviewStep
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                }
                .scrollDismissesKeyboard(.interactively)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    Button {
                        if step < totalSteps - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) { step += 1 }
                        } else {
                            Task { await completeOnboarding() }
                        }
                    } label: {
                        if isLoading {
                            ProgressView().tint(AppTheme.charcoal)
                        } else {
                            Text(step == totalSteps - 1 ? "Begin" : "Continue")
                        }
                    }
                    .buttonStyle(AppButtonStyle())
                    .disabled(!canContinue || isLoading)
                    .opacity(canContinue ? 1 : 0.5)

                    if step == 0 || step == 3 {
                        Button("Skip") {
                            withAnimation(.easeInOut(duration: 0.3)) { step += 1 }
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.subtleGray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var canContinue: Bool {
        switch step {
        case 0: return true
        case 1: return !selectedAddictions.isEmpty
        case 2: return !reasonForQuitting.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return true
        case 4: return true
        default: return true
        }
    }

    private var nicknameStep: some View {
        VStack(spacing: 16) {
            Text("What should we call you?")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(AppTheme.warmWhite)
                .multilineTextAlignment(.center)

            Text("This is just for you. You can skip this.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtleGray)

            AppTextField(placeholder: "A name or nickname", text: $nickname)
                .padding(.top, 8)
        }
    }

    private var addictionsStep: some View {
        VStack(spacing: 16) {
            Text("What are you here\nto work on?")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(AppTheme.warmWhite)
                .multilineTextAlignment(.center)

            Text("Select all that apply. This stays private.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtleGray)

            VStack(spacing: 12) {
                ForEach(AddictionType.allCases) { type in
                    Button {
                        if selectedAddictions.contains(type) {
                            selectedAddictions.remove(type)
                        } else {
                            selectedAddictions.insert(type)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: type.icon)
                                .font(.title3)
                                .foregroundStyle(selectedAddictions.contains(type) ? AppTheme.terracotta : AppTheme.subtleGray)
                                .frame(width: 28)

                            Text(type.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(AppTheme.warmWhite)

                            Spacer()

                            if selectedAddictions.contains(type) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.terracotta)
                            }
                        }
                        .padding(16)
                        .background(selectedAddictions.contains(type) ? AppTheme.terracotta.opacity(0.12) : AppTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selectedAddictions.contains(type) ? AppTheme.terracotta.opacity(0.4) : Color.clear, lineWidth: 1)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private var reasonStep: some View {
        VStack(spacing: 16) {
            Text("Why do you want to stop?")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(AppTheme.warmWhite)
                .multilineTextAlignment(.center)

            Text("Be honest. This is for you.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtleGray)

            AppTextEditor(placeholder: "Write whatever comes to mind...", text: $reasonForQuitting, minHeight: 120)
                .padding(.top, 8)
        }
    }

    private var whoForStep: some View {
        VStack(spacing: 16) {
            Text("Who are you doing\nthis for?")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(AppTheme.warmWhite)
                .multilineTextAlignment(.center)

            Text("A person, a future version of yourself, anyone. This will be shown to you in hard moments.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtleGray)
                .multilineTextAlignment(.center)

            AppTextField(placeholder: "For my kids, for myself, for...", text: $whoFor)
                .padding(.top, 8)
        }
    }

    private var urgePreviewStep: some View {
        VStack(spacing: 20) {
            Text("How strong is your urge\nright now, today?")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(AppTheme.warmWhite)
                .multilineTextAlignment(.center)

            Text("This is what your daily check-in will look like.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.subtleGray)

            Text("\(Int(initialUrge))")
                .font(.system(size: 56, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.urgeColor(for: Int(initialUrge)))
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: Int(initialUrge))

            Slider(value: $initialUrge, in: 1...10, step: 1)
                .tint(AppTheme.urgeColor(for: Int(initialUrge)))
                .padding(.horizontal, 8)

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
    }

    private func completeOnboarding() async {
        isLoading = true
        errorMessage = nil
        do {
            let addictions = selectedAddictions.map(\.rawValue)
            let dobString: String? = hasSetDOB ? {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: dateOfBirth)
            }() : nil
            try await appState.completeOnboarding(
                nickname: nickname.isEmpty ? nil : nickname,
                dateOfBirth: dobString,
                addictions: addictions,
                reasonForQuitting: reasonForQuitting,
                whoFor: whoFor.isEmpty ? nil : whoFor
            )
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
        isLoading = false
    }
}
