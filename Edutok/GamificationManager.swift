/// GamificationManager.swift
///
/// Drives all reward mechanics: XP and levelling, daily challenges, mystery boxes,
/// achievements, XP-gain/level-up/particle animations, and local notifications.
/// XP follows a quadratic level curve (see `UserProgress`); awarding XP returns whether
/// the user levelled up so the manager can trigger the level-up celebration. All
/// progress is persisted to `UserDefaults` and key milestones are mirrored to Firebase.
import Foundation
import SwiftUI

/// Observable, main-actor store of the player's progression and reward state.
@MainActor
class GamificationManager: ObservableObject {
    @Published var userProgress = UserProgress()
    @Published var recentXPGains: [XPGainEvent] = []
    @Published var shouldShowLevelUp = false
    @Published var shouldShowAchievement = false
    @Published var newAchievement: CustomAchievement?
    @Published var particleEffects: [ParticleEffect] = []

    // NEW: Phase 1 features
    @Published var dailyChallenges: [DailyChallenge] = []
    @Published var availableMysteryBoxes: [MysteryBox] = []
    @Published var enhancedAchievements: [EnhancedAchievement] = []
    @Published var shouldShowMysteryBox = false
    @Published var currentMysteryBox: MysteryBox?

    private let userDefaultsKey = "UserProgress"
    private let challengeStore = ChallengeStore()
    private let mysteryBoxStore = MysteryBoxStore()
    private let enhancedAchievementsKey = "EnhancedAchievements"
    private let notifications = NotificationScheduler()
    private var topicExploredObserver: NSObjectProtocol?

    init() {
        loadProgress()
        loadDailyChallenges()
        loadMysteryBoxes()
        loadEnhancedAchievements()
        notifications.requestPermission()

        // Generate new daily challenges if needed
        if dailyChallenges.isEmpty || dailyChallenges.first?.isExpired == true {
            generateDailyChallenges()
        }

        // Generate mystery boxes if none available
        if availableMysteryBoxes.isEmpty {
            generateMysteryBoxes()
        }

        // NEW: Listen for topic exploration notifications
        setupNotificationListeners()

        // Check enhanced achievements after loading progress
        checkEnhancedAchievements()
    }

