//
//  TopicProgressTests.swift
//  EdutokTests
//
//  Topic progress percentage tests.
//

import Foundation
import Testing

@testable import Edutok

struct TopicProgressTests {
    @Test func emptyTopicHasZeroProgress() {
        let topic = Topic(title: "Empty", flashcards: [])
        #expect(topic.progressPercentage == 0)
    }

    @Test func topicProgressReflectsUnderstoodCards() {
        let cards = [
            Flashcard(type: .definition, question: "Q1", answer: "A1", isUnderstood: true),
            Flashcard(type: .definition, question: "Q2", answer: "A2", isUnderstood: true),
            Flashcard(type: .definition, question: "Q3", answer: "A3", isUnderstood: false),
            Flashcard(type: .definition, question: "Q4", answer: "A4", isUnderstood: false),
        ]
        let topic = Topic(title: "Half", flashcards: cards)
        #expect(topic.progressPercentage == 50)
    }
}
