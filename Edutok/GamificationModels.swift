import Foundation

// MARK: - User Progress Model
struct UserProgress: Codable {
    var totalXP: Int = 0
    var currentLevel: Int = 1
    var xpInCurrentLevel: Int = 0
    var lastActiveDate: Date = Date()
    var totalCardsCompleted: Int = 0
    var totalCorrectAnswers: Int = 0
    var achievementsUnlocked: [String] = []
    var dailyMysteryBoxes: [MysteryBox] = []
    var lastMysteryBoxDate: Date?
    var currentStreak: Int = 0 
    // Calculate XP needed for next level (exponential growth)
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
    
    // XP formula: Level 1=0, Level 2=100, Level 3=250, Level 4=450, etc.
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
    
    // Add XP and check for level up
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

enum Achievement: String, CaseIterable {
    // Learning achievements
    case firstCard = "first_card"
    case scholar = "scholar"
    case perfectionist = "perfectionist"
    case speedDemon = "speed_demon"
    
    // Social achievements
    case socialButterfly = "social_butterfly"  // Share 5 topics
    case trendsetter = "trendsetter"          // Create a trending topic
    case studyBuddy = "study_buddy"           // Invite 3 friends
    case influencer = "influencer"             // Get 100 likes on topics
    
    // Time achievements
    case nightOwl = "night_owl"
    case earlyBird = "early_bird"             // Study before 6 AM
    case dedicated = "dedicated"
    case unstoppable = "unstoppable"
    
    // Special achievements
    case explorer = "explorer"
    case masterMind = "master_mind"           // Complete 5 topics with 100%
    case knowledgeSeeker = "knowledge_seeker" // Learn 25 different topics
    case legendary = "legendary"               // Reach level 50
    
    var category: AchievementCategory {
        switch self {
        case .firstCard, .scholar, .perfectionist, .speedDemon:
            return .learning
        case .socialButterfly, .trendsetter, .studyBuddy, .influencer:
            return .social
        case .nightOwl, .earlyBird, .dedicated, .unstoppable:
            return .time
        case .explorer, .masterMind, .knowledgeSeeker, .legendary:
            return .special
        }
    }
    
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
        case .socialButterfly: return "Social Butterfly"
        case .trendsetter: return "Trendsetter"
        case .studyBuddy: return "Study Buddy"
        case .influencer: return "Influencer"
        case .earlyBird: return "Early Bird"
        case .masterMind: return "Master Mind"
        case .knowledgeSeeker: return "Knowledge Seeker"
        case .legendary: return "Legendary"
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
        case .socialButterfly: return "Share 5 topics with friends"
        case .trendsetter: return "Create a trending topic"
        case .studyBuddy: return "Invite 3 friends to learn"
        case .influencer: return "Get 100 likes on your topics"
        case .earlyBird: return "Study before 6 AM"
        case .masterMind: return "Complete 5 topics with 100%"
        case .knowledgeSeeker: return "Learn 25 different topics"
        case .legendary: return "Reach level 50"
        }
    }
    
    var emoji: String {
        switch self {
        case .firstCard: return "🌱"
        case .scholar: return "📚"
        case .speedDemon: return "⚡"
        case .nightOwl: return "🦉"
        case .explorer: return "🗺️"
        case .perfectionist: return "💎"
        case .dedicated: return "🎯"
        case .unstoppable: return "🚀"
        case .socialButterfly: return "🦋"
        case .trendsetter: return "📈"
        case .studyBuddy: return "👥"
        case .influencer: return "⭐"
        case .earlyBird: return "🌅"
        case .masterMind: return "🧠"
        case .knowledgeSeeker: return "🔍"
        case .legendary: return "👑"
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
        case .socialButterfly: return 200
        case .trendsetter: return 600
        case .studyBuddy: return 150
        case .influencer: return 800
        case .earlyBird: return 100
        case .masterMind: return 750
        case .knowledgeSeeker: return 500
        case .legendary: return 2000
        }
    }
}

// Add this enum RIGHT AFTER the Achievement enum closes
enum AchievementCategory: String, CaseIterable {
    case learning = "Learning"
    case social = "Social"
    case time = "Time"
    case special = "Special"
}



// MARK: - Mystery Box System
struct MysteryBox: Identifiable, Codable {
    let id = UUID()
    var isOpened: Bool = false
    var xpReward: Int = 0
    let boxNumber: Int // 1, 2, or 3
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case isOpened, xpReward, boxNumber, date
    }
    
    // Generate random XP reward
    mutating func open() -> Int {
        guard !isOpened else { return 0 }
        
        // Random XP between 10-100, with rare chances for bigger rewards
        let random = Int.random(in: 1...100)
        if random <= 60 { // 60% chance
            xpReward = Int.random(in: 10...30)
        } else if random <= 90 { // 30% chance
            xpReward = Int.random(in: 31...60)
        } else if random <= 98 { // 8% chance
            xpReward = Int.random(in: 61...100)
        } else { // 2% chance for jackpot
            xpReward = Int.random(in: 150...250)
        }
        
        isOpened = true
        return xpReward
    }
}
// MARK: - Daily Challenge Models
struct DailyChallenge: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let xpReward: Int
    var isCompleted: Bool
    let type: ChallengeType
    let expiresAt: Date
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var progress: Double {
        return Double(currentValue) / Double(targetValue)
    }
}

enum ChallengeType: String, Codable {
    case cardsCompleted = "cards_completed"
    case correctAnswers = "correct_answers"
    case topicsExplored = "topics_explored"
}

// MARK: - Mystery Box Models
struct MysteryBox: Identifiable, Codable {
    let id = UUID()
    let xpAmount: Int
    let rarity: BoxRarity
    var isOpened: Bool
    var openedAt: Date?
}

enum BoxRarity: String, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var xpRange: ClosedRange<Int> {
        switch self {
        case .common: return 10...30
        case .rare: return 31...60
        case .epic: return 61...100
        case .legendary: return 101...200
        }
    }
    
    var emoji: String {
        switch self {
        case .common: return "📦"
        case .rare: return "🎁"
        case .epic: return "💎"
        case .legendary: return "👑"
        }
    }
}

// MARK: - Enhanced Achievement Models
struct EnhancedAchievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let xpReward: Int
    let icon: String
    let rarity: BoxRarity
    var isUnlocked: Bool
    var unlockedAt: Date?
    let category: AchievementCategory
}

// MARK: - Custom Achievement for notifications
struct CustomAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let xpReward: Int
    let emoji: String
}
