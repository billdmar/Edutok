/// AchievementEvaluator.swift
///
/// Enhanced-achievement catalog, unlock evaluation, and persistence — extracted from
/// `GamificationManager` following the same stateless-helper pattern as `ChallengeStore` /
/// `MysteryBoxStore`. The unlock conditions are a **pure** function with an injected `now`,
/// so the time-based achievements (Night Owl / Early Bird) are deterministic and testable.
/// `GamificationManager` keeps `@Published var enhancedAchievements` and performs the unlock
/// side effects (XP, toast, particles, Firebase).
///
/// This also fixes a real bug: the manager previously rebuilt the catalog from scratch every
/// launch and never loaded the persisted array, so unlock timestamps were lost on restart.
/// `load()` now restores saved unlocks.
import Foundation

struct AchievementEvaluator {
    private let userDefaultsKey = "EnhancedAchievements"

    /// The fixed achievement catalog. `progress` seeds the already-satisfied progress-based
    /// achievements as unlocked on first build (matching the original behavior).
    func catalog(progress: UserProgress) -> [EnhancedAchievement] {
        [
            EnhancedAchievement(title: "First Steps", description: "Complete your first flashcard",
                                xpReward: 25, icon: "1.circle.fill", rarity: .common,
                                isUnlocked: progress.totalCardsCompleted >= 1, unlockedAt: nil, category: .learning),
            EnhancedAchievement(title: "Scholar", description: "Complete 100 flashcards",
                                xpReward: 100, icon: "graduationcap.fill", rarity: .rare,
                                isUnlocked: progress.totalCardsCompleted >= 100, unlockedAt: nil, category: .learning),
            EnhancedAchievement(title: "Perfectionist", description: "Get 25 perfect answers",
                                xpReward: 150, icon: "star.fill", rarity: .epic,
                                isUnlocked: progress.totalCorrectAnswers >= 25, unlockedAt: nil, category: .learning),
            EnhancedAchievement(title: "Night Owl", description: "Study after 11 PM",
                                xpReward: 75, icon: "moon.fill", rarity: .rare,
                                isUnlocked: false, unlockedAt: nil, category: .time),
            EnhancedAchievement(title: "Early Bird", description: "Study before 8 AM",
                                xpReward: 75, icon: "sunrise.fill", rarity: .rare,
                                isUnlocked: false, unlockedAt: nil, category: .time),
            EnhancedAchievement(title: "Streak Master", description: "Maintain a 7-day learning streak",
                                xpReward: 200, icon: "flame.fill", rarity: .epic,
                                isUnlocked: progress.currentStreak >= 7, unlockedAt: nil, category: .time)
        ]
    }

    /// Whether a given achievement's unlock condition is met. Pure; `hour` is the local hour
    /// (0–23) so time-based achievements are deterministic in tests.
    func isConditionMet(title: String, progress: UserProgress, hour: Int) -> Bool {
        switch title {
        case "First Steps": return progress.totalCardsCompleted >= 1
        case "Scholar": return progress.totalCardsCompleted >= 100
        case "Perfectionist": return progress.totalCorrectAnswers >= 25
        case "Night Owl": return hour >= 23 || hour <= 5
        case "Early Bird": return hour >= 5 && hour <= 8
        case "Streak Master": return progress.currentStreak >= 7
        default: return false
        }
    }

    /// Indices of currently-locked achievements whose condition is now met (i.e. should be
    /// unlocked). Pure — `now` is injected so the time-based checks are deterministic.
    func newlyUnlockableIndices(in achievements: [EnhancedAchievement],
                                progress: UserProgress,
                                now: Date = Date(),
                                calendar: Calendar = .current) -> [Int] {
        let hour = calendar.component(.hour, from: now)
        return achievements.indices.filter { index in
            !achievements[index].isUnlocked
                && isConditionMet(title: achievements[index].title, progress: progress, hour: hour)
        }
    }

    func save(_ achievements: [EnhancedAchievement]) {
        do {
            UserDefaults.standard.set(try JSONEncoder().encode(achievements), forKey: userDefaultsKey)
        } catch {
            #if DEBUG
            print("Error saving enhanced achievements: \(error)")
            #endif
        }
    }

    /// Restores persisted achievements (with their unlock timestamps), or `nil` if none stored.
    func load() -> [EnhancedAchievement]? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        do {
            return try JSONDecoder().decode([EnhancedAchievement].self, from: data)
        } catch {
            #if DEBUG
            print("Error loading enhanced achievements: \(error)")
            #endif
            return nil
        }
    }
}
