import SwiftUI

struct JournalView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var responses: [String: String] = [:]
    @State private var freeText = ""
    @State private var isSaving = false
    @State private var saved = false

    private var todayPrompts: [String] {
        let allPrompts = [
            "What triggered you today?",
            "What does this addiction give you?",
            "Who are you doing this for?",
            "What happens after you relapse?",
            "What would your life look like without this?",
            "What are you proud of today, even if it was small?"
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let startIndex = (dayOfYear * 2) % allPrompts.count
        var prompts: [String] = []
        for i in 0..<3 {
            prompts.append(allPrompts[(startIndex + i) % allPrompts.count])
        }
        return prompts
    }

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(AppTheme.subtleGray)
                    }
                    Spacer()
                    Text("Journal")
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
                        Text(todayFormatted)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.subtleGray)

                        ForEach(todayPrompts, id: \.self) { prompt in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(prompt)
                                    .font(.system(.subheadline, design: .serif, weight: .medium))
                                    .foregroundStyle(AppTheme.warmWhite)

                                AppTextEditor(
                                    placeholder: "Take your time...",
                                    text: Binding(
                                        get: { responses[prompt] ?? "" },
                                        set: { responses[prompt] = $0 }
                                    ),
                                    minHeight: 80
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anything else on your mind?")
                                .font(.system(.subheadline, design: .serif, weight: .medium))
                                .foregroundStyle(AppTheme.warmWhite.opacity(0.7))

                            AppTextEditor(placeholder: "Free write...", text: $freeText, minHeight: 100)
                        }

                        Button {
                            Task { await saveEntry() }
                        } label: {
                            if isSaving {
                                ProgressView().tint(AppTheme.charcoal)
                            } else if saved {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark")
                                    Text("Saved")
                                }
                            } else {
                                Text("Save Entry")
                            }
                        }
                        .buttonStyle(AppButtonStyle())
                        .disabled(isSaving || saved)
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func saveEntry() async {
        guard let userId = appState.currentUser?.id else { return }
        isSaving = true
        let filteredResponses = responses.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
        let entry = JournalEntry(
            id: UUID().uuidString,
            userId: userId,
            date: SupabaseService.todayString(),
            promptResponses: filteredResponses.isEmpty ? nil : filteredResponses,
            freeText: freeText.isEmpty ? nil : freeText
        )
        do {
            try await appState.supabase.createJournalEntry(entry)
            saved = true
        } catch {
            // silently fail
        }
        isSaving = false
    }
}
