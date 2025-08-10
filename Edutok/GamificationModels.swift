import Foundation
import SwiftUI
import UserNotifications

@MainActor
class GamificationManager: ObservableObject {
    @Published var userProgress = UserProgress()
    @Published var recentXPGains: [XPGainEvent] = []
    @Published var shouldShowLevelUp = false
    @Published var shouldShowAchievement = false
    @Published var newAchievement: Achievement?
    @Published var particleEffects: [ParticleEffect] = []
    @Published var showComboDisplay = false
    @Published var comboDisplayTimer: Timer?
    
    // NEW: Session tracking for combos and achievements
    @Published var sessionStats = SessionStats()
    @Published var perfectCardCount = 0
    
    private let userDefaultsKey = "UserProgress"
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        loadProgress()
        requestNotificationPermission()
    }
    
    // MARK: - Enhanced XP System with Multipliers
    
    func awardXP(_ reward: XPReward, animated: Bool = true) {
        let baseAmount = reward.rawValue
        let didLevelUp = userProgress.addXP(baseAmount)
        
        if animated {
            let xpEvent = XPGainEvent(
                amount: Int(Double(baseAmount) * userProgress.comboXPMultiplier * userProgress.dailyXPMultiplier),
                reason: reward.description,
                emoji: reward.emoji,
                isCombo: userProgress.currentCombo > 2,
                isMultiplied: userProgress.dailyXPMultiplier > 1.0,
                comboMultiplier: userProgress.comboXPMultiplier,
                streakMultiplier: userProgress.dailyXPMultiplier
            )
            recentXPGains.append(xpEvent)
            
            // Remove after animation with stagger for multiple XP gains
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                if let index = self.recentXPGains.firstIndex(where: { $0.id == xpEvent.id }) {
                    self.recentXPGains.remove(at: index)
                }
            }
        }
        
        if didLevelUp {
            showExplosiveLevelUpAnimation()
            scheduleEncouragementNotification()
            addParticleEffect(.fireworks)
            
            // Check for level-based achievements
            checkLevelBasedAchievements()
            
            // Track level up achievement in Firebase
            Task {
                await FirebaseManager.shared.trackAchievement("level_\(userProgress.currentLevel)")
            }
        }
        
        saveProgress()
    }
    
    func awardXPForCardCompletion(wasCorrect: Bool, isFirstTry: Bool, timeToAnswer: TimeInterval) {
        sessionStats.cardsCompleted += 1
        
        if wasCorrect {
            // Increment combo for correct answers
            userProgress.incrementCombo()
            sessionStats.correctAnswers += 1
            
            // Show combo display if combo is significant
            if userProgress.currentCombo > 2 {
                showComboDisplay = true
                resetComboDisplayTimer()
            }
            
            // Award base XP with combo and streak multipliers
            let baseXP = XPReward.correctAnswer.rawValue
            let multipliedXP = Int(Double(baseXP) * userProgress.comboXPMultiplier * userProgress.dailyXPMultiplier)
            
            if isFirstTry {
                perfectCardCount += 1
                awardXP(.perfectCard, animated: false)
                addParticleEffect(.perfectAnswer)
                
                // Check perfectionist achievements
                checkPerfectionistAchievements()
            } else {
                awardXP(.correctAnswer, animated: false)
                addParticleEffect(.correctAnswer)
            }
            
            // Speed bonus for answers under 3 seconds
            if timeToAnswer < 3.0 {
                awardXP(.speedBonus, animated: false)
            }
            
            // Combo milestone bonuses
            if userProgress.currentCombo % 5 == 0 && userProgress.currentCombo > 0 {
                awardXP(.comboBonus, animated: false)
                addParticleEffect(.comboMultiplier(multiplier: userProgress.comboXPMultiplier))
            }
            
            // Check combo achievements
            checkComboAchievements()
            
        } else {
            // Reset combo on wrong answer
            userProgress.resetCombo()
            showComboDisplay = false
            comboDisplayTimer?.invalidate()
        }
        
        // Always award completion XP
        awardXP(.cardCompleted, animated: false)
        
        // Show combined XP gain
        let totalXP = calculateTotalXPGained(wasCorrect: wasCorrect, isFirstTry: isFirstTry, timeToAnswer: timeToAnswer)
        showCombinedXPGain(totalXP: totalXP, wasCorrect: wasCorrect, isFirstTry: isFirstTry)
        
        // Update user stats
        userProgress.totalCardsCompleted += 1
        if wasCorrect {
            userProgress.totalCorrectAnswers += 1
        }
        
        // Check general achievements
        checkGeneralAchievements()
        
        saveProgress()
    }
    
    private func calculateTotalXPGained(wasCorrect: Bool, isFirstTry: Bool, timeToAnswer: TimeInterval) -> Int {
        var total = XPReward.cardCompleted.rawValue
        
        if wasCorrect {
            total += XPReward.correctAnswer.rawValue
            
            if isFirstTry {
                total += XPReward.perfectCard.rawValue
            }
            
            if timeToAnswer < 3.0 {
                total += XPReward.speedBonus.rawValue
            }
            
            if userProgress.currentCombo % 5 == 0 && userProgress.currentCombo > 0 {
                total += XPReward.comboBonus.rawValue
            }
        }
        
        return Int(Double(total) * userProgress.comboXPMultiplier * userProgress.dailyXPMultiplier)
    }
    
    private func showCombinedXPGain(totalXP: Int, wasCorrect: Bool, isFirstTry: Bool) {
        let reason = wasCorrect ? (isFirstTry ? "Perfect Answer!" : "Correct!") : "Keep Learning!"
        let emoji = wasCorrect ? (isFirstTry ? "🌟" : "✅") : "💪"
        
        let combinedEvent = XPGainEvent(
            amount: totalXP,
            reason: reason,
            emoji: emoji,
            isCombo: userProgress.currentCombo > 2,
            isMultiplied: userProgress.dailyXPMultiplier > 1.0,
            comboMultiplier: userProgress.comboXPMultiplier,
            streakMultiplier: userProgress.dailyXPMultiplier
        )
        recentXPGains.append(combinedEvent)
    }
    
    // MARK: - Enhanced Achievement System
    
    func checkGeneralAchievements() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Time-based achievements
        if hour >= 23 || hour <= 5 {
            unlockAchievement(.nightOwl)
        }
        
        if hour >= 5 && hour <= 7 {
            unlockAchievement(.earlyBird)
        }
        
        // Weekend warrior
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 { // Sunday or Saturday
            unlockAchievement(.weekendWarrior)
        }
        
        // First card achievement
        if userProgress.totalCardsCompleted == 1 {
            unlockAchievement(.firstCard)
        }
        
        // Scholar achievements (progressive)
        checkProgressiveAchievements()
    }
    
    private func checkProgressiveAchievements() {
        let cards = userProgress.totalCardsCompleted
        
        // Scholar progression
        if cards >= 50 && !userProgress.achievementsUnlocked.contains(Achievement.scholar_bronze.rawValue) {
            unlockAchievement(.scholar_bronze)
        } else if cards >= 250 && !userProgress.achievementsUnlocked.contains(Achievement.scholar_silver.rawValue) {
            unlockAchievement(.scholar_silver)
        } else if cards >= 1000 && !userProgress.achievementsUnlocked.contains(Achievement.scholar_gold.rawValue) {
            unlockAchievement(.scholar_gold)
        } else if cards >= 5000 && !userProgress.achievementsUnlocked.contains(Achievement.scholar_platinum.rawValue) {
            unlockAchievement(.scholar_platinum)
        }
        
        // Streak achievements
        let streak = userProgress.currentStreak
        if streak >= 3 && !userProgress.achievementsUnlocked.contains(Achievement.dedicated_bronze.rawValue) {
            unlockAchievement(.dedicated_bronze)
        } else if streak >= 7 && !userProgress.achievementsUnlocked.contains(Achievement.dedicated_silver.rawValue) {
            unlockAchievement(.dedicated_silver)
        } else if streak >= 30 && !userProgress.achievementsUnlocked.contains(Achievement.dedicated_gold.rawValue) {
            unlockAchievement(.dedicated_gold)
        } else if streak >= 100 && !userProgress.achievementsUnlocked.contains(Achievement.dedicated_platinum.rawValue) {
            unlockAchievement(.dedicated_platinum)
        } else if streak >= 365 && !userProgress.achievementsUnlocked.contains(Achievement.unstoppable.rawValue) {
            unlockAchievement(.unstoppable)
        }
    }
    
    private func checkComboAchievements() {
        let combo = userProgress.currentCombo
        
        if combo >= 5 && !userProgress.achievementsUnlocked.contains(Achievement.comboMaster_bronze.rawValue) {
            unlockAchievement(.comboMaster_bronze)
        } else if combo >= 15 && !userProgress.achievementsUnlocked.contains(Achievement.comboMaster_silver.rawValue) {
            unlockAchievement(.comboMaster_silver)
        } else if combo >= 50 && !userProgress.achievementsUnlocked.contains(Achievement.comboMaster_gold.rawValue) {
            unlockAchievement(.comboMaster_gold)
        } else if combo >= 100 && !userProgress.achievementsUnlocked.contains(Achievement.comboMaster_platinum.rawValue) {
            unlockAchievement(.comboMaster_platinum)
        }
    }
    
    private func checkPerfectionistAchievements() {
        if perfectCardCount >= 10 && !userProgress.achievementsUnlocked.contains(Achievement.perfectionist_bronze.rawValue) {
            unlockAchievement(.perfectionist_bronze)
        } else if perfectCardCount >= 50 && !userProgress.achievementsUnlocked.contains(Achievement.perfectionist_silver.rawValue) {
            unlockAchievement(.perfectionist_silver)
        } else if perfectCardCount >= 200 && !userProgress.achievementsUnlocked.contains(Achievement.perfectionist_gold.rawValue) {
            unlockAchievement(.perfectionist_gold)
        } else if perfectCardCount >= 1000 && !userProgress.achievementsUnlocked.contains(Achievement.perfectionist_platinum.rawValue) {
            unlockAchievement(.perfectionist_platinum)
        }
    }
    
    private func checkLevelBasedAchievements() {
        // Award special achievements for milestone levels
        switch userProgress.currentLevel {
        case 10:
            unlockAchievement(.scholar_bronze)
        case 25:
            unlockAchievement(.scholar_silver)
        case 50:
            unlockAchievement(.scholar_gold)
        case 100:
            unlockAchievement(.scholar_platinum)
        default:
            break
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        guard !userProgress.achievementsUnlocked.contains(achievement.rawValue) else { return }
        
        userProgress.achievementsUnlocked.append(achievement.rawValue)
        newAchievement = achievement
        shouldShowAchievement = true
        
        // Award XP for achievement with tier multiplier
        let didLevelUp = userProgress.addXP(achievement.xpReward)
        if didLevelUp {
            showExplosiveLevelUpAnimation()
        }
        
        // Add tier-appropriate particle effect
        addParticleEffect(.achievement(tier: achievement.tier))
        
        // Haptic feedback based on tier
        let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = {
            switch achievement.tier {
            case .bronze: return .light
            case .silver: return .medium
            case .gold, .platinum, .diamond: return .heavy
            }
        }()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: impactStyle)
        impactFeedback.impactOccurred()
        
        Task {
            await FirebaseManager.shared.trackAchievement(achievement.rawValue)
        }
        
        saveProgress()
    }
    
    // MARK: - Enhanced Particle Effects
    
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
    
    // MARK: - Enhanced Level Up Animation
    
    private func showExplosiveLevelUpAnimation() {
        shouldShowLevelUp = true
        
        // Multiple particle effects for level up
        addParticleEffect(.levelUp)
        addParticleEffect(.confetti)
        addParticleEffect(.explosion)
        
        // Strong haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Hide after extended animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.shouldShowLevelUp = false
        }
    }
    
    // MARK: - Combo Display Management
    
    private func resetComboDisplayTimer() {
        comboDisplayTimer?.invalidate()
        comboDisplayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.showComboDisplay = false
            }
        }
    }
    
    // MARK: - Session Stats
    
    func resetSessionStats() {
        sessionStats = SessionStats()
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
    
    // MARK: - Enhanced Push Notifications
    
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
        content.title = "🎉 LEVEL UP!"
        content.body = "You've reached level \(userProgress.currentLevel)! Your learning journey is incredible! 🚀"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 hour later
        let request = UNNotificationRequest(identifier: "levelUp_\(userProgress.currentLevel)", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleStudyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Ready to level up? 🧠⚡"
        content.body = "Your combo is waiting! Come back and keep your streak alive! 🔥"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false) // 24 hours
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleStreakWarning(streakDays: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Don't break your epic streak!"
        content.body = "You have a \(streakDays)-day learning streak worth \(String(format: "%.1f", userProgress.dailyXPMultiplier))x XP! Keep it alive! 🚀"
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

// MARK: - Session Statistics
struct SessionStats {
    var cardsCompleted: Int = 0
    var correctAnswers: Int = 0
    var startTime: Date = Date()
    
    var accuracy: Double {
        guard cardsCompleted > 0 else { return 0 }
        return Double(correctAnswers) / Double(cardsCompleted)
    }
    
    var sessionDuration: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
}

// MARK: - Enhanced Particle Effect Model
struct ParticleEffect: Identifiable {
    let id = UUID()
    let type: ParticleType
    let duration: TimeInterval
    
    init(type: ParticleType) {
        self.type = type
        self.duration = type.duration
    }
}
