import Foundation
import SwiftUI
import UserNotifications

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
    private let challengesKey = "DailyChallenges"
    private let mysteryBoxesKey = "MysteryBoxes"
    private let enhancedAchievementsKey = "EnhancedAchievements"
    private let notificationCenter = UNUserNotificationCenter.current()
    private var topicExploredObserver: NSObjectProtocol?
   
    
    init() {
        loadProgress()
        loadDailyChallenges()
        loadMysteryBoxes()
        loadEnhancedAchievements()
        requestNotificationPermission()
        
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
        ) { _ in
            self.updateChallengeProgress(type: .topicsExplored)
        }
    }
    
    deinit {
        if let observer = topicExploredObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Daily Challenges
    
    func generateDailyChallenges() {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        
        dailyChallenges = [
            DailyChallenge(
                title: "Card Master",
                description: "Complete 15 flashcards today",
                targetValue: 15,
                currentValue: 0,
                xpReward: 50,
                isCompleted: false,
                type: .cardsCompleted,
                expiresAt: tomorrow
            ),
            DailyChallenge(
                title: "Perfect Score",
                description: "Get 10 correct answers in a row",
                targetValue: 10,
                currentValue: 0,
                xpReward: 75,
                isCompleted: false,
                type: .correctAnswers,
                expiresAt: tomorrow
            ),
            DailyChallenge(
                title: "Topic Explorer",
                description: "Explore 3 new topics today",
                targetValue: 3,
                currentValue: 0,
                xpReward: 100,
                isCompleted: false,
                type: .topicsExplored,
                expiresAt: tomorrow
            )
        ]
        
        saveDailyChallenges()
    }
    
    func updateChallengeProgress(type: ChallengeType, value: Int = 1) {
        for index in dailyChallenges.indices {
            if dailyChallenges[index].type == type && !dailyChallenges[index].isCompleted {
                dailyChallenges[index].currentValue += value
                
                // Check if challenge is completed
                if dailyChallenges[index].currentValue >= dailyChallenges[index].targetValue {
                    dailyChallenges[index].isCompleted = true
                    completeChallenge(dailyChallenges[index])
                }
            }
        }
        
        saveDailyChallenges()
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
        availableMysteryBoxes = []
        
        // Generate 3-5 mystery boxes
        let boxCount = Int.random(in: 3...5)
        
        for _ in 0..<boxCount {
            let rarity = randomRarity()
            let xpAmount = Int.random(in: rarity.xpRange)
            
            let mysteryBox = MysteryBox(
                xpAmount: xpAmount,
                rarity: rarity,
                isOpened: false,
                openedAt: nil
            )
            
            availableMysteryBoxes.append(mysteryBox)
        }
        
        saveMysteryBoxes()
    }
    
    private func randomRarity() -> BoxRarity {
        let random = Double.random(in: 0...1)
        
        switch random {
        case 0...0.5: return .common      // 50% chance
        case 0.5...0.8: return .rare      // 30% chance
        case 0.8...0.95: return .epic     // 15% chance
        default: return .legendary         // 5% chance
        }
    }
    
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
        
        saveMysteryBoxes()
        
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
            scheduleEncouragementNotification()
            
            // Track level up achievement in Firebase
            Task {
                await FirebaseManager.shared.trackAchievement("level_\(userProgress.currentLevel)")
            }
        }
        
        saveProgress()
    }
    
    func awardXPForCardCompletion(wasCorrect: Bool, isFirstTry: Bool, timeToAnswer: TimeInterval) {
        var totalXP = 0
        
        // Base XP for completing card
        awardXP(.cardCompleted, animated: false)
        totalXP += XPReward.cardCompleted.rawValue
        
        if wasCorrect {
            awardXP(.correctAnswer, animated: false)
            totalXP += XPReward.correctAnswer.rawValue
            
            if isFirstTry {
                awardXP(.perfectCard, animated: false)
                totalXP += XPReward.perfectCard.rawValue
                checkAchievement(.perfectionist)
            }
            
            // Speed bonus for answers under 5 seconds
            if timeToAnswer < 5.0 {
                awardXP(.speedBonus, animated: false)
                totalXP += XPReward.speedBonus.rawValue
            }
        }
        
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
        
        // Check achievements
        checkAchievements()
        checkEnhancedAchievements()
        
        // Add particle effects
        if wasCorrect {
            addParticleEffect(isFirstTry ? .perfectAnswer : .correctAnswer)
        }
        
        saveProgress()
    }
    
    // MARK: - Achievement System
    
    func checkAchievements() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Check all achievements
        if userProgress.totalCardsCompleted == 1 {
            unlockAchievement(.firstCard)
        }
        
        if userProgress.totalCardsCompleted >= 100 {
            unlockAchievement(.scholar)
        }
        
        if hour >= 23 || hour <= 5 {
            unlockAchievement(.nightOwl)
        }
        
        // Add more achievement checks as needed
    }
    
    func checkAchievement(_ achievement: Achievement) {
        guard !userProgress.achievementsUnlocked.contains(achievement.rawValue) else { return }
        
        let shouldUnlock: Bool
        
        switch achievement {
        case .perfectionist:
            // Count perfect cards (this would need tracking in actual implementation)
            shouldUnlock = userProgress.totalCorrectAnswers >= 25 // Simplified
        case .explorer:
            // This would need topic tracking
            shouldUnlock = false // Implement when topic tracking is added
        case .speedDemon:
            // This would need session tracking
            shouldUnlock = false // Implement when session tracking is added
        default:
            shouldUnlock = false
        }
        
        if shouldUnlock {
            unlockAchievement(achievement)
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        guard !userProgress.achievementsUnlocked.contains(achievement.rawValue) else { return }
        
        userProgress.achievementsUnlocked.append(achievement.rawValue)
        newAchievement = CustomAchievement(
            title: achievement.title,
            description: achievement.description,
            xpReward: achievement.xpReward,
            emoji: achievement.emoji
        )
        shouldShowAchievement = true
        
        // Award XP for achievement
        let didLevelUp = userProgress.addXP(achievement.xpReward)
        if didLevelUp {
            showLevelUpAnimation()
        }
        
        // Add celebration particle effect
        addParticleEffect(.achievement)
        Task {
            await FirebaseManager.shared.trackAchievement(achievement.rawValue)
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
    
    private func saveDailyChallenges() {
        do {
            let data = try JSONEncoder().encode(dailyChallenges)
            UserDefaults.standard.set(data, forKey: challengesKey)
        } catch {
            print("Error saving daily challenges: \(error)")
        }
    }
    
    private func loadDailyChallenges() {
        guard let data = UserDefaults.standard.data(forKey: challengesKey) else { return }
        
        do {
            dailyChallenges = try JSONDecoder().decode([DailyChallenge].self, from: data)
        } catch {
            print("Error loading daily challenges: \(error)")
            dailyChallenges = []
        }
    }
    
    private func saveMysteryBoxes() {
        do {
            let data = try JSONEncoder().encode(availableMysteryBoxes)
            UserDefaults.standard.set(data, forKey: mysteryBoxesKey)
        } catch {
            print("Error saving mystery boxes: \(error)")
        }
    }
    
    private func loadMysteryBoxes() {
        guard let data = UserDefaults.standard.data(forKey: mysteryBoxesKey) else { return }
        
        do {
            availableMysteryBoxes = try JSONDecoder().decode([MysteryBox].self, from: data)
        } catch {
            print("Error loading mystery boxes: \(error)")
            availableMysteryBoxes = []
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
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleEncouragementNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Level Up! 🎉"
        content.body = "You've reached level \(userProgress.currentLevel)! Keep up the amazing progress!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 hour later
        let request = UNNotificationRequest(identifier: "levelUp", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleStudyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Ready to learn something new? 🧠"
        content.body = "Your brain is waiting for some fresh knowledge!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false) // 24 hours
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleStreakWarning(streakDays: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak! 🔥"
        content.body = "You have a \(streakDays)-day learning streak. Keep it alive!"
        content.sound = .default
        
        // Schedule for 8 PM today
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streakWarning", content: content, trigger: trigger)
        
        notificationCenter.add(request)
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
