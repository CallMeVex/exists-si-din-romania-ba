import SwiftUI

struct ProfileView: View {
    let appState: AppState
    @State private var showProgress = false
    @State private var showResources = false
    @State private var showSettings = false
    @State private var showMentorApp = false
    @State private var showEditInfo = false
    @State private var expandedProgress = false
    @State private var expandedResources = false
    @State private var expandedSupporter = false
    @State private var expandedSettings = false

    private var totalCleanDays: Int {
        appState.streaks.reduce(0) { $0 + $1.totalCleanDays }
    }

    private var memberSinceText: String {
        guard let joinDate = appState.currentUser?.joinDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: joinDate) {
            let display = DateFormatter()
            display.dateFormat = "MMMM yyyy"
            return "Member since \(display.string(from: date))"
        }
        return "Member since \(joinDate)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.charcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 14) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(AppTheme.terracotta.opacity(0.25))
                                    .frame(width: 90, height: 90)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(AppTheme.terracotta.opacity(0.7))
                                    }

                                if appState.currentUser?.isMentor == true {
                                    Circle()
                                        .fill(AppTheme.charcoal)
                                        .frame(width: 26, height: 26)
                                        .overlay {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(AppTheme.terracotta)
                                        }
                                        .offset(x: 2, y: 2)
                                }
                            }

                            VStack(spacing: 5) {
                                Text(appState.currentUser?.nickname ?? appState.currentUser?.username ?? "")
                                    .font(.system(.title2, design: .serif, weight: .semibold))
                                    .italic()
                                    .foregroundStyle(AppTheme.terracotta)

                                HStack(spacing: 6) {
                                    if !memberSinceText.isEmpty {
                                        Text(memberSinceText)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.subtleGray)
                                    }
                                    if totalCleanDays > 0 {
                                        if !memberSinceText.isEmpty {
                                            Text("•")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.subtleGray)
                                        }
                                        Text("\(totalCleanDays) Days Clean")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.subtleGray)
                                    }
                                }
                            }

                            if let addictions = appState.currentUser?.selectedAddictions, !addictions.isEmpty {
                                FlowLayout(spacing: 8, centerRows: true) {
                                    ForEach(addictions, id: \.self) { addiction in
                                        Text(addiction.capitalized + " Recovery")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(AppTheme.warmWhite.opacity(0.8))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(AppTheme.cardBackground)
                                            .clipShape(.rect(cornerRadius: 20))
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.top, 24)

                        VStack(spacing: 10) {
                            ProfileAccordion(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "My Progress",
                                isExpanded: $expandedProgress
                            ) {
                                VStack(spacing: 10) {
                                    ForEach(appState.streaks, id: \.id) { streak in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(streak.addictionType.capitalized)
                                                    .font(.subheadline.weight(.medium))
                                                    .foregroundStyle(AppTheme.warmWhite)
                                                Text("Day \(streak.currentStreak)")
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.subtleGray)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 3) {
                                                Text("Best: \(streak.longestStreak)d")
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.terracotta)
                                                Text("\(streak.totalCleanDays) total")
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.subtleGray)
                                            }
                                        }
                                        .padding(12)
                                        .background(AppTheme.charcoal.opacity(0.5))
                                        .clipShape(.rect(cornerRadius: 10))
                                    }

                                    Button {
                                        showProgress = true
                                    } label: {
                                        Text("View full progress →")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppTheme.terracotta)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.top, 4)
                                    }
                                }
                            }

                            ProfileAccordion(
                                icon: "books.vertical.fill",
                                title: "Resources",
                                isExpanded: $expandedResources
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("These are real people and organizations who can help. The AI in this app is not a substitute for professional support.")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.subtleGray)
                                        .lineSpacing(3)
                                        .padding(.bottom, 4)

                                    ResourceLink(title: "AA — Alcoholics Anonymous", url: "https://aa.org")
                                    ResourceLink(title: "NA — Narcotics Anonymous", url: "https://na.org")
                                    ResourceLink(title: "SMART Recovery", url: "https://smartrecovery.org")
                                    ResourceLink(title: "GamCare (Gambling)", url: "https://gamcare.org.uk")
                                    ResourceLink(title: "SAA (Sexual Compulsivity)", url: "https://saa.org")
                                    ResourceLink(title: "Crisis Helplines Worldwide", url: "https://findahelpline.com")
                                    ResourceLink(title: "Smokefree.gov (Nicotine)", url: "https://smokefree.gov")
                                }
                            }

                            ProfileAccordion(
                                icon: "hands.and.sparkles.fill",
                                title: "Become a Supporter",
                                isExpanded: $expandedSupporter
                            ) {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("If you've been walking this road and want to support others just starting out, you can apply. Your story — not a title or a number — is what qualifies you.")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.subtleGray)
                                        .lineSpacing(3)

                                    Button {
                                        showMentorApp = true
                                    } label: {
                                        Text("Apply to Support Others")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.charcoal)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(AppTheme.terracotta)
                                            .clipShape(.rect(cornerRadius: 10))
                                    }
                                }
                            }

                            ProfileAccordion(
                                icon: "gearshape.fill",
                                title: "Settings",
                                isExpanded: $expandedSettings
                            ) {
                                VStack(spacing: 8) {
                                    Button {
                                        showEditInfo = true
                                    } label: {
                                        SettingsRow(icon: "person.fill", title: "Edit My Info")
                                    }

                                    Button {
                                        showSettings = true
                                    } label: {
                                        SettingsRow(icon: "slider.horizontal.3", title: "App Settings")
                                    }

                                    Button {
                                        appState.signOut()
                                    } label: {
                                        SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", destructive: false)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showProgress) {
                ProgressDetailView(appState: appState)
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(appState: appState)
            }
            .fullScreenCover(isPresented: $showMentorApp) {
                MentorApplicationView(appState: appState)
            }
            .sheet(isPresented: $showEditInfo) {
                EditInfoView(appState: appState)
            }
        }
    }
}

