/// MysteryBoxStore.swift
///
/// Mystery-box generation, rarity distribution, and persistence — extracted from
/// `GamificationManager` so the reward manager isn't also the box factory + storage layer.
/// This is a **stateless** helper: it returns values and reads/writes `UserDefaults`, but it
/// does NOT own the `@Published` array (that stays on `GamificationManager`, which the views
/// bind to). `GamificationManager` remains the side-effect coordinator (XP, animation,
/// Firebase). Keeping the helper stateless avoids any chance of the published array drifting
/// out of sync with a second copy.
import Foundation

struct MysteryBoxStore {
    private let userDefaultsKey = "MysteryBoxes"

    /// Maps a uniform [0,1) value onto the rarity distribution
    /// (50% common / 30% rare / 15% epic / 5% legendary). Pure + testable without RNG.
    nonisolated static func rarity(for value: Double) -> BoxRarity {
        switch value {
        case ..<0.5: return .common       // 50% chance
        case ..<0.8: return .rare         // 30% chance
        case ..<0.95: return .epic        // 15% chance
        default: return .legendary        // 5% chance
        }
    }

    /// Generates 3–5 unopened boxes, each with a random rarity and an XP amount drawn from
    /// that rarity's range.
    func makeBoxes() -> [MysteryBox] {
        let count = Int.random(in: 3...5)
        return (0..<count).map { _ in
            let rarity = Self.rarity(for: Double.random(in: 0...1))
            return MysteryBox(xpAmount: Int.random(in: rarity.xpRange),
                              rarity: rarity, isOpened: false, openedAt: nil)
        }
    }

    func save(_ boxes: [MysteryBox]) {
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(boxes), forKey: userDefaultsKey)
        } catch {
            #if DEBUG
            print("Error saving mystery boxes: \(error)")
            #endif
        }
    }

    /// Loads persisted boxes, or `nil` if none are stored (caller decides whether to generate).
    func load() -> [MysteryBox]? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        do {
            return try JSONDecoder().decode([MysteryBox].self, from: data)
        } catch {
            #if DEBUG
            print("Error loading mystery boxes: \(error)")
            #endif
            return nil
        }
    }
}
