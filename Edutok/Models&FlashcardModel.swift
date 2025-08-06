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
    
    enum CodingKeys: String, CodingKey {
        case type, question, answer, isUnderstood, isBookmarked
    }
}

// MARK: - Models/TopicModel.swift
import Foundation

struct Topic: Identifiable, Codable {
    let id = UUID()
    let title: String
    var flashcards: [Flashcard]
    let createdAt: Date = Date()
    
    var progressPercentage: Int {
        guard !flashcards.isEmpty else { return 0 }
        let understoodCount = flashcards.filter { $0.isUnderstood }.count
        return Int((Double(understoodCount) / Double(flashcards.count)) * 100)
    }
    
    enum CodingKeys: String, CodingKey {
        case title, flashcards, createdAt
    }
}
