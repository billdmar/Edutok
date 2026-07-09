//
//  XPMathTests.swift
//  EdutokTests
//
//  Card-completion XP math and mystery box rarity tests.
//

import Foundation
import Testing

@testable import Edutok

struct XPMathTests {
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

    // MARK: - Card-completion XP math

    @Test func incorrectCardAwardsBaseXPOnly() {
        // 10 base, no bonuses.
        #expect(GamificationManager.cardCompletionXP(wasCorrect: false, isFirstTry: false, timeToAnswer: 1) == 10)
    }

    @Test func correctSlowNonFirstTryAwardsBasePlusCorrect() {
        // 10 + 15, no perfect, no speed (>=5s).
        #expect(GamificationManager.cardCompletionXP(wasCorrect: true, isFirstTry: false, timeToAnswer: 9) == 25)
    }

    @Test func perfectFastCardAwardsAllBonuses() {
        // 10 + 15 + 25 (perfect) + 5 (speed) = 55.
        #expect(GamificationManager.cardCompletionXP(wasCorrect: true, isFirstTry: true, timeToAnswer: 1) == 55)
    }

    @Test func firstTryButSlowSkipsSpeedBonus() {
        // 10 + 15 + 25, no speed because 5.0 is not < 5.0.
        #expect(GamificationManager.cardCompletionXP(wasCorrect: true, isFirstTry: true, timeToAnswer: 5) == 50)
    }

    @Test func correctFastNonFirstTryGetsSpeedNotPerfect() {
        // 10 + 15 + 5 (speed), no perfect.
        #expect(GamificationManager.cardCompletionXP(wasCorrect: true, isFirstTry: false, timeToAnswer: 2) == 30)
    }

    @Test func firstTryWithoutCorrectIgnoresPerfectBonus() {
        // Perfect/speed only apply when wasCorrect — incorrect stays at base 10.
        #expect(GamificationManager.cardCompletionXP(wasCorrect: false, isFirstTry: true, timeToAnswer: 1) == 10)
    }

    // MARK: - Mystery-box rarity distribution

    @Test func rarityBoundariesMapToExpectedTiers() {
        #expect(MysteryBoxStore.rarity(for: 0.0) == .common)
        #expect(MysteryBoxStore.rarity(for: 0.49) == .common)
        #expect(MysteryBoxStore.rarity(for: 0.5) == .rare)      // boundary → rare
        #expect(MysteryBoxStore.rarity(for: 0.79) == .rare)
        #expect(MysteryBoxStore.rarity(for: 0.8) == .epic)      // boundary → epic
        #expect(MysteryBoxStore.rarity(for: 0.94) == .epic)
        #expect(MysteryBoxStore.rarity(for: 0.95) == .legendary) // boundary → legendary
        #expect(MysteryBoxStore.rarity(for: 0.999) == .legendary)
    }
}
