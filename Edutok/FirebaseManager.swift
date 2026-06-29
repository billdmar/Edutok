/// FirebaseManager.swift
///
/// Single entry point for authentication and Firestore persistence. Configures
/// Firebase once at init, listens for auth state changes, and loads-or-creates the
/// signed-in user's profile document. Also tracks daily activity stats (cards flipped,
/// topics explored, streaks) and maintains the per-day leaderboards. All Firestore
/// writes are best-effort (`try?`) so transient backend failures never crash the app;
/// a local fallback user is created if the profile can't be loaded.
import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

/// Shared, main-actor singleton wrapping Firebase Auth and Firestore for the app.
@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false

    private init() {
        // Configure Firebase
        configureFirebase()
        setupAuthListener()
    }

    private func configureFirebase() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }

    private func setupAuthListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.isAuthenticated = true
                    await self?.loadOrCreateUser(uid: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }

    // MARK: - Authentication Methods

    /// Signs in anonymously and loads or creates the backing user profile.
    func signInAnonymously() async throws {
        let result = try await auth.signInAnonymously()
        await loadOrCreateUser(uid: result.user.uid)
    }

    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        await loadOrCreateUser(uid: result.user.uid)
    }

    func signUp(email: String, password: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        await loadOrCreateUser(uid: result.user.uid)
    }

    func signInWithPhone(phoneNumber: String) async throws -> String {
        // Note: Phone auth requires additional setup in Firebase Console
        // and may not work in simulator
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            return verificationID
        } catch {
            throw error
        }
    }

    func verifyPhoneCode(verificationID: String, verificationCode: String) async throws {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        let result = try await auth.signIn(with: credential)
        await loadOrCreateUser(uid: result.user.uid)
    }

    func signOut() {
        try? auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    /// Permanently deletes the signed-in user: removes their leaderboard entries and
    /// profile document, then deletes the Firebase Auth account. Best-effort on the
    /// Firestore deletes (so a transient failure still lets the account deletion proceed).
    ///
    /// Returns `true` if the auth account was deleted. Deleting an account can fail with
    /// `requiresRecentLogin` if the session is stale; in that case we still sign the user
    /// out (their data is already removed) and return `false` so the UI can say so.
    @discardableResult
    func deleteAccount() async -> Bool {
        guard let user = auth.currentUser else { return false }
        let uid = user.uid
        let dateString = DateFormatter.yyyyMMdd.string(from: Calendar.current.startOfDay(for: Date()))

        // Remove today's leaderboard entries (doc id is "<date>_<uid>").
        try? await db.collection("daily_cards_leaderboard").document("\(dateString)_\(uid)").delete()
        try? await db.collection("daily_topics_leaderboard").document("\(dateString)_\(uid)").delete()

        // Remove the profile document.
        try? await db.collection("users").document(uid).delete()

        // Delete the auth account.
        var deleted = false
        do {
            try await user.delete()
            deleted = true
        } catch {
            #if DEBUG
            print("Account deletion failed (will sign out instead): \(error)")
            #endif
            // Data is already gone; sign out so the user isn't stranded mid-deletion.
            try? auth.signOut()
        }

        currentUser = nil
        isAuthenticated = false
        return deleted
    }

    func updateUsername(_ newUsername: String) async {
        guard var user = currentUser else { return }

        // Cap username length before persisting to keep stored/leaderboard values bounded.
        user.username = String(newUsername.prefix(30))
        currentUser = user

        // Save to Firestore
        try? await saveUser(user)
    }

    // MARK: - User Management

    /// Loads the Firestore profile for `uid`, creating a new one if absent. On any
    /// error, falls back to an in-memory user so the app remains usable offline.
    private func loadOrCreateUser(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()

            if document.exists {
                // Load existing user
                let data = document.data() ?? [:]
                currentUser = AppUser(
                    id: uid,
                    username: data["username"] as? String ?? generateRandomUsername(),
                    totalCardsFlipped: data["totalCardsFlipped"] as? Int ?? 0,
                    totalTopicsExplored: data["totalTopicsExplored"] as? Int ?? 0,
                    currentStreak: data["currentStreak"] as? Int ?? 0,
                    longestStreak: data["longestStreak"] as? Int ?? 0,
                    lastActiveDate: (data["lastActiveDate"] as? Timestamp)?.dateValue() ?? Date(),
                    joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
                    dailyStats: loadDailyStats(from: data["dailyStats"] as? [[String: Any]] ?? [])
                )
            } else {
                // Create new user
                let newUser = AppUser(
                    id: uid,
                    username: generateRandomUsername(),
                    totalCardsFlipped: 0,
                    totalTopicsExplored: 0,
                    currentStreak: 0,
                    longestStreak: 0,
                    lastActiveDate: Date(),
                    joinDate: Date(),
                    dailyStats: []
                )

                try await saveUser(newUser)
                currentUser = newUser
            }
        } catch {
            AppLog.error("Error loading/creating user: \(error)", category: .auth)

            // Create a local user if database fails
            currentUser = AppUser(
                id: uid,
                username: generateRandomUsername(),
                totalCardsFlipped: 0,
                totalTopicsExplored: 0,
                currentStreak: 0,
                longestStreak: 0,
                lastActiveDate: Date(),
                joinDate: Date(),
                dailyStats: []
            )
        }
    }

    private func loadDailyStats(from data: [[String: Any]]) -> [DailyStat] {
        return data.compactMap { dict in
            guard let dateTimestamp = dict["date"] as? Timestamp,
                  let cardsFlipped = dict["cardsFlipped"] as? Int,
                  let topicsExplored = dict["topicsExplored"] as? Int else {
                return nil
            }

            return DailyStat(
                date: dateTimestamp.dateValue(),
                cardsFlipped: cardsFlipped,
                topicsExplored: topicsExplored,
                achievements: dict["achievements"] as? [String] ?? []
            )
        }
    }

    private func saveUser(_ user: AppUser) async throws {
        let userData: [String: Any] = [
            "username": user.username,
            "totalCardsFlipped": user.totalCardsFlipped,
            "totalTopicsExplored": user.totalTopicsExplored,
            "currentStreak": user.currentStreak,
            "longestStreak": user.longestStreak,
            "lastActiveDate": Timestamp(date: user.lastActiveDate),
            "joinDate": Timestamp(date: user.joinDate),
            "dailyStats": user.dailyStats.map { stat in
                [
                    "date": Timestamp(date: stat.date),
                    "cardsFlipped": stat.cardsFlipped,
                    "topicsExplored": stat.topicsExplored,
                    "achievements": stat.achievements
                ]
            }
        ]

        try await db.collection("users").document(user.id).setData(userData)
    }

    // MARK: - Daily Stats Tracking

    /// Records one card flip: bumps totals and today's daily stat, refreshes the
    /// streak, persists the user, and updates the cards-flipped leaderboard.
    func trackCardFlipped() async {
        guard var user = currentUser else { return }

        let today = Calendar.current.startOfDay(for: Date())

        // Update total
        user.totalCardsFlipped += 1

        // Update or create daily stat
        if let todayIndex = user.dailyStats.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            user.dailyStats[todayIndex].cardsFlipped += 1
        } else {
            let newDailyStat = DailyStat(
                date: today,
                cardsFlipped: 1,
                topicsExplored: 0,
                achievements: []
            )
            user.dailyStats.append(newDailyStat)
        }

        // Update streak
        updateStreak(for: &user)

        currentUser = user
        try? await saveUser(user)

        // Update leaderboard
        await updateDailyLeaderboard(user: user, type: .cardsFlipped)
    }

    func trackTopicExplored() async {
        guard var user = currentUser else { return }

        let today = Calendar.current.startOfDay(for: Date())

        // Update total
        user.totalTopicsExplored += 1

        // Update or create daily stat
        if let todayIndex = user.dailyStats.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            user.dailyStats[todayIndex].topicsExplored += 1
        } else {
            let newDailyStat = DailyStat(
                date: today,
                cardsFlipped: 0,
                topicsExplored: 1,
                achievements: []
            )
            user.dailyStats.append(newDailyStat)
        }

        // Update streak
        updateStreak(for: &user)

        currentUser = user
        try? await saveUser(user)

        // Update leaderboard
        await updateDailyLeaderboard(user: user, type: .topicsExplored)
    }

    func trackAchievement(_ achievement: String) async {
        guard var user = currentUser else { return }

        let today = Calendar.current.startOfDay(for: Date())

        // Update or create daily stat
        if let todayIndex = user.dailyStats.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            if !user.dailyStats[todayIndex].achievements.contains(achievement) {
                user.dailyStats[todayIndex].achievements.append(achievement)
            }
        } else {
            let newDailyStat = DailyStat(
                date: today,
                cardsFlipped: 0,
                topicsExplored: 0,
                achievements: [achievement]
            )
            user.dailyStats.append(newDailyStat)
        }

        currentUser = user
        try? await saveUser(user)
    }

    /// Refreshes the user's streak from their activity history. Idempotent per day:
    /// the streak is recomputed from the set of active days (see `StreakCalculator`),
    /// so multiple events on the same day never inflate it.
    private func updateStreak(for user: inout AppUser) {
        user.currentStreak = StreakCalculator.currentStreak(from: user.dailyStats)
        user.longestStreak = StreakCalculator.longestStreak(
            from: user.dailyStats,
            previousLongest: user.longestStreak
        )
        user.lastActiveDate = Date()
    }

    // MARK: - Leaderboard Management

    private func updateDailyLeaderboard(user: AppUser, type: LeaderboardType) async {
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = DateFormatter.yyyyMMdd.string(from: today)

        let todayStats = user.dailyStats.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        let value = type == .cardsFlipped ? (todayStats?.cardsFlipped ?? 0) : (todayStats?.topicsExplored ?? 0)

        let leaderboardEntry: [String: Any] = [
            "userId": user.id,
            "username": user.username,
            "value": value,
            "timestamp": Timestamp(date: Date())
        ]

        let collectionName = type == .cardsFlipped ? "daily_cards_leaderboard" : "daily_topics_leaderboard"

        try? await db.collection(collectionName).document("\(dateString)_\(user.id)").setData(leaderboardEntry)
    }

    /// Fetches today's top leaderboard entries for the given type, filters to today's
    /// documents, flags the current user, and assigns 1-based ranks by descending value.
    func fetchDailyLeaderboard(type: LeaderboardType) async throws -> [LeaderboardEntry] {
            let today = Calendar.current.startOfDay(for: Date())
            let dateString = DateFormatter.yyyyMMdd.string(from: today)

            let collectionName = type == .cardsFlipped ? "daily_cards_leaderboard" : "daily_topics_leaderboard"

            let snapshot = try await db.collection(collectionName)
                .whereField("userId", isNotEqualTo: "")
                .order(by: "value", descending: true)
                .limit(to: 50)
                .getDocuments()

            let rows: [LeaderboardRow] = snapshot.documents.compactMap { document in
                let data = document.data()
                guard let userId = data["userId"] as? String,
                      let username = data["username"] as? String,
                      let value = data["value"] as? Int,
                      document.documentID.hasPrefix(dateString) else {
                    return nil
                }
                return LeaderboardRow(userId: userId, username: username, value: value)
            }

            return LeaderboardEntry.ranked(from: rows, currentUserId: currentUser?.id)
        }

    // MARK: - Utility

    private func generateRandomUsername() -> String {
        let adjectives = ["Swift", "Bright", "Quick", "Smart", "Clever", "Sharp", "Wise", "Bold", "Fast", "Keen"]
        let nouns = ["Learner", "Student", "Scholar", "Thinker", "Explorer", "Genius", "Mind", "Brain", "Seeker", "Master"]

        let randomAdjective = adjectives.randomElement() ?? "Smart"
        let randomNoun = nouns.randomElement() ?? "Learner"
        let randomNumber = Int.random(in: 100...999)

        return "\(randomAdjective)\(randomNoun)\(randomNumber)"
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
