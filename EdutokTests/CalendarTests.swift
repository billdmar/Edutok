//
//  CalendarTests.swift
//  EdutokTests
//
//  Calendar activity-level bucketing tests.
//

import Foundation
import Testing

@testable import Edutok

struct CalendarTests {
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
}
