// FirebaseManager.swift
import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

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
    
    // MARK: - Authentication
    
    func signInAnonymously() async throws {
        let result = try await auth.signInAnonymously()
        await loadOrCreateUser(uid: result.user.uid)
    }
    
    func signOut() {
        try? auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - User Management
    
    private func loadOrCreateUser(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            if document.exists {
                // Load existing user
                let data = document.data() ?? [:]
                currentUser = AppUser(
                    id: uid,
                    username: data["username"] as? String ?? "Anonymous",
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
            print("Error loading/creating user: \(error)")
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
    
    private func updateStreak(for user: inout AppUser) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Check if user was active yesterday or today
        let hasActivityToday = user.dailyStats.contains { calendar.isDate($0.date, inSameDayAs: today) && ($0.cardsFlipped > 0 || $0.topicsExplored > 0) }
        let hasActivityYesterday = user.dailyStats.contains { calendar.isDate($0.date, inSameDayAs: yesterday) && ($0.cardsFlipped > 0 || $0.topicsExplored > 0) }
        
        if hasActivityToday {
            if hasActivityYesterday || user.currentStreak == 0 {
                user.currentStreak += 1
                user.longestStreak = max(user.longestStreak, user.currentStreak)
            }
        } else {
            user.currentStreak = 0
        }
        
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
    
    func fetchDailyLeaderboard(type: LeaderboardType) async throws -> [LeaderboardEntry] {
            let today = Calendar.current.startOfDay(for: Date())
            let dateString = DateFormatter.yyyyMMdd.string(from: today)
            
            let collectionName = type == .cardsFlipped ? "daily_cards_leaderboard" : "daily_topics_leaderboard"
            
            let snapshot = try await db.collection(collectionName)
                .whereField("userId", isNotEqualTo: "")
                .order(by: "value", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            let currentUserId = currentUser?.id
            
            // First, create the initial entries
            var entries: [LeaderboardEntry] = []
            
            for document in snapshot.documents {
                let data = document.data()
                guard let userId = data["userId"] as? String,
                      let username = data["username"] as? String,
                      let value = data["value"] as? Int,
                      document.documentID.hasPrefix(dateString) else {
                    continue
                }
                
                let entry = LeaderboardEntry(
                    userId: userId,
                    username: username,
                    value: value,
                    rank: 0, // Will be set after sorting
                    isCurrentUser: userId == currentUserId
                )
                entries.append(entry)
            }
            
            // Now assign ranks
            let rankedEntries = entries.enumerated().map { index, entry in
                LeaderboardEntry(
                    userId: entry.userId,
                    username: entry.username,
                    value: entry.value,
                    rank: index + 1,
                    isCurrentUser: entry.isCurrentUser
                )
            }
            
            return rankedEntries
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
