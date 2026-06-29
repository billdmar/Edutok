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

    // MARK: - Streak calculation

    /// Builds a DailyStat for `daysAgo` days before `reference` with the given activity.
    private func stat(daysAgo: Int, cards: Int = 1, topics: Int = 0,
                      reference: Date, calendar: Calendar = .current) -> DailyStat {
        let day = calendar.date(byAdding: .day, value: -daysAgo,
                                to: calendar.startOfDay(for: reference))!
        return DailyStat(date: day, cardsFlipped: cards, topicsExplored: topics, achievements: [])
    }

    @Test func streakIsZeroWithNoActivityToday() {
        let now = Date()
        // Active yesterday but not today -> streak is not alive.
        let stats = [stat(daysAgo: 1, reference: now)]
        #expect(StreakCalculator.currentStreak(from: stats, asOf: now) == 0)
    }

    @Test func streakIsOneForSingleActiveDay() {
        let now = Date()
        let stats = [stat(daysAgo: 0, reference: now)]
        #expect(StreakCalculator.currentStreak(from: stats, asOf: now) == 1)
    }

    @Test func sameDayActivityDoesNotInflateStreak() {
        // Regression test for the streak bug: many events on one day = streak 1, not N.
        let now = Date()
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let stats = (0..<50).map { _ in
            DailyStat(date: today, cardsFlipped: 1, topicsExplored: 0, achievements: [])
        }
        #expect(StreakCalculator.currentStreak(from: stats, asOf: now) == 1)
    }

    @Test func consecutiveDaysAccumulateStreak() {
        let now = Date()
        let stats = [stat(daysAgo: 0, reference: now),
                     stat(daysAgo: 1, reference: now),
                     stat(daysAgo: 2, reference: now)]
        #expect(StreakCalculator.currentStreak(from: stats, asOf: now) == 3)
    }

    @Test func gapResetsStreakToTodayOnly() {
        let now = Date()
        // Active today and 3 days ago, but the intervening days are missing.
        let stats = [stat(daysAgo: 0, reference: now),
                     stat(daysAgo: 3, reference: now),
                     stat(daysAgo: 4, reference: now)]
        #expect(StreakCalculator.currentStreak(from: stats, asOf: now) == 1)
    }

    @Test func zeroActivityDaysAreNotCounted() {
        let now = Date()
        // Today has a stat row but no actual activity -> not a streak day.
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let stats = [DailyStat(date: today, cardsFlipped: 0, topicsExplored: 0, achievements: [])]
        #expect(StreakCalculator.currentStreak(from: stats, asOf: now) == 0)
    }

    @Test func longestStreakNeverDecreases() {
        let now = Date()
        let stats = [stat(daysAgo: 0, reference: now)] // current streak 1
        // A previously higher longest streak is preserved.
        #expect(StreakCalculator.longestStreak(from: stats, previousLongest: 7, asOf: now) == 7)
    }

    @Test func longestStreakRisesWithCurrent() {
        let now = Date()
        let stats = [stat(daysAgo: 0, reference: now),
                     stat(daysAgo: 1, reference: now),
                     stat(daysAgo: 2, reference: now)]
        #expect(StreakCalculator.longestStreak(from: stats, previousLongest: 2, asOf: now) == 3)
    }

    // MARK: - Leaderboard ranking

    @Test func leaderboardSortsDescendingAndRanksFromOne() {
        let rows = [
            LeaderboardRow(userId: "a", username: "Alice", value: 5),
            LeaderboardRow(userId: "b", username: "Bob", value: 12),
            LeaderboardRow(userId: "c", username: "Cara", value: 9),
        ]
        let ranked = LeaderboardEntry.ranked(from: rows, currentUserId: "a")
        #expect(ranked.map(\.userId) == ["b", "c", "a"])
        #expect(ranked.map(\.rank) == [1, 2, 3])
    }

    @Test func leaderboardFlagsCurrentUser() {
        let rows = [
            LeaderboardRow(userId: "a", username: "Alice", value: 5),
            LeaderboardRow(userId: "b", username: "Bob", value: 12),
        ]
        let ranked = LeaderboardEntry.ranked(from: rows, currentUserId: "a")
        #expect(ranked.first(where: { $0.userId == "a" })?.isCurrentUser == true)
        #expect(ranked.first(where: { $0.userId == "b" })?.isCurrentUser == false)
    }

    @Test func leaderboardHandlesEmptyAndNilCurrentUser() {
        #expect(LeaderboardEntry.ranked(from: [], currentUserId: nil).isEmpty)
        let rows = [LeaderboardRow(userId: "a", username: "Alice", value: 5)]
        let ranked = LeaderboardEntry.ranked(from: rows, currentUserId: nil)
        #expect(ranked.count == 1)
        #expect(ranked[0].isCurrentUser == false)
    }

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
}
