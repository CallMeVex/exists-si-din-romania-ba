import SwiftUI

struct SignUpView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private enum Field {
        case username
        case email
        case password
    }

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(AppTheme.subtleGray)
                    }
                    Spacer()
                }

                VStack(spacing: 8) {
                    Text("Create your account")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(AppTheme.warmWhite)

                    Text("Everything stays private.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.subtleGray)
                }

                VStack(spacing: 16) {
                    AppTextField(placeholder: "Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }

                    AppTextField(placeholder: "Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    AppSecureField(placeholder: "Password", text: $password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await signUp() } }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await signUp() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.charcoal)
                    } else {
                        Text("Create Account")
                    }
                }
                .buttonStyle(AppButtonStyle())
                .disabled(username.isEmpty || email.isEmpty || password.count < 6 || isLoading)
                .opacity(username.isEmpty || email.isEmpty || password.count < 6 ? 0.5 : 1)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }

    private func signUp() async {
        guard !username.isEmpty, !email.isEmpty, password.count >= 6, !isLoading else { return }
        focusedField = nil
        isLoading = true
        errorMessage = nil
        do {
            try await appState.signUp(email: email, password: password, username: username)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