struct ProfileAccordion<Content: View>: View {
    let icon: String
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.terracotta.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.terracotta)
                    }

                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.warmWhite)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AppTheme.subtleGray)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }

            if isExpanded {
                Divider()
                    .background(AppTheme.subtleGray.opacity(0.2))
                    .padding(.horizontal, 16)

                content
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 14))
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var destructive: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(destructive ? .red.opacity(0.8) : AppTheme.subtleGray)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(destructive ? .red.opacity(0.8) : AppTheme.warmWhite.opacity(0.85))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(AppTheme.subtleGray.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(AppTheme.charcoal.opacity(0.5))
        .clipShape(.rect(cornerRadius: 10))
    }
}

struct ResourceLink: View {
    let title: String
    let url: String

    var body: some View {
        if let urlObj = URL(string: url) {
            Link(destination: urlObj) {
                HStack(spacing: 10) {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(AppTheme.terracotta.opacity(0.8))
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.warmWhite.opacity(0.85))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.subtleGray.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.charcoal.opacity(0.5))
                .clipShape(.rect(cornerRadius: 10))
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var centerRows: Bool = false

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[(LayoutSubview, CGSize)]] = []
        var currentRow: [(LayoutSubview, CGSize)] = []
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let projectedWidth = currentRow.isEmpty ? size.width : currentRowWidth + spacing + size.width

            if projectedWidth > bounds.width, !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [(subview, size)]
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRow.append((subview, size))
                currentRowWidth = projectedWidth
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        var rowY: CGFloat = bounds.minY

        for row in rows {
            let rowWidth = row.reduce(CGFloat(0)) { $0 + $1.1.width } + CGFloat(max(0, row.count - 1)) * spacing
            let rowHeight = row.reduce(CGFloat(0)) { max($0, $1.1.height) }
            var rowX = bounds.minX

            if centerRows {
                rowX = bounds.minX + max(0, (bounds.width - rowWidth) / 2)
            }

            for (subview, size) in row {
                subview.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(size))
                rowX += size.width + spacing
            }

            rowY += rowHeight + spacing
        }
    }
}
