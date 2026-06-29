/// StreakCalculator.swift
///
/// Pure, dependency-free streak math, extracted from `FirebaseManager` so it can be
/// unit-tested without Firebase or the network.
///
/// The streak is **recomputed from the set of active days** rather than incremented
/// per event. This makes it idempotent: flipping fifty cards in one day advances the
/// streak by at most one, where the previous `+= 1`-per-event logic would have counted
/// the streak to fifty.
import Foundation

/// Computes learning streaks from a user's daily activity.
enum StreakCalculator {
    /// The current streak: the number of consecutive days with activity ending on
    /// `referenceDate`. Returns `0` when there is no activity on `referenceDate`,
    /// matching the rule that a streak is only "alive" if you studied today.
    ///
    /// - Parameters:
    ///   - stats: the user's daily stats (order and duplicates don't matter).
    ///   - referenceDate: the day to measure up to (defaults to now).
    ///   - calendar: injected for testability (defaults to `.current`).
    static func currentStreak(
        from stats: [DailyStat],
        asOf referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let activeDays = activeDaySet(from: stats, calendar: calendar)
        let today = calendar.startOfDay(for: referenceDate)

        // A streak is only alive if there's activity today.
        guard activeDays.contains(today) else { return 0 }

        var streak = 0
        var day = today
        while activeDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// The longest streak: the previously recorded longest, raised to the current
    /// streak if today's run now exceeds it. Never decreases.
    static func longestStreak(
        from stats: [DailyStat],
        previousLongest: Int,
        asOf referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        max(previousLongest, currentStreak(from: stats, asOf: referenceDate, calendar: calendar))
    }

    /// The set of distinct start-of-day dates on which the user had any activity.
    private static func activeDaySet(from stats: [DailyStat], calendar: Calendar) -> Set<Date> {
        var days = Set<Date>()
        for stat in stats where stat.hasActivity {
            days.insert(calendar.startOfDay(for: stat.date))
        }
        return days
    }
}
