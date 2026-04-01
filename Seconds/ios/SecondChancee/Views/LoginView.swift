import SwiftUI

struct LoginView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private enum Field {
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
                    Text("Welcome back")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(AppTheme.warmWhite)

                    Text("Pick up where you left off.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.subtleGray)
                }

                VStack(spacing: 16) {
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
                        .onSubmit { Task { await logIn() } }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await logIn() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.charcoal)
                    } else {
                        Text("Log In")
                    }
                }
                .buttonStyle(AppButtonStyle())
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }

    private func logIn() async {
        guard !email.isEmpty, !password.isEmpty, !isLoading else { return }
        focusedField = nil
        isLoading = true
        errorMessage = nil
        do {
            try await appState.signIn(email: email, password: password)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
