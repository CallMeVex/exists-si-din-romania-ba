import SwiftUI

struct EditInfoView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var reasonForQuitting: String = ""
    @State private var whoFor: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.charcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Edit your support profile")
                                .font(.system(.title3, design: .serif, weight: .semibold))
                                .foregroundStyle(AppTheme.warmWhite)
                            Text("Keep your intention and support focus up to date.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.subtleGray)
                                .lineSpacing(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(AppTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))

                        infoCard

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Why do you want to stop?")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.warmWhite)
                            AppTextEditor(placeholder: "Write your core reason...", text: $reasonForQuitting, minHeight: 110)
                        }
                        .padding(16)
                        .background(AppTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Who are you doing this for?")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.warmWhite)
                            AppTextField(placeholder: "Yourself, family, future self...", text: $whoFor)
                        }
                        .padding(16)
                        .background(AppTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))

                        Button {
                            Task { await save() }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .tint(AppTheme.charcoal)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Save Changes")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.charcoal)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(AppTheme.terracotta)
                        .clipShape(.rect(cornerRadius: 12))
                        .disabled(isSaving)
                        .opacity(isSaving ? 0.75 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit My Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.subtleGray)
                }
            }
            .onAppear {
                reasonForQuitting = appState.currentUser?.reasonForQuitting ?? ""
                whoFor = appState.currentUser?.whoFor ?? ""
            }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Username")
                    .font(.caption)
                    .foregroundStyle(AppTheme.subtleGray)
                Text(appState.currentUser?.username ?? "")
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.warmWhite)
            }

            if let addictions = appState.currentUser?.selectedAddictions, !addictions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recovery Focus")
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleGray)
                    FlowLayout(spacing: 8, centerRows: false) {
                        ForEach(addictions, id: \.self) { addiction in
                            Text(addiction.capitalized)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.warmWhite.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(AppTheme.charcoal.opacity(0.8))
                                .clipShape(.rect(cornerRadius: 14))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 14))
    }

    private func save() async {
        guard let userId = appState.currentUser?.id else { return }
        isSaving = true
        var fields: [String: Any] = [:]
        if !reasonForQuitting.isEmpty { fields["reason_for_quitting"] = reasonForQuitting }
        if !whoFor.isEmpty { fields["who_for"] = whoFor }
        if !fields.isEmpty {
            try? await appState.supabase.updateUser(id: userId, fields: fields)
            appState.currentUser?.reasonForQuitting = reasonForQuitting
            appState.currentUser?.whoFor = whoFor
        }
        isSaving = false
        dismiss()
    }
}