    // NEW: Setup notification listeners for cross-component communication
    private func setupNotificationListeners() {
        topicExploredObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TopicExplored"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateChallengeProgress(type: .topicsExplored)
        }
    }

    deinit {
        if let observer = topicExploredObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Daily Challenges

    /// Creates the day's set of daily challenges, each with a target, XP reward, and expiry.
    func generateDailyChallenges() {
        dailyChallenges = challengeStore.makeDailyChallenges()
        challengeStore.save(dailyChallenges)
    }

    /// Regenerates the daily challenges if the current set has expired (e.g. the app was
    /// left open past midnight). Safe to call often — it no-ops when challenges are current.
    func refreshDailyChallengesIfNeeded() {
        if challengeStore.needsRefresh(dailyChallenges) {
            generateDailyChallenges()
        }
    }

    func updateChallengeProgress(type: ChallengeType, value: Int = 1) {
        // Don't credit progress against a stale (expired) challenge set.
        refreshDailyChallengesIfNeeded()

        let result = challengeStore.applyProgress(to: dailyChallenges, type: type, value: value)
        dailyChallenges = result.challenges

        // Reward each challenge that just completed (XP/toast/particle/Firebase side effects).
        for challenge in result.newlyCompleted {
            completeChallenge(challenge)
        }

        challengeStore.save(dailyChallenges)
    }

    private func completeChallenge(_ challenge: DailyChallenge) {
        // Award XP
        let didLevelUp = userProgress.addXP(challenge.xpReward)

        if didLevelUp {
            showLevelUpAnimation()
        }

        // Show completion notification
        showChallengeCompletion(challenge)

        // Track in Firebase
        Task {
            await FirebaseManager.shared.trackAchievement("daily_challenge_\(challenge.type.rawValue)")
        }
    }

    private func showChallengeCompletion(_ challenge: DailyChallenge) {
        // Add particle effect
        addParticleEffect(.achievement)

        // Show achievement notification
        newAchievement = CustomAchievement(
            title: challenge.title,
            description: "Daily Challenge Completed!",
            xpReward: challenge.xpReward,
            emoji: "🎯"
        )
        shouldShowAchievement = true

        // Hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.shouldShowAchievement = false
        }
    }

    // MARK: - Mystery Boxes

    func generateMysteryBoxes() {
        availableMysteryBoxes = mysteryBoxStore.makeBoxes()
        mysteryBoxStore.save(availableMysteryBoxes)
    }

    /// Opens a mystery box: reveals and awards its XP, marks it opened, and persists state.
    func openMysteryBox(_ box: MysteryBox) {
        guard let index = availableMysteryBoxes.firstIndex(where: { $0.id == box.id }),
              !availableMysteryBoxes[index].isOpened else { return }

        // Mark as opened
        availableMysteryBoxes[index].isOpened = true
        availableMysteryBoxes[index].openedAt = Date()

        // Award XP
        let didLevelUp = userProgress.addXP(box.xpAmount)
        if didLevelUp {
            showLevelUpAnimation()
        }

        // Show mystery box animation
        currentMysteryBox = availableMysteryBoxes[index]
        shouldShowMysteryBox = true

        // Add particle effect
        addParticleEffect(.achievement)

        // Hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.shouldShowMysteryBox = false
        }

        mysteryBoxStore.save(availableMysteryBoxes)

        // Track in Firebase
        Task {
            await FirebaseManager.shared.trackAchievement("mystery_box_\(box.rarity.rawValue)")
        }
    }

    // MARK: - Enhanced Achievements

    func loadEnhancedAchievements() {
        enhancedAchievements = [
            EnhancedAchievement(
                title: "First Steps",
                description: "Complete your first flashcard",
                xpReward: 25,
                icon: "1.circle.fill",
                rarity: .common,
                isUnlocked: userProgress.totalCardsCompleted >= 1,
                unlockedAt: nil,
                category: .learning
            ),
            EnhancedAchievement(
                title: "Scholar",
                description: "Complete 100 flashcards",
                xpReward: 100,
                icon: "graduationcap.fill",
                rarity: .rare,
                isUnlocked: userProgress.totalCardsCompleted >= 100,
                unlockedAt: nil,
                category: .learning
            ),
            EnhancedAchievement(
                title: "Perfectionist",
                description: "Get 25 perfect answers",
                xpReward: 150,
                icon: "star.fill",
                rarity: .epic,
                isUnlocked: userProgress.totalCorrectAnswers >= 25,
                unlockedAt: nil,
                category: .learning
            ),
            EnhancedAchievement(
                title: "Night Owl",
                description: "Study after 11 PM",
                xpReward: 75,
                icon: "moon.fill",
                rarity: .rare,
                isUnlocked: false,
                unlockedAt: nil,
                category: .time
            ),
            EnhancedAchievement(
                title: "Early Bird",
                description: "Study before 8 AM",
                xpReward: 75,
                icon: "sunrise.fill",
                rarity: .rare,
                isUnlocked: false,
                unlockedAt: nil,
                category: .time
            ),
            EnhancedAchievement(
                title: "Streak Master",
                description: "Maintain a 7-day learning streak",
                xpReward: 200,
                icon: "flame.fill",
                rarity: .epic,
                isUnlocked: userProgress.currentStreak >= 7,
                unlockedAt: nil,
                category: .time
            )
        ]

        saveEnhancedAchievements()
    }

    func checkEnhancedAchievements() {
        let hour = Calendar.current.component(.hour, from: Date())

        for index in enhancedAchievements.indices {
            let achievement = enhancedAchievements[index]

            if !achievement.isUnlocked {
                var shouldUnlock = false

                switch achievement.title {
                case "First Steps":
                    shouldUnlock = userProgress.totalCardsCompleted >= 1
                case "Scholar":
                    shouldUnlock = userProgress.totalCardsCompleted >= 100
                case "Perfectionist":
                    shouldUnlock = userProgress.totalCorrectAnswers >= 25
                case "Night Owl":
                    shouldUnlock = hour >= 23 || hour <= 5
                case "Early Bird":
                    shouldUnlock = hour >= 5 && hour <= 8
                case "Streak Master":
                    shouldUnlock = userProgress.currentStreak >= 7
                default:
                    shouldUnlock = false
                }

                if shouldUnlock {
                    unlockEnhancedAchievement(index)
                }
            }
        }
    }

    private func unlockEnhancedAchievement(_ index: Int) {
        enhancedAchievements[index].isUnlocked = true
        enhancedAchievements[index].unlockedAt = Date()

        // Award XP
        let xpReward = enhancedAchievements[index].xpReward
        let didLevelUp = userProgress.addXP(xpReward)
        if didLevelUp {
            showLevelUpAnimation()
        }

        // Show achievement notification
        newAchievement = CustomAchievement(
            title: enhancedAchievements[index].title,
            description: enhancedAchievements[index].description,
            xpReward: xpReward,
            emoji: "🏆"
        )
        shouldShowAchievement = true

        // Add particle effect
        addParticleEffect(.achievement)

        // Hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.shouldShowAchievement = false
        }

        saveEnhancedAchievements()

        // Track in Firebase
        Task {
            await FirebaseManager.shared.trackAchievement(enhancedAchievements[index].title.lowercased().replacingOccurrences(of: " ", with: "_"))
        }
    }

    // MARK: - XP System

    /// Adds the reward's XP, optionally shows a transient XP-gain animation, and—if the
    /// XP pushed the user to a new level—triggers the level-up celebration and Firebase
    /// milestone tracking. Persists progress afterward.
    func awardXP(_ reward: XPReward, animated: Bool = true) {
        let xpAmount = reward.rawValue
        let didLevelUp = userProgress.addXP(xpAmount)

        if animated {
            // Add XP gain event for animation
            let xpEvent = XPGainEvent(
                amount: xpAmount,
                reason: reward.description,
                emoji: reward.emoji
            )
            recentXPGains.append(xpEvent)

            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if let index = self.recentXPGains.firstIndex(where: { $0.id == xpEvent.id }) {
                    self.recentXPGains.remove(at: index)
                }
            }
        }

        if didLevelUp {
            showLevelUpAnimation()
            notifications.scheduleEncouragement(level: userProgress.currentLevel)

            // Track level up achievement in Firebase
            Task {
                await FirebaseManager.shared.trackAchievement("level_\(userProgress.currentLevel)")
            }
        }

        saveProgress()
    }

    /// Pure XP math for finishing a card: base completion XP plus bonuses for a correct
    /// answer, a first-try "perfect" card, and a fast (<5s) answer. Extracted as a
    /// `nonisolated static` function so it's unit-testable without the manager/UI.
    nonisolated static func cardCompletionXP(wasCorrect: Bool,
                                             isFirstTry: Bool,
                                             timeToAnswer: TimeInterval) -> Int {
        var total = XPReward.cardCompleted.rawValue
        if wasCorrect {
            total += XPReward.correctAnswer.rawValue
            if isFirstTry { total += XPReward.perfectCard.rawValue }
            if timeToAnswer < 5.0 { total += XPReward.speedBonus.rawValue }
        }
        return total
    }

    /// Awards the combined XP for finishing a card: base completion XP plus bonuses for
    /// a correct answer, a first-try "perfect" card, and a fast answer (speed bonus).
    func awardXPForCardCompletion(wasCorrect: Bool, isFirstTry: Bool, timeToAnswer: TimeInterval) {
        // Base XP for completing card
        awardXP(.cardCompleted, animated: false)

        if wasCorrect {
            awardXP(.correctAnswer, animated: false)
            if isFirstTry {
                awardXP(.perfectCard, animated: false)
            }
            // Speed bonus for answers under 5 seconds
            if timeToAnswer < 5.0 {
                awardXP(.speedBonus, animated: false)
            }
        }

        let totalXP = Self.cardCompletionXP(wasCorrect: wasCorrect,
                                            isFirstTry: isFirstTry,
                                            timeToAnswer: timeToAnswer)

        // Show combined XP gain
        let combinedEvent = XPGainEvent(
            amount: totalXP,
            reason: wasCorrect ? (isFirstTry ? "Perfect Answer!" : "Correct!") : "Keep Learning!",
            emoji: wasCorrect ? (isFirstTry ? "🌟" : "✅") : "💪"
        )
        recentXPGains.append(combinedEvent)

        // Update user stats
        userProgress.totalCardsCompleted += 1
        if wasCorrect {
            userProgress.totalCorrectAnswers += 1
        }

        // Update challenge progress
        updateChallengeProgress(type: .cardsCompleted)
        if wasCorrect {
            updateChallengeProgress(type: .correctAnswers)
        }

        // Check achievements (single source of truth — the enhanced system).
        checkEnhancedAchievements()

        // Add particle effects
        if wasCorrect {
            addParticleEffect(isFirstTry ? .perfectAnswer : .correctAnswer)
        }

        saveProgress()
    }

    // MARK: - Particle Effects

    func addParticleEffect(_ type: ParticleType) {
        let effect = ParticleEffect(type: type)
        particleEffects.append(effect)

        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + effect.duration) {
            if let index = self.particleEffects.firstIndex(where: { $0.id == effect.id }) {
                self.particleEffects.remove(at: index)
            }
        }
    }

    // MARK: - Level Up Animation

    private func showLevelUpAnimation() {
        shouldShowLevelUp = true
        addParticleEffect(.levelUp)

        // Hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.shouldShowLevelUp = false
        }
    }

    // MARK: - Persistence

    private func saveProgress() {
        do {
            let data = try JSONEncoder().encode(userProgress)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error saving user progress: \(error)")
        }
    }

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }

        do {
            userProgress = try JSONDecoder().decode(UserProgress.self, from: data)
        } catch {
            print("Error loading user progress: \(error)")
            userProgress = UserProgress() // Reset to default
        }
    }

    private func loadDailyChallenges() {
        if let challenges = challengeStore.load() {
            dailyChallenges = challenges
        }
    }

    private func loadMysteryBoxes() {
        if let boxes = mysteryBoxStore.load() {
            availableMysteryBoxes = boxes
        }
    }

    private func saveEnhancedAchievements() {
        do {
            let data = try JSONEncoder().encode(enhancedAchievements)
            UserDefaults.standard.set(data, forKey: enhancedAchievementsKey)
        } catch {
            print("Error saving enhanced achievements: \(error)")
        }
    }

    // MARK: - Smart Push Notifications
    // Scheduling lives in `NotificationScheduler`; these thin pass-throughs preserve the
    // call sites (e.g. App.swift) and the manager's public surface.

    func scheduleStudyReminder() {
        notifications.scheduleStudyReminder()
    }

    func scheduleStreakWarning(streakDays: Int) {
        notifications.scheduleStreakWarning(streakDays: streakDays)
    }
}

// MARK: - Supporting Models

struct XPGainEvent: Identifiable {
    let id = UUID()
    let amount: Int
    let reason: String
    let emoji: String
    let timestamp = Date()
}

struct ParticleEffect: Identifiable {
    let id = UUID()
    let type: ParticleType
    let duration: TimeInterval

    init(type: ParticleType) {
        self.type = type
        self.duration = type.duration
    }
}

enum ParticleType {
    case correctAnswer
    case perfectAnswer
    case levelUp
    case achievement

    var duration: TimeInterval {
        switch self {
        case .correctAnswer: return 1.5
        case .perfectAnswer: return 2.5
        case .levelUp: return 4.0
        case .achievement: return 3.0
        }
    }

    var particleCount: Int {
        switch self {
        case .correctAnswer: return 15
        case .perfectAnswer: return 30
        case .levelUp: return 50
        case .achievement: return 40
        }
    }

    var colors: [Color] {
        switch self {
        case .correctAnswer: return [.green, .mint]
        case .perfectAnswer: return [.yellow, .orange, .pink]
        case .levelUp: return [.purple, .blue, .pink]
        case .achievement: return [.gold, .yellow, .orange]
        }
    }
}
