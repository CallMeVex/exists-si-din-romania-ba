import SwiftUI

struct ProgressDetailView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var relapseLogs: [RelapseLog] = []
    @State private var recentCheckins: [DailyCheckin] = []
    @State private var showRelapseForm = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            AppTheme.charcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(AppTheme.subtleGray)
                    }
                    Spacer()
                    Text("My Progress")
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
                        if !appState.streaks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Streaks")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.warmWhite)

                                ForEach(appState.streaks, id: \.id) { streak in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(streak.addictionType.capitalized)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(AppTheme.warmWhite)
                                            Text("Day \(streak.currentStreak)")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.subtleGray)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Best: \(streak.longestStreak)")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.terracotta)
                                            Text("Total clean: \(streak.totalCleanDays)")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.subtleGray)
                                        }
                                    }
                                    .padding(14)
                                    .background(AppTheme.cardBackground)
                                    .clipShape(.rect(cornerRadius: 10))
                                }
                            }
                        }

                        if !recentCheckins.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Urge History (30 days)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.warmWhite)

                                UrgeGraphView(checkins: recentCheckins)
                                    .frame(height: 120)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Relapse Log")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.warmWhite)
                                Spacer()
                                Button {
                                    showRelapseForm = true
                                } label: {
                                    Text("Log Setback")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(AppTheme.terracotta)
                                }
                            }

                            Text("Every setback is information, not failure.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.subtleGray)
                                .italic()

                            if relapseLogs.isEmpty {
                                Text("Nothing logged yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.subtleGray)
                                    .padding(.vertical, 8)
                            }

                            ForEach(relapseLogs) { log in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(log.addictionType.capitalized)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(AppTheme.warmWhite)
                                        Spacer()
                                        Text("Urge: \(log.urgeLevelAtTime)")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.urgeColor(for: log.urgeLevelAtTime))
                                    }
                                    if let reflection = log.reflection, !reflection.isEmpty {
                                        Text(reflection)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.subtleGray)
                                            .lineLimit(3)
                                    }
                                }
                                .padding(12)
                                .background(AppTheme.cardBackground)
                                .clipShape(.rect(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $showRelapseForm) {
            RelapseFormView(appState: appState) {
                Task { await loadData() }
            }
        }
    }

    private func loadData() async {
        guard let userId = appState.currentUser?.id else { return }
        isLoading = true
        do {
            relapseLogs = try await appState.supabase.fetchRelapseLogs(userId: userId)
            recentCheckins = try await appState.supabase.fetchRecentCheckins(userId: userId, limit: 30)
        } catch {
            // silently fail
        }
        isLoading = false
    }
}

struct UrgeGraphView: View {
    let checkins: [DailyCheckin]

    var body: some View {
        GeometryReader { geo in
            let sorted = checkins.sorted { $0.date < $1.date }
            let width = geo.size.width
            let height = geo.size.height
            let count = sorted.count
            guard count > 1 else { return AnyView(EmptyView()) }

            let stepX = width / CGFloat(count - 1)

            return AnyView(
                ZStack {
                    Path { path in
                        for (index, checkin) in sorted.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(checkin.urgeLevel) / 10.0 * height)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppTheme.terracotta.opacity(0.7), lineWidth: 2)

                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, checkin in
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(checkin.urgeLevel) / 10.0 * height)
                        Circle()
                            .fill(AppTheme.urgeColor(for: checkin.urgeLevel))
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
            )
        }
        .background(AppTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 10))
    }
}
