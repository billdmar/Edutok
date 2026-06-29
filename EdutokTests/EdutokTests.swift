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

    // MARK: - Daily challenge expiry

    @Test func challengeWithFutureExpiryIsNotExpired() {
        let challenge = DailyChallenge(
            title: "T", description: "D", targetValue: 5, currentValue: 0,
            xpReward: 50, isCompleted: false, type: .cardsCompleted,
            expiresAt: Date().addingTimeInterval(3600)
        )
        #expect(!challenge.isExpired)
    }

    @Test func challengeWithPastExpiryIsExpired() {
        let challenge = DailyChallenge(
            title: "T", description: "D", targetValue: 5, currentValue: 0,
            xpReward: 50, isCompleted: false, type: .cardsCompleted,
            expiresAt: Date().addingTimeInterval(-3600)
        )
        #expect(challenge.isExpired)
    }

    // MARK: - Spaced-repetition scheduling

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
        let cal = Calendar.current
        let due = card(understood: true, lastReviewed: nil, reviewCount: 0)
        let notDue = card(understood: true, lastReviewed: now, reviewCount: 0)
        let notUnderstood = card(understood: false, lastReviewed: nil, reviewCount: 0)
        let result = ReviewScheduler.dueCards(from: [due, notDue, notUnderstood], asOf: now)
        #expect(result.count == 1)
    }

    // MARK: - Flashcard backward-compatible decoding

    @Test func decodesLegacyFlashcardJSONWithoutReviewFields() throws {
        // A returning user's saved card predates lastReviewedAt/reviewCount. Decoding must
        // NOT throw (a throw would wipe all saved topics in loadSavedTopics' catch block).
        let legacy = """
        {"type":"question","question":"Q","answer":"A","isUnderstood":true,"isBookmarked":false}
        """.data(using: .utf8)!
        let card = try JSONDecoder().decode(Flashcard.self, from: legacy)
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

    // MARK: - Calendar activity-level bucketing

    private func calendarDay(cards: Int, topics: Int) -> CalendarDay {
        let stat = DailyStat(date: Date(), cardsFlipped: cards, topicsExplored: topics, achievements: [])
        return CalendarDay(date: Date(), dailyStat: stat, hasStreak: false, achievements: [])
    }

    @Test func activityLevelBucketsByTotalActivity() {
        #expect(calendarDay(cards: 0, topics: 0).activityLevel == .none)
        #expect(calendarDay(cards: 1, topics: 0).activityLevel == .low)
        #expect(calendarDay(cards: 4, topics: 0).activityLevel == .low)
        #expect(calendarDay(cards: 5, topics: 0).activityLevel == .medium)   // boundary
        #expect(calendarDay(cards: 14, topics: 0).activityLevel == .medium)
        #expect(calendarDay(cards: 8, topics: 7).activityLevel == .high)     // 15 total → high
    }

    @Test func calendarDayWithNoStatIsNone() {
        let day = CalendarDay(date: Date(), dailyStat: nil, hasStreak: false, achievements: [])
        #expect(day.activityLevel == .none)
    }

    @Test func dailyStatTotalActivitySumsBothCounts() {
        let stat = DailyStat(date: Date(), cardsFlipped: 6, topicsExplored: 4, achievements: [])
        #expect(stat.totalActivity == 10)
    }

    // MARK: - ChallengeStore progress logic

    @Test func challengeProgressAdvancesMatchingTypeAndClamps() {
        let store = ChallengeStore()
        let challenges = store.makeDailyChallenges()
        // Card Master targets 15 cardsCompleted; advance by 20 → clamps to 15 and completes.
        let result = store.applyProgress(to: challenges, type: .cardsCompleted, value: 20)
        let cardMaster = result.challenges.first { $0.type == .cardsCompleted }!
        #expect(cardMaster.currentValue == 15)
        #expect(cardMaster.isCompleted)
        #expect(result.newlyCompleted.contains { $0.type == .cardsCompleted })
    }

    @Test func challengeProgressLeavesOtherTypesUntouched() {
        let store = ChallengeStore()
        let result = store.applyProgress(to: store.makeDailyChallenges(), type: .cardsCompleted, value: 1)
        let explorer = result.challenges.first { $0.type == .topicsExplored }!
        #expect(explorer.currentValue == 0)
        #expect(!explorer.isCompleted)
    }

    @Test func challengeProgressBelowTargetDoesNotComplete() {
        let store = ChallengeStore()
        let result = store.applyProgress(to: store.makeDailyChallenges(), type: .cardsCompleted, value: 3)
        #expect(result.newlyCompleted.isEmpty)
        #expect(result.challenges.first { $0.type == .cardsCompleted }!.currentValue == 3)
    }

    @Test func challengeNeedsRefreshWhenEmptyOrExpired() {
        let store = ChallengeStore()
        #expect(store.needsRefresh([]))                       // empty → refresh
        #expect(!store.needsRefresh(store.makeDailyChallenges())) // fresh → no refresh
        let expired = [DailyChallenge(title: "T", description: "D", targetValue: 5, currentValue: 0,
                                      xpReward: 10, isCompleted: false, type: .cardsCompleted,
                                      expiresAt: Date().addingTimeInterval(-3600))]
        #expect(store.needsRefresh(expired))                  // expired → refresh
    }

    @Test func mysteryBoxStoreMakesThreeToFiveBoxes() {
        let boxes = MysteryBoxStore().makeBoxes()
        #expect(boxes.count >= 3 && boxes.count <= 5)
        #expect(boxes.allSatisfy { !$0.isOpened && $0.xpAmount > 0 })
    }

    // MARK: - AchievementEvaluator unlock conditions

    private func progress(cards: Int = 0, correct: Int = 0, streak: Int = 0) -> UserProgress {
        var p = UserProgress()
        p.totalCardsCompleted = cards
        p.totalCorrectAnswers = correct
        p.currentStreak = streak
        return p
    }

    @Test func progressBasedUnlockConditions() {
        let eval = AchievementEvaluator()
        #expect(eval.isConditionMet(title: "First Steps", progress: progress(cards: 1), hour: 12))
        #expect(!eval.isConditionMet(title: "First Steps", progress: progress(cards: 0), hour: 12))
        #expect(eval.isConditionMet(title: "Scholar", progress: progress(cards: 100), hour: 12))
        #expect(!eval.isConditionMet(title: "Scholar", progress: progress(cards: 99), hour: 12))
        #expect(eval.isConditionMet(title: "Perfectionist", progress: progress(correct: 25), hour: 12))
        #expect(eval.isConditionMet(title: "Streak Master", progress: progress(streak: 7), hour: 12))
        #expect(!eval.isConditionMet(title: "Streak Master", progress: progress(streak: 6), hour: 12))
    }

    @Test func timeBasedUnlockConditionsAreDeterministic() {
        let eval = AchievementEvaluator()
        let p = progress()
        // Night Owl: hour >= 23 || hour <= 5
        #expect(eval.isConditionMet(title: "Night Owl", progress: p, hour: 23))
        #expect(eval.isConditionMet(title: "Night Owl", progress: p, hour: 3))
        #expect(!eval.isConditionMet(title: "Night Owl", progress: p, hour: 12))
        // Early Bird: hour 5...8
        #expect(eval.isConditionMet(title: "Early Bird", progress: p, hour: 6))
        #expect(eval.isConditionMet(title: "Early Bird", progress: p, hour: 8))
        #expect(!eval.isConditionMet(title: "Early Bird", progress: p, hour: 9))
    }

    @Test func newlyUnlockableSkipsAlreadyUnlocked() {
        let eval = AchievementEvaluator()
        var catalog = eval.catalog(progress: progress())   // all locked at zero progress
        // Inject a noon time so the time-based ones don't fire.
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let p = progress(cards: 1)
        let first = eval.newlyUnlockableIndices(in: catalog, progress: p, now: noon)
        #expect(first.contains { catalog[$0].title == "First Steps" })

        // Mark First Steps unlocked → it should no longer be reported.
        if let idx = catalog.firstIndex(where: { $0.title == "First Steps" }) {
            catalog[idx].isUnlocked = true
        }
        let second = eval.newlyUnlockableIndices(in: catalog, progress: p, now: noon)
        #expect(!second.contains { catalog[$0].title == "First Steps" })
    }

    @Test func catalogSeedsAlreadyEarnedProgressAchievements() {
        let eval = AchievementEvaluator()
        let catalog = eval.catalog(progress: progress(cards: 100, correct: 25, streak: 7))
        #expect(catalog.first { $0.title == "Scholar" }?.isUnlocked == true)
        #expect(catalog.first { $0.title == "Perfectionist" }?.isUnlocked == true)
        #expect(catalog.first { $0.title == "Streak Master" }?.isUnlocked == true)
        // Time-based ones are never seeded as unlocked.
        #expect(catalog.first { $0.title == "Night Owl" }?.isUnlocked == false)
    }
}

