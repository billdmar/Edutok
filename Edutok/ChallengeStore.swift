/// ChallengeStore.swift
///
/// Daily-challenge generation, progress math, expiry, and persistence — extracted from
/// `GamificationManager`. Stateless like `MysteryBoxStore`: it operates on a passed-in
/// `[DailyChallenge]` and returns the new array plus the challenges that *just* completed,
/// so `GamificationManager` keeps the `@Published var dailyChallenges` the views bind to and
/// performs the side effects (XP, toast, particles, Firebase) for completions.
import Foundation

struct ChallengeStore {
    private let userDefaultsKey = "DailyChallenges"

    /// Result of advancing challenge progress: the updated set + the challenges that crossed
    /// their target on this update (for the caller to reward).
    struct ProgressResult {
        let challenges: [DailyChallenge]
        let newlyCompleted: [DailyChallenge]
    }

    /// The day's fresh challenge set, expiring at the start of tomorrow.
    func makeDailyChallenges(now: Date = Date(), calendar: Calendar = .current) -> [DailyChallenge] {
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        return [
            DailyChallenge(title: "Card Master", description: "Complete 15 flashcards today",
                           targetValue: 15, currentValue: 0, xpReward: 50, isCompleted: false,
                           type: .cardsCompleted, expiresAt: tomorrow),
            DailyChallenge(title: "Perfect Score", description: "Get 10 correct answers in a row",
                           targetValue: 10, currentValue: 0, xpReward: 75, isCompleted: false,
                           type: .correctAnswers, expiresAt: tomorrow),
            DailyChallenge(title: "Topic Explorer", description: "Explore 3 new topics today",
                           targetValue: 3, currentValue: 0, xpReward: 100, isCompleted: false,
                           type: .topicsExplored, expiresAt: tomorrow)
        ]
    }

    /// Whether a set needs regenerating (empty or any challenge expired).
    func needsRefresh(_ challenges: [DailyChallenge]) -> Bool {
        challenges.isEmpty || challenges.contains { $0.isExpired }
    }

    /// Advances every matching, not-yet-completed challenge by `value` (clamped to target),
    /// marking newly-crossed ones complete. Pure — returns the updated set and the
    /// completions for the caller to reward. (Caller should refresh an expired set first.)
    func applyProgress(to challenges: [DailyChallenge], type: ChallengeType, value: Int) -> ProgressResult {
        adjust(challenges, type: type) { current, target in min(current + value, target) }
    }

    /// Like `applyProgress`, but SETS each matching challenge's progress to an absolute value
    /// (clamped to target) instead of incrementing — for "in a row" challenges that mirror a
    /// streak which can drop back to a lower value (or 0) on a wrong answer.
    func setProgress(to challenges: [DailyChallenge], type: ChallengeType, value: Int) -> ProgressResult {
        adjust(challenges, type: type) { _, target in min(max(value, 0), target) }
    }

    /// Shared core: apply `newValue(currentValue, targetValue)` to each matching, not-yet-
    /// completed challenge, marking newly-crossed ones complete.
    private func adjust(_ challenges: [DailyChallenge], type: ChallengeType,
                        _ newValue: (Int, Int) -> Int) -> ProgressResult {
        var updated = challenges
        var completed: [DailyChallenge] = []
        for index in updated.indices where updated[index].type == type && !updated[index].isCompleted {
            updated[index].currentValue = newValue(updated[index].currentValue, updated[index].targetValue)
            if updated[index].currentValue >= updated[index].targetValue {
                updated[index].isCompleted = true
                completed.append(updated[index])
            }
        }
        return ProgressResult(challenges: updated, newlyCompleted: completed)
    }

    func save(_ challenges: [DailyChallenge]) {
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(challenges), forKey: userDefaultsKey)
        } catch {
            #if DEBUG
            print("Error saving daily challenges: \(error)")
            #endif
        }
    }

    /// Loads persisted challenges, or `nil` if none stored.
    func load() -> [DailyChallenge]? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        do {
            return try JSONDecoder().decode([DailyChallenge].self, from: data)
        } catch {
            #if DEBUG
            print("Error loading daily challenges: \(error)")
            #endif
            return nil
        }
    }
}
