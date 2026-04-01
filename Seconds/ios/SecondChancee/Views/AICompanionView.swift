import SwiftUI

struct AICompanionView: View {
    let appState: AppState
    @State private var viewModel = ChatViewModel()
    @State private var hasLoaded = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.terracotta.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Text(String(appState.aiCompanionName.prefix(1)))
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(AppTheme.terracotta)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(appState.aiCompanionName)
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(AppTheme.warmWhite)
                        Text("Recovery Companion")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.subtleGray)
                    }

                    Spacer()

                    Circle()
                        .fill(Color(red: 0.3, green: 0.72, blue: 0.44))
                        .frame(width: 7, height: 7)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                Divider()
                    .background(AppTheme.cardBackground)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isTyping {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .id("typing")
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            if viewModel.isTyping {
                                proxy.scrollTo("typing", anchor: .bottom)
                            } else if let last = viewModel.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) { _, isTyping in
                        if isTyping {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider().background(AppTheme.cardBackground)

                HStack(spacing: 12) {
                    TextField("", text: $viewModel.inputText, prompt: Text("Write something...").foregroundStyle(AppTheme.subtleGray), axis: .vertical)
                        .font(.body)
                        .foregroundStyle(AppTheme.warmWhite)
                        .focused($isInputFocused)
                        .lineLimit(1...4)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 20))

                    Button {
                        Task { await viewModel.sendMessage(appState: appState) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.subtleGray : AppTheme.terracotta)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.surfaceBackground)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
            }
        }
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                let preload = appState.urgePreloadMessage
                viewModel.loadWithContext(appState: appState, preloadMessage: preload)
                appState.urgePreloadMessage = nil
            }
        }
        .onChange(of: appState.urgePreloadMessage) { _, newMessage in
            if let newMessage {
                viewModel.loadWithContext(appState: appState, preloadMessage: newMessage)
                appState.urgePreloadMessage = nil
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                Circle()
                    .fill(AppTheme.terracotta.opacity(0.18))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.terracotta)
                    }
            }

            Text(message.content)
                .font(.body)
                .foregroundStyle(isUser ? AppTheme.charcoal : AppTheme.warmWhite.opacity(0.92))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isUser ? AppTheme.terracotta : AppTheme.cardBackground)
                .clipShape(.rect(cornerRadius: 18, style: .continuous))

            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 16)
    }
}

struct TypingIndicator: View {
    @State private var dotPhase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AppTheme.subtleGray)
                    .frame(width: 6, height: 6)
                    .opacity(dotPhase == index ? 1 : 0.3)
                    .scaleEffect(dotPhase == index ? 1.2 : 1)
                    .animation(.easeInOut(duration: 0.3), value: dotPhase)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 18, style: .continuous))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotPhase = (dotPhase + 1) % 3
            }
        }
    }
}
