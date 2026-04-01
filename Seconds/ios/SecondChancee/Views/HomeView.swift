import SwiftUI

private let dailyQuotes: [(quote: String, author: String)] = [
    ("Every moment is a fresh beginning. The only person you are destined to become is the person you decide to be.", "T.S. Eliot"),
    ("You don't have to see the whole staircase, just take the first step.", "Martin Luther King Jr."),
    ("The secret of getting ahead is getting started.", "Mark Twain"),
    ("Courage is not having the strength to go on; it is going on when you don't have the strength.", "Theodore Roosevelt"),
    ("What lies behind us and what lies before us are tiny matters compared to what lies within us.", "Ralph Waldo Emerson"),
    ("Recovery is not a race. You don't have to feel guilty if it takes you longer than you thought.", "Unknown"),
    ("Every day is a new opportunity to change your life.", "Unknown"),
    ("The struggle you're in today is developing the strength you need tomorrow.", "Unknown"),
    ("You are braver than you believe, stronger than you seem, and more capable than you imagine.", "A.A. Milne"),
    ("One day at a time. This is enough. Do not look back and grieve over the past, for it is gone.", "Ida Scott Taylor")
]

struct HomeView: View {
    let appState: AppState
    @Binding var selectedTab: Int
    @State private var showJournal = false
    @State private var showAnalysis = false
    @State private var showRelapse = false
    @State private var showNotifications = false
    @State private var replyNotifications: [ReplyNotificationItem] = []

    private let supabase = SupabaseService()

