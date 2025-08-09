import Foundation
import SwiftUI

@MainActor
class StreakProtectionManager: ObservableObject {
    static let shared = StreakProtectionManager()
    
    @Published var availableFreezes: Int = 1 // Start with 1 free freeze
    @Published var showStreakWarning = false
    @Published var showFreezeUsed = false
    @Published var showFreezeEarned = false
    @Published var streakInDanger = false
    
    // Streak freeze tracking
    @Published var lastActivityDate: Date = Date()
    @Published var freezeExpirationDate: Date?
    @Published var hasUsedFreezeToday = false
    
    private let userDefaultsKey = "StreakProtection"
    private let warningHoursBeforeReset = 4 // Show warning 4 hours before midnight
    
    private var warningTimer: Timer?
    private var dangerCheckTimer: Timer?
    
    private init() {
        loadStreakData()
        setupDangerMonitoring()
    }
    
    private func setupDangerMonitoring() {
        dangerCheckTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                self.checkStreakDanger()
            }
        }
        
        // Check immediately
        checkStreakDanger()
    }
    
    func recordActivity() {
        lastActivityDate = Date()
        streakInDanger = false
        showStreakWarning = false
        hasUsedFreezeToday = false
        
        // Check if user earned a new freeze
        checkForFreezeReward()
        
        saveStreakData()
    }
    
    private func checkStreakDanger() {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if it's been more than 20 hours since last activity
        let hoursSinceActivity = now.timeIntervalSince(lastActivityDate) / 3600
        
        // If no activity today and it's after 8 PM, streak is in danger
        let currentHour = calendar.component(.hour, from: now)
        let isToday = calendar.isDate(lastActivityDate, inSameDayAs: now)
        
        if !isToday && currentHour >= 20 {
            if !streakInDanger {
                streakInDanger = true
                showStreakWarning = true
                scheduleStreakWarningNotification()
            }
        } else if hoursSinceActivity >= 20 {
            if !streakInDanger {
                streakInDanger = true
                showStreakWarning = true
                scheduleStreakWarningNotification()
            }
        }
    }
    
    func useStreakFreeze() -> Bool {
        guard availableFreezes > 0, !hasUsedFreezeToday else {
            return false
        }
        
        availableFreezes -= 1
        hasUsedFreezeToday = true
        streakInDanger = false
        showStreakWarning = false
        
        // Set freeze expiration to tomorrow at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        freezeExpirationDate = calendar.startOfDay(for: tomorrow)
        
        showFreezeUsed = true
        
        // Play celebration effects
        SoundEffectsManager.shared.playSound(.achievement)
        HapticFeedbackManager.shared.trigger(.milestone)
        
        // Award some XP for using protection wisely
        GamificationManager.shared.awardXP(.streakBonus)
        
        saveStreakData()
        
        // Hide notification after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showFreezeUsed = false
        }
        
        return true
    }
    
    private func checkForFreezeReward() {
        let calendar = Calendar.current
        let streak = GamificationManager.shared.userProgress.currentStreak
        
        // Earn freeze every 7 days of streak
        if streak > 0 && streak % 7 == 0 && availableFreezes < 3 {
            earnStreakFreeze()
        }
        
        // Earn freeze on special milestones
        let milestones = [30, 50, 100, 200, 365]
        if milestones.contains(streak) && availableFreezes < 5 {
            earnStreakFreeze()
        }
    }
    
    private func earnStreakFreeze() {
        availableFreezes += 1
        showFreezeEarned = true
        
        // Play celebration
        SoundEffectsManager.shared.playSound(.streakBonus)
        HapticFeedbackManager.shared.trigger(.achievement(tier: .gold))
        
        // Hide notification after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.showFreezeEarned = false
        }
    }
    
    func canUseFreeze: Bool {
        return availableFreezes > 0 && !hasUsedFreezeToday && streakInDanger
    }
    
    var freezeStatusText: String {
        if let expiration = freezeExpirationDate, expiration > Date() {
            return "Streak Protected Until Tomorrow"
        } else if availableFreezes > 0 {
            return "\(availableFreezes) Streak Freeze\(availableFreezes == 1 ? "" : "s") Available"
        } else {
            return "No Streak Freezes Available"
        }
    }
    
    var streakProtectionActive: Bool {
        guard let expiration = freezeExpirationDate else { return false }
        return expiration > Date()
    }
    
    private func scheduleStreakWarningNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Your Streak is in Danger!"
        content.body = "Don't lose your \(GamificationManager.shared.userProgress.currentStreak)-day streak! Quick study session or use a Streak Freeze? 🧊"
        content.sound = .default
        content.categoryIdentifier = "STREAK_WARNING"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false) // 30 min later
        let request = UNNotificationRequest(identifier: "streakWarning", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func saveStreakData() {
        let data = StreakProtectionData(
            availableFreezes: availableFreezes,
            lastActivityDate: lastActivityDate,
            freezeExpirationDate: freezeExpirationDate,
            hasUsedFreezeToday: hasUsedFreezeToday
        )
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("Error saving streak data: \(error)")
        }
    }
    
    private func loadStreakData() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(StreakProtectionData.self, from: data)
            availableFreezes = decoded.availableFreezes
            lastActivityDate = decoded.lastActivityDate
            freezeExpirationDate = decoded.freezeExpirationDate
            hasUsedFreezeToday = decoded.hasUsedFreezeToday
            
            // Reset daily flag if it's a new day
            let calendar = Calendar.current
            if !calendar.isDate(lastActivityDate, inSameDayAs: Date()) {
                hasUsedFreezeToday = false
            }
            
        } catch {
            print("Error loading streak data: \(error)")
        }
    }
    
    deinit {
        warningTimer?.invalidate()
        dangerCheckTimer?.invalidate()
    }
}

// MARK: - Streak Protection Data Model
private struct StreakProtectionData: Codable {
    let availableFreezes: Int
    let lastActivityDate: Date
    let freezeExpirationDate: Date?
    let hasUsedFreezeToday: Bool
}

// MARK: - Streak Warning View
struct StreakWarningView: View {
    @Binding var isShowing: Bool
    let streakDays: Int
    @StateObject private var streakManager = StreakProtectionManager.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }
            
            VStack(spacing: 25) {
                VStack(spacing: 15) {
                    Text("🔥")
                        .font(.system(size: 60))
                    
                    Text("Streak in Danger!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Your \(streakDays)-day learning streak is about to break!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Study now or use a Streak Freeze to protect it!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 15) {
                    // Study Now Button
                    Button("Study Now! 📚") {
                        isShowing = false
                        // Navigate to learning
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    
                    // Use Freeze Button
                    if streakManager.canUseFreeze {
                        Button("Use Streak Freeze 🧊 (\(streakManager.availableFreezes) left)") {
                            if streakManager.useStreakFreeze() {
                                isShowing = false
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                    }
                    
                    // Dismiss Button
                    Button("Maybe Later") {
                        isShowing = false
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 10)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.orange, lineWidth: 2)
                    )
            )
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Streak Freeze Notifications
struct FreezeUsedView: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Text("🧊")
                .font(.system(size: 40))
            
            Text("Streak Freeze Used!")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.cyan)
            
            Text("Your streak is protected until tomorrow!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cyan, lineWidth: 2)
                )
        )
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

struct FreezeEarnedView: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Text("🎁")
                .font(.system(size: 40))
            
            Text("Streak Freeze Earned!")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
            
            Text("Keep up the great work! You've earned streak protection!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow, lineWidth: 2)
                )
        )
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}
