//
//  StreakTests.swift
//  EdutokTests
//
//  StreakCalculator tests.
//

import Foundation
import Testing

@testable import Edutok

struct StreakTests {
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
}
