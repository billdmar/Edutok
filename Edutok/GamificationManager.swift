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
    
    private let userDefaultsKey = "UserProgress"
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        loadProgress()
        requestNotificationPermission()
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
        
        // Check achievements
        checkAchievements()
        
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
        newAchievement = achievement
        shouldShowAchievement = true
        
        // Award XP for achievement
        let didLevelUp = userProgress.addXP(achievement.xpReward)
        if didLevelUp {
            showLevelUpAnimation()
        }
        
        // Add celebration particle effect
        addParticleEffect(.achievement)
        
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
