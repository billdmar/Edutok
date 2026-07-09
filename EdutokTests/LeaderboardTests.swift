//
//  LeaderboardTests.swift
//  EdutokTests
//
//  Leaderboard ranking tests.
//

import Foundation
import Testing

@testable import Edutok

struct LeaderboardTests {
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
}
