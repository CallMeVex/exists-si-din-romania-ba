import SwiftUI
import RevenueCat

@Observable
class AppState {
    var isAuthenticated = false
    var needsOnboarding = false
    var currentUser: AppUser?
    var hasCheckedInToday = false
    var todayCheckin: DailyCheckin?
    var streaks: [StreakTracker] = []
    var isLoading = false
    var errorMessage: String?
    var showEmergencyMode = false
    var navigateToAIFromUrge = false
    var urgePreloadMessage: String?

    var aiCompanionName: String {
        get { UserDefaults.standard.string(forKey: "ai_companion_name") ?? "Joy" }
        set { UserDefaults.standard.set(newValue, forKey: "ai_companion_name") }
    }

    var dailyCheckinReminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "daily_checkin_reminder_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "daily_checkin_reminder_enabled") }
    }

    var communityAlertsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "community_alerts_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "community_alerts_enabled") }
    }

    var weeklySummaryEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "weekly_summary_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "weekly_summary_enabled") }
    }

    var biometricLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometric_lock_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometric_lock_enabled") }
    }

    var incognitoModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "incognito_mode_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "incognito_mode_enabled") }
    }

    let supabase = SupabaseService()
    let openAI = OpenAIService()
    let localStorage = LocalStorageService()

    func checkAuth() async {
        if let savedToken = UserDefaults.standard.string(forKey: "access_token"),
           let savedUserId = UserDefaults.standard.string(forKey: "user_id") {
            supabase.accessToken = savedToken
            supabase.currentUserId = savedUserId
            do {
                if let user = try await supabase.fetchUser(id: savedUserId) {
                    currentUser = user

                    // Re-identify in RC on every app launch
                    try? await Purchases.shared.logIn(savedUserId)

                    isAuthenticated = true
                    needsOnboarding = !user.onboardingComplete
                    await checkTodayCheckin()
                    await fetchStreaks()
                } else {
                    signOut()
                }
            } catch {
                ErrorViewModel.shared.showError(error)
                signOut()
            }
        }
    }

    func signUp(email: String, password: String, username: String) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            let authResponse = try await supabase.signUp(email: email, password: password)
            saveTokens()

            // Identify user in RC immediately on sign up
            try? await Purchases.shared.logIn(authResponse.user.id)

            let user = AppUser(
                id: authResponse.user.id,
                username: username,
                selectedAddictions: [],
                isMentor: false,
                mentorApproved: false,
                onboardingComplete: false
            )
            try await supabase.createUser(user)
            currentUser = user
            isAuthenticated = true
            needsOnboarding = true
        } catch {
            ErrorViewModel.shared.showError(error)
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            let authResponse = try await supabase.signIn(email: email, password: password)
            saveTokens()
            if let user = try await supabase.fetchUser(id: authResponse.user.id) {
                currentUser = user
                isAuthenticated = true
                needsOnboarding = !user.onboardingComplete

                // Tell RC who this user is — ties subscription to Supabase ID
                try? await Purchases.shared.logIn(authResponse.user.id)

                await checkTodayCheckin()
                await fetchStreaks()
            }
        } catch {
            ErrorViewModel.shared.showError(error)
            throw error
        }
    }

    func signOut() {
        Task { try? await Purchases.shared.logOut() }
        supabase.signOut()
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "user_id")
        isAuthenticated = false
        currentUser = nil
        hasCheckedInToday = false
        todayCheckin = nil
        streaks = []
    }

    func completeOnboarding(nickname: String?, dateOfBirth: String?, addictions: [String], reasonForQuitting: String, whoFor: String?) async throws {
        guard let userId = currentUser?.id else { return }
        var fields: [String: Any] = [
            "selected_addictions": addictions,
            "reason_for_quitting": reasonForQuitting,
            "onboarding_complete": true,
            "join_date": SupabaseService.todayString()
        ]
        if let nickname, !nickname.isEmpty { fields["nickname"] = nickname }
        if let dateOfBirth, !dateOfBirth.isEmpty { fields["date_of_birth"] = dateOfBirth }
        if let whoFor, !whoFor.isEmpty { fields["who_for"] = whoFor }
        try await supabase.updateUser(id: userId, fields: fields)

        for addiction in addictions {
            let streak = StreakTracker(
                id: UUID().uuidString,
                userId: userId,
                addictionType: addiction,
                currentStreak: 0,
                longestStreak: 0,
                totalCleanDays: 0,
                relapseCount: 0
            )
            try await supabase.upsertStreak(streak)
        }

        currentUser?.nickname = nickname
        currentUser?.dateOfBirth = dateOfBirth
        currentUser?.selectedAddictions = addictions
        currentUser?.reasonForQuitting = reasonForQuitting
        currentUser?.whoFor = whoFor
        currentUser?.onboardingComplete = true
        needsOnboarding = false
        await fetchStreaks()
    }

    func submitCheckin(urgeLevel: Int, urgeReason: String?, mood: Int?) async throws {
        guard let userId = currentUser?.id else { return }
        let checkin = DailyCheckin(
            id: UUID().uuidString,
            userId: userId,
            date: SupabaseService.todayString(),
            urgeLevel: urgeLevel,
            urgeReason: urgeReason,
            mood: mood
        )
        try await supabase.createCheckin(checkin)
        todayCheckin = checkin
        hasCheckedInToday = true

        for var streak in streaks {
            streak.currentStreak += 1
            streak.totalCleanDays += 1
            if streak.currentStreak > streak.longestStreak {
                streak.longestStreak = streak.currentStreak
            }
            streak.lastCheckinDate = SupabaseService.todayString()
            try await supabase.updateStreak(id: streak.id, fields: [
                "current_streak": streak.currentStreak,
                "total_clean_days": streak.totalCleanDays,
                "longest_streak": streak.longestStreak,
                "last_checkin_date": streak.lastCheckinDate as Any
            ])
        }
        await fetchStreaks()

        if urgeLevel >= 8 {
            showEmergencyMode = true
        }

        if urgeLevel >= 6 {
            navigateToAIFromUrge = true
            urgePreloadMessage = "I can see today is a tough one. You don't have to explain everything right now — I'm here. What's going on?"
        }
    }

    func logRelapse(addictionType: String, urgeLevel: Int, reflection: String?) async throws {
        guard let userId = currentUser?.id else { return }
        let log = RelapseLog(
            id: UUID().uuidString,
            userId: userId,
            addictionType: addictionType,
            reflection: reflection,
            urgeLevelAtTime: urgeLevel
        )
        try await supabase.createRelapseLog(log)

        if let index = streaks.firstIndex(where: { $0.addictionType == addictionType }) {
            let streakId = streaks[index].id
            try await supabase.updateStreak(id: streakId, fields: [
                "current_streak": 0,
                "relapse_count": streaks[index].relapseCount + 1
            ])
        }
        await fetchStreaks()

        navigateToAIFromUrge = true
        urgePreloadMessage = "You logged a setback. That took honesty. I'm here — do you want to talk about what happened?"
    }

    func checkTodayCheckin() async {
        guard let userId = currentUser?.id else { return }
        do {
            if let checkin = try await supabase.fetchTodayCheckin(userId: userId) {
                todayCheckin = checkin
                hasCheckedInToday = true
            } else {
                hasCheckedInToday = false
                todayCheckin = nil
            }
        } catch {
            hasCheckedInToday = false
        }
    }

    func fetchStreaks() async {
        guard let userId = currentUser?.id else { return }
        do {
            streaks = try await supabase.fetchStreaks(userId: userId)
        } catch {
            // silently fail
        }
    }

    func deleteAllData() async throws {
        guard let userId = currentUser?.id else { return }
        try await supabase.deleteUserData(userId: userId)
        localStorage.clearAll()
        signOut()
    }

    func clearLocalCache() {
        localStorage.clearAll()
    }

    func updateEmail(_ email: String) async throws {
        try await supabase.updateAuthUser(fields: ["email": email])
    }

    func updatePassword(_ password: String) async throws {
        try await supabase.updateAuthUser(fields: ["password": password])
    }

    private func saveTokens() {
        if let token = supabase.accessToken {
            UserDefaults.standard.set(token, forKey: "access_token")
        }
        if let userId = supabase.currentUserId {
            UserDefaults.standard.set(userId, forKey: "user_id")
        }
    }

    var primaryStreak: Int {
        streaks.first?.currentStreak ?? 0
    }

    var motivationalMessage: String {
        let name = currentUser?.nickname ?? currentUser?.username ?? "friend"
        let whoFor = currentUser?.whoFor
        let reason = currentUser?.reasonForQuitting
        let days = primaryStreak

        let messages: [String] = [
            "You're still here, \(name). That matters more than you know.",
            days > 0 ? "Day \(days). Each one is a quiet act of courage." : "Today is a new beginning. You chose to show up.",
            whoFor != nil ? "Remember who you're doing this for — \(whoFor!)." : "You're doing this for yourself. That's enough.",
            reason != nil ? "You said you wanted to stop because \"\(reason!)\". Hold onto that." : "Your reasons are valid, even on hard days.",
            "Progress isn't a straight line. You're still moving forward.",
            "The version of you that started this journey would be proud of where you are now."
        ]
        return messages[abs(SupabaseService.todayString().hashValue) % messages.count]
    }
}