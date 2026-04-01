import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var companionName: String = ""
    @State private var showEditInfo = false
    @State private var showEmailPrompt = false
    @State private var showPasswordPrompt = false
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var settingsMessage: String?

    @State private var dailyReminder = false
    @State private var communityAlerts = true
    @State private var weeklySummary = false
    @State private var biometricLock = false
    @State private var incognitoMode = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 18) {
                        aiCompanionSection
                        accountSection
                        notificationsSection
                        privacySection
                        dataSection
                        aboutSection

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "trash")
                                Text("Delete All My Data")
                                Spacer()
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red.opacity(0.85))
                            .padding(15)
                            .background(Color.red.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
            }
        }
        .sheet(isPresented: $showEditInfo) {
            EditInfoView(appState: appState)
        }
        .onAppear {
            companionName = appState.aiCompanionName == "Joy" ? "" : appState.aiCompanionName
            dailyReminder = appState.dailyCheckinReminderEnabled
            communityAlerts = appState.communityAlertsEnabled
            weeklySummary = appState.weeklySummaryEnabled
            biometricLock = appState.biometricLockEnabled
            incognitoMode = appState.incognitoModeEnabled
        }
        .onChange(of: companionName) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            appState.aiCompanionName = trimmed.isEmpty ? "Joy" : trimmed
        }
        .onChange(of: dailyReminder) { _, newValue in
            appState.dailyCheckinReminderEnabled = newValue
        }
        .onChange(of: communityAlerts) { _, newValue in
            appState.communityAlertsEnabled = newValue
        }
        .onChange(of: weeklySummary) { _, newValue in
            appState.weeklySummaryEnabled = newValue
        }
        .onChange(of: incognitoMode) { _, newValue in
            appState.incognitoModeEnabled = newValue
        }
        .onChange(of: biometricLock) { _, newValue in
            guard newValue else {
                appState.biometricLockEnabled = false
                return
            }
            enableBiometricLock()
        }
        .alert("Change Email", isPresented: $showEmailPrompt) {
            TextField("name@example.com", text: $newEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Save") {
                Task {
                    let trimmed = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    do {
                        try await appState.updateEmail(trimmed)
                        settingsMessage = "Email update requested. Check your inbox for confirmation."
                        newEmail = ""
                    } catch {
                        settingsMessage = error.localizedDescription
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your new email address.")
        }
        .alert("Change Password", isPresented: $showPasswordPrompt) {
            SecureField("New password", text: $newPassword)
            Button("Save") {
                Task {
                    let trimmed = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.count >= 6 else {
                        settingsMessage = "Password must be at least 6 characters."
                        return
                    }
                    do {
                        try await appState.updatePassword(trimmed)
                        settingsMessage = "Password updated successfully."
                        newPassword = ""
                    } catch {
                        settingsMessage = error.localizedDescription
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose a stronger password for your account.")
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirm) {
            Button("Delete Everything", role: .destructive) {
                Task {
                    try? await appState.deleteAllData()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all your data from our servers and this device. This cannot be undone.")
        }
        .alert("Settings", isPresented: Binding(
            get: { settingsMessage != nil },
            set: { newValue in if !newValue { settingsMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(settingsMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(AppTheme.terracotta)
            }
            Spacer()
            Text("Settings")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(AppTheme.warmWhite)
            Spacer()
            Color.clear.frame(width: 20, height: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private var aiCompanionSection: some View {
        section("AI COMPANION") {
            VStack(spacing: 12) {
                TextField("", text: $companionName, prompt: Text("Joy").foregroundStyle(AppTheme.subtleGray))
                    .font(.body)
                    .foregroundStyle(AppTheme.warmWhite)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppTheme.charcoal.opacity(0.6))
                    .clipShape(.rect(cornerRadius: 10))

                Text("Name updates in real time in your chat screen.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.subtleGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var accountSection: some View {
        section("ACCOUNT") {
            VStack(spacing: 2) {
                actionRow(icon: "person.crop.circle", title: "Profile Info") { showEditInfo = true }
                actionRow(icon: "envelope", title: "Change Email") { showEmailPrompt = true }
                actionRow(icon: "lock", title: "Change Password") { showPasswordPrompt = true }
                actionRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out") {
                    appState.signOut()
                    dismiss()
                }
            }
        }
    }

    private var notificationsSection: some View {
        section("NOTIFICATIONS") {
            VStack(spacing: 2) {
                toggleRow(icon: "alarm", title: "Daily Check-in Reminder", isOn: $dailyReminder)
                toggleRow(icon: "person.3", title: "Community Alerts", isOn: $communityAlerts)
                toggleRow(icon: "chart.bar", title: "Weekly Summary", isOn: $weeklySummary)
            }
        }
    }

    private var privacySection: some View {
        section("PRIVACY & SECURITY") {
            VStack(spacing: 2) {
                toggleRow(icon: "faceid", title: "Biometric Lock", isOn: $biometricLock)
                toggleRow(icon: "eye.slash", title: "Incognito Mode", isOn: $incognitoMode)
            }
        }
    }

    private var dataSection: some View {
        section("DATA") {
            VStack(spacing: 2) {
                actionRow(icon: "trash", title: "Clear Local Cache") {
                    appState.clearLocalCache()
                    settingsMessage = "Local cache cleared."
                }
            }
        }
    }

    private var aboutSection: some View {
        section("ABOUT") {
            VStack(spacing: 2) {
                valueRow(icon: "info.circle", title: "Version", value: appVersion)
                externalLinkRow(icon: "doc.text", title: "Terms of Service", url: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
                externalLinkRow(icon: "hand.raised", title: "Privacy Policy", url: "https://www.apple.com/legal/privacy/")
                externalLinkRow(icon: "questionmark.circle", title: "Support Contact", url: "mailto:support@secondchance.app")
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(AppTheme.subtleGray)
                .padding(.horizontal, 4)
            content()
                .padding(4)
                .background(AppTheme.cardBackground)
                .clipShape(.rect(cornerRadius: 14))
        }
    }

    private func actionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.terracotta.opacity(0.85))
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.warmWhite)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.subtleGray.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(AppTheme.charcoal.opacity(0.45))
            .clipShape(.rect(cornerRadius: 10))
        }
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.terracotta.opacity(0.85))
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.warmWhite)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.terracotta)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.charcoal.opacity(0.45))
        .clipShape(.rect(cornerRadius: 10))
    }

    private func valueRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.terracotta.opacity(0.85))
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.warmWhite)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(AppTheme.subtleGray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(AppTheme.charcoal.opacity(0.45))
        .clipShape(.rect(cornerRadius: 10))
    }

    private func externalLinkRow(icon: String, title: String, url: String) -> some View {
        Group {
            if let targetURL = URL(string: url) {
                Link(destination: targetURL) {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .foregroundStyle(AppTheme.terracotta.opacity(0.85))
                            .frame(width: 20)
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.warmWhite)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.subtleGray.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(AppTheme.charcoal.opacity(0.45))
                    .clipShape(.rect(cornerRadius: 10))
                }
            }
        }
    }

    private func enableBiometricLock() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricLock = false
            appState.biometricLockEnabled = false
            settingsMessage = "Biometric authentication is not available on this device."
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable biometric lock for Second Chance") { success, _ in
            DispatchQueue.main.async {
                if success {
                    appState.biometricLockEnabled = true
                } else {
                    biometricLock = false
                    appState.biometricLockEnabled = false
                    settingsMessage = "Biometric verification failed."
                }
            }
        }
    }
}
