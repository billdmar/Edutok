import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Smart notification templates
    private let motivationalMessages = [
        "Your brain is craving some new knowledge! 🧠✨",
        "Time to feed your curiosity! 📚💫",
        "Ready to level up your learning? 🚀",
        "Your future self will thank you for studying today! 🌟",
        "Knowledge is power - and you're getting stronger! 💪",
        "Turn screen time into brain time! 🎯",
        "Quick study session = big brain gains! ⚡",
        "Your learning streak is waiting for you! 🔥"
    ]
    
    private let streakMessages = [
        "Don't let your 🔥 streak die! Just 5 minutes can save it!",
        "Your {streak}-day streak is incredible! Keep it alive! 💪",
        "You're on fire with your {streak}-day streak! 🔥 Don't stop now!",
        "Amazing! {streak} days straight! Can you make it {next}? 🎯",
        "Your dedication is inspiring! {streak} days and counting! ⭐"
    ]
    
    private let levelUpMessages = [
        "Congratulations on reaching Level {level}! 🎉 Ready for more?",
        "Level {level} achieved! Your brain is getting stronger! 💪",
        "Welcome to Level {level}! New challenges await! 🚀",
        "Level {level} unlocked! You're on an incredible learning journey! ✨"
    ]
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Smart Study Reminders
    
    func scheduleSmartStudyReminder(basedOnUsage userProgress: UserProgress) {
        let content = UNMutableNotificationContent()
        content.title = "FlashTok"
        content.body = motivationalMessages.randomElement() ?? "Ready to learn something amazing?"
        content.sound = .default
        content.badge = 1
        
        // Schedule based on user's typical usage patterns
        let hour = getOptimalStudyTime(for: userProgress)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyStudy", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleStreakReminder(streakDays: Int) {
        guard streakDays > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Streak Alert! 🔥"
        
        let message = streakMessages.randomElement()?.replacingOccurrences(of: "{streak}", with: "\(streakDays)")
            .replacingOccurrences(of: "{next}", with: "\(streakDays + 1)") ?? "Don't break your streak!"
        
        content.body = message
        content.sound = .default
        content.badge = 1
        
        // Schedule for evening if user hasn't studied today
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streakWarning", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleLevelUpCelebration(newLevel: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Incredible Achievement!"
        content.body = levelUpMessages.randomElement()?.replacingOccurrences(of: "{level}", with: "\(newLevel)") ?? "You leveled up!"
        content.sound = .default
        
        // Schedule for 1 hour later to encourage return
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "levelUpCelebration", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleReEngagementNotification(daysSinceLastUse: Int) {
        let content = UNMutableNotificationContent()
        content.title = "We miss you! 🥺"
        
        let body: String
        switch daysSinceLastUse {
        case 1:
            body = "Your brain is wondering where you went! Come back for just 2 minutes? 🧠"
        case 2...3:
            body = "Your learning streak is getting cold... Warm it up with a quick session! 🔥"
        case 4...7:
            body = "Did you know your brain forgets 50% of new info within an hour? Let's fight that! 💪"
        default:
            body = "New fascinating topics are waiting for you! Discover something amazing today! ✨"
        }
        
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "reengagement", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleWeeklyChallenge() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Challenge! 🏆"
        content.body = "New weekly challenge is live! Can you complete 100 cards this week?"
        content.sound = .default
        
        // Schedule for Monday morning
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyChallenge", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleAchievementNotification(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = "\(achievement.emoji) \(achievement.title) - \(achievement.description)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(achievement.rawValue)", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    // MARK: - Smart Timing
    
    private func getOptimalStudyTime(for userProgress: UserProgress) -> Int {
        // Simple algorithm - could be enhanced with ML
        let calendar = Calendar.current
        let lastActive = calendar.component(.hour, from: userProgress.lastActiveDate)
        
        // If user was active in evening, suggest morning
        if lastActive >= 18 {
            return 9 // 9 AM
        }
        // If user was active in morning, suggest evening
        else if lastActive <= 12 {
            return 19 // 7 PM
        }
        // Default to afternoon
        else {
            return 15 // 3 PM
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
