//
//  AchievementTests.swift
//  EdutokTests
//
//  AchievementEvaluator tests.
//

import Foundation
import Testing

@testable import Edutok

struct AchievementTests {
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
