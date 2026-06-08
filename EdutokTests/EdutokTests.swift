//
//  EdutokTests.swift
//  EdutokTests
//
//  Unit tests for Edutok's pure domain logic — XP/leveling math, progress
//  calculations, and reward ranges. These exercise deterministic model logic
//  with no Firebase or network dependency.
//

import Foundation
import Testing

@testable import Edutok

struct EdutokTests {
    // MARK: - Leveling math

    @Test func newUserStartsAtLevelOne() {
        let progress = UserProgress()
        #expect(progress.currentLevel == 1)
        #expect(progress.totalXP == 0)
    }

    @Test func addingXPAccumulatesTotal() {
        var progress = UserProgress()
        _ = progress.addXP(30)
        _ = progress.addXP(20)
        #expect(progress.totalXP == 50)
    }

    @Test func crossingThresholdReportsLevelUp() {
        var progress = UserProgress()
        // Level 2 requires 100 XP (per the documented formula).
        let leveledUp = progress.addXP(100)
        #expect(leveledUp)
        #expect(progress.currentLevel == 2)
    }

    @Test func stayingBelowThresholdDoesNotLevelUp() {
        var progress = UserProgress()
        let leveledUp = progress.addXP(99)
        #expect(!leveledUp)
        #expect(progress.currentLevel == 1)
    }

    @Test func levelThresholdsFollowFormula() {
        // Verified against the model's own formula
        // ((level-1)^2 * 50) + ((level-1) * 50): L2=100, L3=300, L4=600.
        var atTwo = UserProgress()
        _ = atTwo.addXP(100)
        #expect(atTwo.currentLevel == 2)

        var atThree = UserProgress()
        _ = atThree.addXP(300)
        #expect(atThree.currentLevel == 3)

        var atFour = UserProgress()
        _ = atFour.addXP(600)
        #expect(atFour.currentLevel == 4)
    }

    @Test func levelProgressIsWithinUnitInterval() {
        var progress = UserProgress()
        _ = progress.addXP(150) // between level 2 (100) and level 3 (300)
        #expect(progress.levelProgress >= 0.0)
        #expect(progress.levelProgress <= 1.0)
    }

    // MARK: - Topic progress

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

    // MARK: - Daily challenge progress

    @Test func dailyChallengeProgressClampsAtOne() {
        let challenge = DailyChallenge(
            title: "Over-achiever",
            description: "Do 5 cards",
            targetValue: 5,
            currentValue: 8, // exceeds target
            xpReward: 50,
            isCompleted: true,
            type: .cardsCompleted,
            expiresAt: Date().addingTimeInterval(3600)
        )
        #expect(challenge.progressPercentage == 1.0)
    }

    // MARK: - Reward ranges

    @Test func boxRarityRangesAreOrdered() {
        // Rarer boxes should award at least as much as commoner ones.
        #expect(BoxRarity.common.xpRange.upperBound <= BoxRarity.rare.xpRange.upperBound)
        #expect(BoxRarity.rare.xpRange.upperBound <= BoxRarity.epic.xpRange.upperBound)
        #expect(BoxRarity.epic.xpRange.upperBound <= BoxRarity.legendary.xpRange.upperBound)
    }

    @Test func everyBoxRarityHasAPositiveNonEmptyRange() {
        // randomRarity() draws an XP amount from rarity.xpRange, so each case must
        // expose a valid (non-empty, positive) range for that draw to be safe.
        for rarity in BoxRarity.allCases {
            #expect(rarity.xpRange.lowerBound <= rarity.xpRange.upperBound)
            #expect(rarity.xpRange.lowerBound > 0)
        }
    }

    @Test func boxRarityRangeLowerBoundsEscalateWithRarity() {
        // The lower bound should also climb with rarity, mirroring the rarity
        // partitions randomRarity() maps onto (common -> rare -> epic -> legendary).
        #expect(BoxRarity.common.xpRange.lowerBound <= BoxRarity.rare.xpRange.lowerBound)
        #expect(BoxRarity.rare.xpRange.lowerBound <= BoxRarity.epic.xpRange.lowerBound)
        #expect(BoxRarity.epic.xpRange.lowerBound <= BoxRarity.legendary.xpRange.lowerBound)
    }
}
