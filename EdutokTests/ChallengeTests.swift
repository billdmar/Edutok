//
//  ChallengeTests.swift
//  EdutokTests
//
//  Daily challenge tests — progress, expiry, and ChallengeStore logic.
//

import Foundation
import Testing

@testable import Edutok

struct ChallengeTests {
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

    // MARK: - ChallengeStore progress logic

    @Test func challengeProgressAdvancesMatchingTypeAndClamps() {
        let store = ChallengeStore()
        let challenges = store.makeDailyChallenges()
        // Card Master targets 15 cardsCompleted; advance by 20 → clamps to 15 and completes.
        let result = store.applyProgress(to: challenges, type: .cardsCompleted, value: 20)
        let cardChallenge = result.challenges.first { $0.type == .cardsCompleted }!
        #expect(cardChallenge.currentValue == 15)
        #expect(cardChallenge.isCompleted)
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

    // MARK: - "In a row" challenge progress (absolute set + reset)

    @Test func setProgressMirrorsStreakAndCanDropToZero() {
        let store = ChallengeStore()
        let base = store.makeDailyChallenges()
        // Streak climbs to 7 (target 10) → not complete, currentValue tracks the streak.
        let at7 = store.setProgress(to: base, type: .correctAnswers, value: 7)
        let perfect7 = at7.challenges.first { $0.type == .correctAnswers }!
        #expect(perfect7.currentValue == 7)
        #expect(!perfect7.isCompleted)
        // A wrong answer resets the streak → challenge progress drops back to 0.
        let at0 = store.setProgress(to: at7.challenges, type: .correctAnswers, value: 0)
        #expect(at0.challenges.first { $0.type == .correctAnswers }!.currentValue == 0)
    }

    @Test func setProgressCompletesAtTenInARow() {
        let store = ChallengeStore()
        let result = store.setProgress(to: store.makeDailyChallenges(), type: .correctAnswers, value: 10)
        #expect(result.newlyCompleted.contains { $0.type == .correctAnswers })
    }
}
