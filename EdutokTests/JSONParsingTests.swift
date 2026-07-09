//
//  JSONParsingTests.swift
//  EdutokTests
//
//  LLMJSON extraction, flashcard type mapping, and Codable decode tests.
//

import Foundation
import Testing

@testable import Edutok

struct JSONParsingTests {
    // MARK: - LLM JSON extraction

    @Test func extractsArrayFromMarkdownFences() {
        let raw = "```json\n[{\"a\":1}]\n```"
        #expect(LLMJSON.extractJSONArray(from: raw) == "[{\"a\":1}]")
    }

    @Test func extractsArrayFromProseWrappedResponse() {
        let raw = "Here are your cards:\n[{\"x\":1}]\nHope that helps!"
        #expect(LLMJSON.extractJSONArray(from: raw) == "[{\"x\":1}]")
    }

    @Test func leavesCleanArrayUnchanged() {
        let raw = "[{\"q\":\"a\"}]"
        #expect(LLMJSON.extractJSONArray(from: raw) == raw)
    }

    @Test func normalizesSmartQuotes() {
        let raw = "[{\u{201C}q\u{201D}:\u{2018}a\u{2019}}]"
        #expect(LLMJSON.extractJSONArray(from: raw) == "[{\"q\":'a'}]")
    }

    @Test func returnsTrimmedTextWhenNoArrayPresent() {
        #expect(LLMJSON.extractJSONArray(from: "  no json here  ") == "no json here")
    }

    // MARK: - Flashcard type mapping

    @Test func mapsKnownFlashcardTypes() {
        #expect(TopicManager.flashcardType(from: "definition") == .definition)
        #expect(TopicManager.flashcardType(from: "True/False") == .truefalse)
        #expect(TopicManager.flashcardType(from: "fill_in_blank") == .fillblank)
        #expect(TopicManager.flashcardType(from: "question") == .question)
    }

    @Test func unknownFlashcardTypeDefaultsToQuestion() {
        #expect(TopicManager.flashcardType(from: "gibberish") == .question)
    }

    // MARK: - Flashcard backward-compatible decoding

    @Test func decodesLegacyFlashcardJSONWithoutReviewFields() throws {
        // A returning user's saved card predates lastReviewedAt/reviewCount. Decoding must
        // NOT throw (a throw would wipe all saved topics in loadSavedTopics' catch block).
        let legacyJSON = """
        {"type":"question","question":"Q","answer":"A","isUnderstood":true,"isBookmarked":false}
        """
        let card = try JSONDecoder().decode(Flashcard.self, from: Data(legacyJSON.utf8))
        #expect(card.question == "Q")
        #expect(card.isUnderstood)        // preserved from old data
        #expect(card.reviewCount == 0)    // defaulted, not thrown
        #expect(card.lastReviewedAt == nil)
    }

    @Test func flashcardRoundTripsThroughCodable() throws {
        var original = Flashcard(type: .definition, question: "Q", answer: "A")
        original.isUnderstood = true
        original.reviewCount = 3
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Flashcard.self, from: data)
        #expect(decoded.question == "Q")
        #expect(decoded.isUnderstood)
        #expect(decoded.reviewCount == 3)
    }

    // MARK: - UserProgress back-compatible decoding

    @Test func decodesLegacyUserProgressWithoutConsecutiveField() throws {
        // A returning user's saved progress predates consecutiveCorrectAnswers. Decoding must
        // NOT throw (a throw would reset all their XP/level in loadProgress' catch).
        let legacyProgress = """
        {"totalXP":250,"currentLevel":3,"xpInCurrentLevel":50,"totalCardsCompleted":12,
         "totalCorrectAnswers":9,"currentStreak":4,"xpGainedToday":40,
         "lastActiveDate":760000000}
        """
        let decoded = try JSONDecoder().decode(UserProgress.self, from: Data(legacyProgress.utf8))
        #expect(decoded.totalXP == 250)
        #expect(decoded.currentLevel == 3)
        #expect(decoded.totalCorrectAnswers == 9)
        #expect(decoded.consecutiveCorrectAnswers == 0)  // defaulted, not thrown
    }

    @Test func userProgressRoundTripsWithStreak() throws {
        var p = UserProgress()
        _ = p.addXP(120)
        p.consecutiveCorrectAnswers = 5
        let decoded = try JSONDecoder().decode(UserProgress.self, from: JSONEncoder().encode(p))
        #expect(decoded.totalXP == 120)
        #expect(decoded.consecutiveCorrectAnswers == 5)
    }
}
