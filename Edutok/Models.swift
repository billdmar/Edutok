import Foundation

enum FlashcardType: String, CaseIterable, Codable {
    case definition = "definition"
    case question = "question"
    case truefalse = "true/false"
    case fillblank = "fill in the blank"
}

struct Flashcard: Identifiable, Codable {
    let id = UUID()
    let type: FlashcardType
    let question: String
    let answer: String
    var isUnderstood: Bool = false
    var isBookmarked: Bool = false
    var imageURL: String? = nil  // NEW: Image URL for the flashcard
    
    enum CodingKeys: String, CodingKey {
        case type, question, answer, isUnderstood, isBookmarked, imageURL
    }
}

// MARK: - Models/TopicModel.swift
import Foundation
struct Topic: Identifiable, Codable, Equatable {
    let id = UUID()
    let title: String
    var flashcards: [Flashcard]
    let createdAt: Date = Date()
    var isLiked: Bool = false
    
    static func == (lhs: Topic, rhs: Topic) -> Bool {
        lhs.id == rhs.id
    }
    
    var progressPercentage: Int {
        guard !flashcards.isEmpty else { return 0 }
        let understoodCount = flashcards.filter { $0.isUnderstood }.count
        return Int((Double(understoodCount) / Double(flashcards.count)) * 100)
    }
    
    enum CodingKeys: String, CodingKey {
        case title, flashcards, createdAt, isLiked
    }
}

// MARK: - New Phase 1 Models

struct CustomAchievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let xpReward: Int
    let emoji: String
}

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
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

enum ChallengeType: String, CaseIterable, Codable {
    case cardsCompleted = "cards_completed"
    case correctAnswers = "correct_answers"
    case topicsExplored = "topics_explored"
    case perfectCards = "perfect_cards"
    case studyTime = "study_time"
    
    var icon: String {
        switch self {
        case .cardsCompleted: return "rectangle.stack.fill"
        case .correctAnswers: return "checkmark.circle.fill"
        case .topicsExplored: return "book.fill"
        case .perfectCards: return "star.fill"
        case .studyTime: return "clock.fill"
        }
    }
    
    var color: String {
        switch self {
        case .cardsCompleted: return "purple"
        case .correctAnswers: return "green"
        case .topicsExplored: return "blue"
        case .perfectCards: return "yellow"
        case .studyTime: return "orange"
        }
    }
}

struct MysteryBox: Identifiable, Codable {
    let id = UUID()
    let xpAmount: Int
    let rarity: BoxRarity
    var isOpened: Bool
    var openedAt: Date?
    
    var displayText: String {
        if isOpened {
            return "+\(xpAmount) XP"
        } else {
            return "???"
        }
    }
}

enum BoxRarity: String, CaseIterable, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
    
    var xpRange: ClosedRange<Int> {
        switch self {
        case .common: return 10...25
        case .rare: return 25...50
        case .epic: return 50...100
        case .legendary: return 100...200
        }
    }
}

struct EnhancedAchievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let xpReward: Int
    let icon: String
    let rarity: AchievementRarity
    var isUnlocked: Bool
    var unlockedAt: Date?
    let category: AchievementCategory
    
    var displayIcon: String {
        if isUnlocked {
            return icon
        } else {
            return "lock.fill"
        }
    }
}

enum AchievementRarity: String, CaseIterable, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
}

enum AchievementCategory: String, CaseIterable, Codable {
    case learning = "learning"
    case social = "social"
    case time = "time"
    case special = "special"
    
    var displayName: String {
        switch self {
        case .learning: return "Learning"
        case .social: return "Social"
        case .time: return "Time"
        case .special: return "Special"
        }
    }
}
