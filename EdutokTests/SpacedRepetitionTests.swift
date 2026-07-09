//
//  SpacedRepetitionTests.swift
//  EdutokTests
//
//  ReviewScheduler tests.
//

import Foundation
import Testing

@testable import Edutok

struct SpacedRepetitionTests {
    private func card(understood: Bool, lastReviewed: Date?, reviewCount: Int) -> Flashcard {
        var c = Flashcard(type: .question, question: "Q", answer: "A")
        c.isUnderstood = understood
        c.lastReviewedAt = lastReviewed
        c.reviewCount = reviewCount
        return c
    }

    @Test func notUnderstoodCardIsNeverDue() {
        let c = card(understood: false, lastReviewed: nil, reviewCount: 0)
        #expect(!ReviewScheduler.isDue(c))
    }

    @Test func understoodNeverReviewedCardIsDue() {
        let c = card(understood: true, lastReviewed: nil, reviewCount: 0)
        #expect(ReviewScheduler.isDue(c))
    }

    @Test func recentlyReviewedCardIsNotDue() {
        let now = Date()
        // Reviewed today, reviewCount 0 → first interval is 1 day → not yet due.
        let c = card(understood: true, lastReviewed: now, reviewCount: 0)
        #expect(!ReviewScheduler.isDue(c, asOf: now))
    }

    @Test func cardBecomesDueAfterItsInterval() {
        let now = Date()
        let cal = Calendar.current
        // reviewCount 0 → 1-day interval; reviewed 2 days ago → due.
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: now)!
        let c = card(understood: true, lastReviewed: twoDaysAgo, reviewCount: 0)
        #expect(ReviewScheduler.isDue(c, asOf: now))
    }

    @Test func higherReviewCountWaitsLonger() {
        let now = Date()
        let cal = Calendar.current
        // reviewCount 3 → 14-day interval; reviewed 7 days ago → NOT yet due.
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: now)!
        let c = card(understood: true, lastReviewed: sevenDaysAgo, reviewCount: 3)
        #expect(!ReviewScheduler.isDue(c, asOf: now))
    }

    @Test func reviewCountBeyondScheduleClampsToLongestInterval() {
        let now = Date()
        let cal = Calendar.current
        // reviewCount 99 clamps to the 30-day interval; reviewed 31 days ago → due.
        let longAgo = cal.date(byAdding: .day, value: -31, to: now)!
        let c = card(understood: true, lastReviewed: longAgo, reviewCount: 99)
        #expect(ReviewScheduler.isDue(c, asOf: now))
    }

    @Test func dueCardsFiltersToOnlyDue() {
        let now = Date()
        let due = card(understood: true, lastReviewed: nil, reviewCount: 0)
        let notDue = card(understood: true, lastReviewed: now, reviewCount: 0)
        let notUnderstood = card(understood: false, lastReviewed: nil, reviewCount: 0)
        let result = ReviewScheduler.dueCards(from: [due, notDue, notUnderstood], asOf: now)
        #expect(result.count == 1)
    }
}
