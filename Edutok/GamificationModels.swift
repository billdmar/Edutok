/// GamificationModels.swift
///
/// Value types behind the gamification system: the player's XP/level progress and the
/// catalogs of XP rewards and achievements. Levelling uses a quadratic XP curve so each
/// level costs progressively more XP than the last.
import Foundation

// MARK: - User Progress Model

/// Tracks cumulative XP, the derived level, and per-level/per-day progress.
///
/// Level thresholds follow a quadratic curve (`levelToXPRequired`): level 1 = 0 XP,
/// level 2 = 100, level 3 = 300, level 4 = 600, and so on. The level is always recomputed
/// from `totalXP`, so XP is the single source of truth.
struct UserProgress: Codable {
    var totalXP: Int = 0
    var currentLevel: Int = 1
    var xpInCurrentLevel: Int = 0
    var lastActiveDate: Date = Date()
    var totalCardsCompleted: Int = 0
    var totalCorrectAnswers: Int = 0
    var achievementsUnlocked: [String] = []
    var currentStreak: Int = 0
    var xpGainedToday: Int = 0

    // Calculate XP needed for next level (quadratic growth)
    var xpNeededForNextLevel: Int {
        return levelToXPRequired(level: currentLevel + 1) - totalXP
    }

    // Calculate current level progress (0.0 to 1.0)
    var levelProgress: Double {
        let currentLevelXP = levelToXPRequired(level: currentLevel)
        let nextLevelXP = levelToXPRequired(level: currentLevel + 1)
        let progressXP = totalXP - currentLevelXP
        return Double(progressXP) / Double(nextLevelXP - currentLevelXP)
    }

    // XP formula: Level 1=0, Level 2=100, Level 3=300, Level 4=600, etc.
    private func levelToXPRequired(level: Int) -> Int {
        if level <= 1 { return 0 }
        return ((level - 1) * (level - 1) * 50) + ((level - 1) * 50)
    }

    // Calculate what level user should be based on total XP
    func calculateLevelFromXP() -> Int {
        var level = 1
        while totalXP >= levelToXPRequired(level: level + 1) {
            level += 1
        }
        return level
    }

    /// Adds `amount` XP, recomputes the current level and in-level XP, and returns
    /// `true` if this gain advanced the user to a higher level.
    mutating func addXP(_ amount: Int) -> Bool {
        let oldLevel = currentLevel
        totalXP += amount
        currentLevel = calculateLevelFromXP()

        // Update XP in current level
        let currentLevelBaseXP = levelToXPRequired(level: currentLevel)
        xpInCurrentLevel = totalXP - currentLevelBaseXP

        return currentLevel > oldLevel // Return true if leveled up
    }
}

// MARK: - XP Reward System

/// Catalog of XP-granting events; the raw value is the XP amount awarded.
enum XPReward: Int, CaseIterable {
    case cardCompleted = 10
    case correctAnswer = 15
    case perfectCard = 25      // Answered correctly on first try
    case topicCompleted = 100
    case dailyGoal = 50
    case weeklyChallenge = 200
    case speedBonus = 5        // Extra XP for quick answers
    case streakBonus = 20      // Daily streak bonus

    var description: String {
        switch self {
        case .cardCompleted: return "Card Completed"
        case .correctAnswer: return "Correct Answer"
        case .perfectCard: return "Perfect Card!"
        case .topicCompleted: return "Topic Mastered"
        case .dailyGoal: return "Daily Goal"
        case .weeklyChallenge: return "Weekly Challenge"
        case .speedBonus: return "Speed Bonus"
        case .streakBonus: return "Streak Bonus"
        }
    }

    var emoji: String {
        switch self {
        case .cardCompleted: return "✅"
        case .correctAnswer: return "💡"
        case .perfectCard: return "🌟"
        case .topicCompleted: return "🏆"
        case .dailyGoal: return "🎯"
        case .weeklyChallenge: return "💪"
        case .speedBonus: return "⚡"
        case .streakBonus: return "🔥"
        }
    }
}

// MARK: - Achievement System

/// The unlockable achievements, each exposing its title, description, emoji, and XP reward.
enum Achievement: String, CaseIterable {
    case firstCard = "first_card"
    case scholar = "scholar"              // 100 cards completed
    case speedDemon = "speed_demon"       // 50 cards in 5 minutes
    case nightOwl = "night_owl"           // Study after 11PM
    case explorer = "explorer"            // 10 different topics
    case perfectionist = "perfectionist" // 25 perfect cards
    case dedicated = "dedicated"          // 7 day streak
    case unstoppable = "unstoppable"     // 30 day streak

    var title: String {
        switch self {
        case .firstCard: return "First Steps"
        case .scholar: return "Scholar"
        case .speedDemon: return "Speed Demon"
        case .nightOwl: return "Night Owl"
        case .explorer: return "Explorer"
        case .perfectionist: return "Perfectionist"
        case .dedicated: return "Dedicated Learner"
        case .unstoppable: return "Unstoppable"
        }
    }

    var description: String {
        switch self {
        case .firstCard: return "Complete your first flashcard"
        case .scholar: return "Complete 100 flashcards"
        case .speedDemon: return "Complete 50 cards in 5 minutes"
        case .nightOwl: return "Study after 11 PM"
        case .explorer: return "Study 10 different topics"
        case .perfectionist: return "Get 25 perfect cards"
        case .dedicated: return "Maintain a 7-day streak"
        case .unstoppable: return "Maintain a 30-day streak"
        }
    }

    var emoji: String {
        switch self {
        case .firstCard: return "🌱"
        case .scholar: return "📚"
        case .speedDemon: return "💨"
        case .nightOwl: return "🦉"
        case .explorer: return "🗺️"
        case .perfectionist: return "💎"
        case .dedicated: return "🎯"
        case .unstoppable: return "🚀"
        }
    }

    var xpReward: Int {
        switch self {
        case .firstCard: return 50
        case .scholar: return 500
        case .speedDemon: return 300
        case .nightOwl: return 100
        case .explorer: return 250
        case .perfectionist: return 400
        case .dedicated: return 350
        case .unstoppable: return 1000
        }
    }
}
