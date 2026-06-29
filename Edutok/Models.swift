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
    var imageURL: String?  // NEW: Image URL for the flashcard
    var lastReviewedAt: Date?  // Most recent spaced-repetition review (nil = never reviewed)
    var reviewCount: Int = 0   // Number of completed review sessions for this card

    init(type: FlashcardType, question: String, answer: String,
         isUnderstood: Bool = false, isBookmarked: Bool = false, imageURL: String? = nil,
         lastReviewedAt: Date? = nil, reviewCount: Int = 0) {
        self.type = type
        self.question = question
        self.answer = answer
        self.isUnderstood = isUnderstood
        self.isBookmarked = isBookmarked
        self.imageURL = imageURL
        self.lastReviewedAt = lastReviewedAt
        self.reviewCount = reviewCount
    }

    enum CodingKeys: String, CodingKey {
        case type, question, answer, isUnderstood, isBookmarked, imageURL, lastReviewedAt, reviewCount
    }

    // Custom decoder so newly-added fields (reviewCount, lastReviewedAt) tolerate older
    // persisted JSON that predates them. Without this, a missing non-optional key throws
    // and `TopicManager.loadSavedTopics` would silently wipe a returning user's topics.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(FlashcardType.self, forKey: .type)
        question = try c.decode(String.self, forKey: .question)
        answer = try c.decode(String.self, forKey: .answer)
        isUnderstood = try c.decodeIfPresent(Bool.self, forKey: .isUnderstood) ?? false
        isBookmarked = try c.decodeIfPresent(Bool.self, forKey: .isBookmarked) ?? false
        imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        lastReviewedAt = try c.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        reviewCount = try c.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
    }
}

// MARK: - Models/TopicModel.swift
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
    case common
    case rare
    case epic
    case legendary

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
    case common
    case rare
    case epic
    case legendary

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
    case learning
    case social
    case time
    case special

    var displayName: String {
        switch self {
        case .learning: return "Learning"
        case .social: return "Social"
        case .time: return "Time"
        case .special: return "Special"
        }
    }
}