// MARK: - GeminiClient networking tests

/// A `URLProtocol` that returns a canned response, so `GeminiClient` can be exercised
/// without a real network. Each test sets `StubURLProtocol.handler` before constructing
/// its session; `.serialized` on the suite avoids cross-test handler races.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@Suite(.serialized)
struct GeminiClientTests {
    private func makeClient() -> GeminiClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return GeminiClient(session: URLSession(configuration: config), apiKey: "test-key")
    }

    private func respond(status: Int, body: String) {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
    }

    @Test func returnsTrimmedTextOnValidResponse() async throws {
        respond(status: 200, body: """
        {"candidates":[{"content":{"parts":[{"text":"  hello world  "}]}}]}
        """)
        let client = makeClient()
        let text = try await client.generateText(prompt: "p", maxOutputTokens: 10)
        #expect(text == "hello world")
    }

    @Test func throwsHttpStatusOnNon200() async {
        respond(status: 503, body: "{}")
        let client = makeClient()
        await #expect(throws: APIError.httpStatus(503)) {
            try await client.generateText(prompt: "p", maxOutputTokens: 10)
        }
    }

    @Test func throwsEmptyResponseWhenNoCandidates() async {
        respond(status: 200, body: #"{"candidates":[]}"#)
        let client = makeClient()
        await #expect(throws: APIError.emptyResponse) {
            try await client.generateText(prompt: "p", maxOutputTokens: 10)
        }
    }

    @Test func throwsDecodingOnMalformedJSON() async {
        respond(status: 200, body: "not json at all")
        let client = makeClient()
        // .decoding carries a message string, so match the case rather than equality.
        do {
            _ = try await client.generateText(prompt: "p", maxOutputTokens: 10)
            Issue.record("expected a decoding error")
        } catch let error as APIError {
            if case .decoding = error { } else {
                Issue.record("expected .decoding, got \(error)")
            }
        } catch {
            Issue.record("expected APIError, got \(error)")
        }
    }
}
