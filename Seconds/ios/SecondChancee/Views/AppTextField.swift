import SwiftUI

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppTheme.subtleGray))
            .font(.body)
            .foregroundStyle(AppTheme.warmWhite)
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(.rect(cornerRadius: 10))
    }
}

struct AppSecureField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppTheme.subtleGray))
            .font(.body)
            .foregroundStyle(AppTheme.warmWhite)
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(.rect(cornerRadius: 10))
    }
}

struct AppTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(AppTheme.subtleGray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
            TextEditor(text: $text)
                .font(.body)
                .foregroundStyle(AppTheme.warmWhite)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: minHeight)
        }
        .background(AppTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 10))
    }
}
