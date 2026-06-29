/// NotificationScheduler.swift
///
/// Local-notification scheduling, extracted from `GamificationManager` so the reward
/// manager isn't also a notification controller. This type is stateless — it owns only a
/// `UNUserNotificationCenter` and takes the values it needs as parameters — which keeps it
/// independent of the manager's `@Published` state and easy to reason about.
import Foundation
import UserNotifications

struct NotificationScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Requests alert/sound/badge authorization (no-op if already decided).
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            #if DEBUG
            print(granted ? "Notification permission granted" : "Notification permission denied")
            #endif
        }
    }

    /// Encouragement nudge after a level-up.
    func scheduleEncouragement(level: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Level Up! 🎉"
        content.body = "You've reached level \(level)! Keep up the amazing progress!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        center.add(UNNotificationRequest(identifier: "levelUp", content: content, trigger: trigger))
    }

    /// Daily "come back and learn" reminder.
    func scheduleStudyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Ready to learn something new? 🧠"
        content.body = "Your brain is waiting for some fresh knowledge!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
        center.add(UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger))
    }

    /// Evening warning to protect an active streak.
    func scheduleStreakWarning(streakDays: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak! 🔥"
        content.body = "You have a \(streakDays)-day learning streak. Keep it alive!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        center.add(UNNotificationRequest(identifier: "streakWarning", content: content, trigger: trigger))
    }
}
