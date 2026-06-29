/// ReviewScheduler.swift
///
/// Pure, dependency-free spaced-repetition scheduling. A card becomes eligible for review
/// once it's been marked understood; after each review it's deferred by a widening interval
/// (1 → 3 → 7 → 14 → 30 days) based on how many times it's already been reviewed. Kept
/// separate from any view/manager so the "is this card due?" decision is unit-testable.
import Foundation

enum ReviewScheduler {
    /// Days to wait after the Nth review before a card is due again. The index is the
    /// card's `reviewCount`; counts past the end clamp to the last (longest) interval.
    static let intervalsInDays = [1, 3, 7, 14, 30]

    /// Whether a single card is due for review as of `referenceDate`.
    /// - A card must be understood to enter the review pool.
    /// - A never-reviewed (`lastReviewedAt == nil`) understood card is immediately due.
    /// - Otherwise it's due once `intervalsInDays[reviewCount]` days have elapsed.
    static func isDue(_ card: Flashcard,
                      asOf referenceDate: Date = Date(),
                      calendar: Calendar = .current) -> Bool {
        guard card.isUnderstood else { return false }
        guard let last = card.lastReviewedAt else { return true }

        let index = min(max(card.reviewCount, 0), intervalsInDays.count - 1)
        let waitDays = intervalsInDays[index]
        guard let dueDate = calendar.date(byAdding: .day, value: waitDays, to: last) else {
            return true
        }
        return referenceDate >= dueDate
    }

    /// Filters a card list to those due for review, preserving order.
    static func dueCards(from cards: [Flashcard],
                         asOf referenceDate: Date = Date(),
                         calendar: Calendar = .current) -> [Flashcard] {
        cards.filter { isDue($0, asOf: referenceDate, calendar: calendar) }
    }
}
