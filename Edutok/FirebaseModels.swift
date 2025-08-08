// FirebaseModels.swift
import Foundation

// MARK: - App User Model
struct AppUser: Identifiable, Codable {
    let id: String
    var username: String
    var totalCardsFlipped: Int
    var totalTopicsExplored: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date
    let joinDate: Date
    var dailyStats: [DailyStat]
    
    // Get today's stats
    var todayStats: DailyStat? {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyStats.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    // Get stats for a specific date
    func statsFor(date: Date) -> DailyStat? {
        let targetDate = Calendar.current.startOfDay(for: date)
        return dailyStats.first { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }
    }
    
    // Check if user has activity on a specific date
    func hasActivityOn(date: Date) -> Bool {
        guard let stats = statsFor(date: date) else { return false }
        return stats.cardsFlipped > 0 || stats.topicsExplored > 0
    }
}

// MARK: - Daily Statistics Model
struct DailyStat: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var cardsFlipped: Int
    var topicsExplored: Int
    var achievements: [String]
    
    enum CodingKeys: String, CodingKey {
        case date, cardsFlipped, topicsExplored, achievements
    }
    
    var hasActivity: Bool {
        return cardsFlipped > 0 || topicsExplored > 0
    }
    
    var totalActivity: Int {
        return cardsFlipped + topicsExplored
    }
}

// MARK: - Leaderboard Models
enum LeaderboardType: String, CaseIterable {
    case cardsFlipped = "cards_flipped"
    case topicsExplored = "topics_explored"
    
    var title: String {
        switch self {
        case .cardsFlipped:
            return "Cards Flipped Today"
        case .topicsExplored:
            return "Topics Explored Today"
        }
    }
    
    var icon: String {
        switch self {
        case .cardsFlipped:
            return "rectangle.stack.fill"
        case .topicsExplored:
            return "book.fill"
        }
    }
    
    var color: String {
        switch self {
        case .cardsFlipped:
            return "purple"
        case .topicsExplored:
            return "blue"
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let userId: String
    let username: String
    let value: Int
    let rank: Int
    let isCurrentUser: Bool
    
    init(userId: String, username: String, value: Int, rank: Int, isCurrentUser: Bool = false) {
        self.userId = userId
        self.username = username
        self.value = value
        self.rank = rank
        self.isCurrentUser = isCurrentUser
    }
}

// MARK: - Calendar Event Models
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let dailyStat: DailyStat?
    let hasStreak: Bool
    let achievements: [String]
    
    var hasActivity: Bool {
        return dailyStat?.hasActivity ?? false
    }
    
    var isToday: Bool {
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var dayNumber: Int {
        return Calendar.current.component(.day, from: date)
    }
    
    var activityLevel: ActivityLevel {
        guard let stat = dailyStat else { return .none }
        
        let total = stat.totalActivity
        if total == 0 { return .none }
        else if total < 5 { return .low }
        else if total < 15 { return .medium }
        else { return .high }
    }
}

enum ActivityLevel {
    case none, low, medium, high
    
    var color: String {
        switch self {
        case .none: return "gray"
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
    
    var opacity: Double {
        switch self {
        case .none: return 0.1
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 1.0
        }
    }
}

// MARK: - Achievement Models
struct CalendarAchievement: Identifiable {
    let id = UUID()
    let date: Date
    let achievementId: String
    let title: String
    let emoji: String
    
    init(date: Date, achievement: Achievement) {
        self.date = date
        self.achievementId = achievement.rawValue
        self.title = achievement.title
        self.emoji = achievement.emoji
    }
}