    private var todayQuote: (quote: String, author: String) {
        let index = abs(SupabaseService.todayString().hashValue) % dailyQuotes.count
        return dailyQuotes[index]
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good evening"
        }
    }

    private var displayName: String {
        appState.currentUser?.nickname ?? appState.currentUser?.username ?? "friend"
    }

    private var notifications: [InAppNotification] {
        var items = replyNotifications.map {
            InAppNotification(
                id: $0.id,
                title: "New reply on your post",
                message: "\($0.username) replied: \($0.preview)",
                icon: "bubble.left.and.bubble.right.fill",
                tint: AppTheme.terracotta,
                createdAt: $0.createdAt
            )
        }
        if appState.primaryStreak > 0 {
            items.append(
                InAppNotification(
                    id: "streak-\(appState.primaryStreak)",
                    title: "Streak update",
                    message: "You are on day \(appState.primaryStreak). Keep the momentum gentle and steady.",
                    icon: "leaf.fill",
                    tint: Color(red: 0.42, green: 0.72, blue: 0.52),
                    createdAt: nil
                )
            )
        }

        if items.isEmpty {
            items.append(
                InAppNotification(
                    id: "empty",
                    title: "All caught up",
                    message: "No new notifications right now.",
                    icon: "checkmark.circle.fill",
                    tint: Color(red: 0.42, green: 0.72, blue: 0.52),
                    createdAt: nil
                )
            )
        }

        return items
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.charcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.cardBackground)
                                    .frame(width: 38, height: 38)
                                Image(systemName: "person.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.subtleGray)
                            }

                            Text("Second Chance")
                                .font(.system(.headline, design: .serif, weight: .semibold))
                                .foregroundStyle(AppTheme.warmWhite)

                            Spacer()

                            Button {
                                showNotifications = true
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell")
                                        .font(.title3)
                                        .foregroundStyle(AppTheme.subtleGray)

                                    if hasUnreadNotifications {
                                        Circle()
                                            .fill(AppTheme.terracotta)
                                            .frame(width: 7, height: 7)
                                            .offset(x: 1, y: -1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(greeting), \(displayName)")
                                .font(.system(.title3, design: .serif))
                                .foregroundStyle(AppTheme.warmWhite.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                        DailyReflectionCard(quote: todayQuote.quote, author: todayQuote.author)
                            .padding(.horizontal, 20)

                        HStack(spacing: 14) {
                            Button {
                                showJournal = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "pencil.line")
                                        .font(.body)
                                        .foregroundStyle(AppTheme.terracotta)
                                    Text("Journal")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AppTheme.warmWhite)
                                    Spacer()
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 20)
                                .background(AppTheme.cardBackground)
                                .clipShape(.rect(cornerRadius: 14))
                            }

                            Button {
                                showAnalysis = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.body)
                                        .foregroundStyle(AppTheme.terracotta)
                                    Text("My Analysis")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AppTheme.warmWhite)
                                    Spacer()
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 20)
                                .background(AppTheme.cardBackground)
                                .clipShape(.rect(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 20)

                        if appState.primaryStreak > 0 {
                            HStack(spacing: 12) {
                                Image(systemName: "leaf.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 0.5))

                                Text("Personal streak")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.warmWhite.opacity(0.8))

                                Spacer()

                                Text("Day \(appState.primaryStreak)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.warmWhite)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.terracotta.opacity(0.75))
                                    .clipShape(.rect(cornerRadius: 20))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(AppTheme.cardBackground)
                            .clipShape(.rect(cornerRadius: 14))
                            .padding(.horizontal, 20)
                        }

                        Button {
                            showRelapse = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.counterclockwise.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.subtleGray)

                                Text("Log a Setback")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.subtleGray)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.subtleGray.opacity(0.5))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(AppTheme.cardBackground.opacity(0.6))
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(AppTheme.subtleGray.opacity(0.2), lineWidth: 1)
                            }
                        }
                        .padding(.horizontal, 20)

                        Button {
                            appState.showEmergencyMode = true
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SUPPORT ACCESS")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(1.5)
                                    .foregroundStyle(AppTheme.subtleGray)

                                Text("Having a hard time right now?")
                                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                                    .foregroundStyle(AppTheme.warmWhite)

                                HStack(spacing: 4) {
                                    Text("Emergency Mode")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(AppTheme.terracotta)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.terracotta)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(AppTheme.cardBackground)
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(AppTheme.terracotta.opacity(0.25), lineWidth: 1)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showJournal) {
                JournalView(appState: appState)
            }
            .fullScreenCover(isPresented: $showAnalysis) {
                AnalysisView(appState: appState)
            }
            .sheet(isPresented: $showRelapse) {
                RelapseFormView(appState: appState) {}
            }
            .fullScreenCover(isPresented: Binding(
                get: { appState.showEmergencyMode },
                set: { appState.showEmergencyMode = $0 }
            )) {
                EmergencyModeView(appState: appState, selectedTab: $selectedTab)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsSheet(notifications: notifications)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await refreshNotifications()
            }
            .onChange(of: showNotifications) { _, isShown in
                if isShown {
                    markNotificationsSeen()
                } else {
                    Task { await refreshNotifications() }
                }
            }
        }
    }

    private var hasUnreadNotifications: Bool {
        guard notifications.first?.id != "empty" else { return false }
        let unreadReplies = replyNotifications.filter { item in
            guard let createdAt = item.createdAt else { return false }
            guard let lastSeen = lastNotificationSeenAt else { return true }
            return createdAt > lastSeen
        }
        return !unreadReplies.isEmpty
    }

    private var lastSeenKey: String {
        let userId = appState.currentUser?.id ?? "guest"
        return "notifications_last_seen_\(userId)"
    }

    private var lastNotificationSeenAt: Date? {
        guard let value = UserDefaults.standard.string(forKey: lastSeenKey) else { return nil }
        return parseISODate(value)
    }

    private func markNotificationsSeen() {
        UserDefaults.standard.set(isoNowString(), forKey: lastSeenKey)
    }

    private func refreshNotifications() async {
        guard let userId = appState.currentUser?.id else { return }
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            supabase.accessToken = token
        }
        supabase.currentUserId = userId
        do {
            let posts = try await supabase.fetchPostsByUser(userId: userId, limit: 50)
            let postIds = posts.map(\.id)
            let replies = try await supabase.fetchRepliesForPostIds(postIds: postIds, limit: 50)
            let filteredReplies = replies.filter { $0.userId != userId }
            replyNotifications = filteredReplies.map {
                ReplyNotificationItem(
                    id: $0.id,
                    username: $0.username ?? "Someone",
                    preview: String($0.content.prefix(90)),
                    createdAt: parseISODate($0.createdAt)
                )
            }
        } catch {
            replyNotifications = []
        }
    }

    private func parseISODate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private func isoNowString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}

private struct InAppNotification: Identifiable {
    let id: String
    let title: String
    let message: String
    let icon: String
    let tint: Color
    let createdAt: Date?
}

private struct ReplyNotificationItem: Identifiable {
    let id: String
    let username: String
    let preview: String
    let createdAt: Date?
}

private struct NotificationsSheet: View {
    let notifications: [InAppNotification]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.charcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(notifications) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(item.tint)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.warmWhite)
                                    Text(item.message)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.subtleGray)
                                        .lineSpacing(2)
                                    if let createdAt = item.createdAt {
                                        Text(relativeTime(createdAt))
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.subtleGray.opacity(0.8))
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(AppTheme.cardBackground)
                            .clipShape(.rect(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.terracotta)
                }
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct DailyReflectionCard: View {
    let quote: String
    let author: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(AppTheme.terracotta)
                .frame(width: 3)
                .clipShape(.rect(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 10) {
                Text("DAILY REFLECTION")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(AppTheme.terracotta)

                Text("\"\(quote)\"")
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundStyle(AppTheme.warmWhite.opacity(0.9))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Text("— \(author)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.subtleGray)
            }
            .padding(.leading, 16)
            .padding(.vertical, 4)
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 14))
    }
}
