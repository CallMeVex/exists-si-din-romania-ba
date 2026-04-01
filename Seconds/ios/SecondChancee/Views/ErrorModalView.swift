import SwiftUI

struct ErrorModalView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.terracotta)
                
                Text("Something Went Wrong")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(AppTheme.warmWhite)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.subtleGray)
                }
            }
            .padding()
            .background(AppTheme.surfaceBackground)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error Message")
                            .font(.caption)
                            .foregroundStyle(AppTheme.subtleGray)
                            .textCase(.uppercase)
                        
                        Text(error.message)
                            .font(.body)
                            .foregroundStyle(AppTheme.warmWhite)
                    }
                    
                    Divider()
                        .background(AppTheme.subtleGray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.caption)
                            .foregroundStyle(AppTheme.subtleGray)
                            .textCase(.uppercase)
                        
                        Text(error.locationString)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(AppTheme.terracotta)
                    }
                    
                    Divider()
                        .background(AppTheme.subtleGray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technical Details")
                            .font(.caption)
                            .foregroundStyle(AppTheme.subtleGray)
                            .textCase(.uppercase)
                        
                        Text(error.detailedDescription)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(AppTheme.subtleGray)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Divider()
                        .background(AppTheme.subtleGray.opacity(0.3))
                    
                    HStack {
                        Text("Time: \(error.timestampString)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.subtleGray.opacity(0.6))
                        
                        Spacer()
                    }
                }
                .padding()
            }
            
            Button {
                onDismiss()
            } label: {
                Text("Dismiss")
                    .font(.system(.subheadline, weight: .medium))
            }
            .buttonStyle(AppButtonStyle())
            .padding()
            .background(AppTheme.surfaceBackground)
        }
        .background(AppTheme.charcoal)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.terracotta.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: 400)
    }
}

struct ErrorModalOverlay: ViewModifier {
    @State private var errorViewModel = ErrorViewModel.shared
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if errorViewModel.isShowingError, let error = errorViewModel.currentError {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                            .onTapGesture {
                                errorViewModel.dismissError()
                            }
                        
                        ErrorModalView(error: error) {
                            errorViewModel.dismissError()
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: errorViewModel.isShowingError)
                }
            }
    }
}

extension View {
    func errorModal() -> some View {
        modifier(ErrorModalOverlay())
    }
}
