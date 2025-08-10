import Foundation
import UIKit
import SwiftUI

@MainActor
class HapticFeedbackManager: ObservableObject {
    static let shared = HapticFeedbackManager()
    
    @Published var hapticEnabled = true
    @Published var hapticIntensity: Float = 1.0
    
    private var impactLight = UIImpactFeedbackGenerator(style: .light)
    private var impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private var impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private var notification = UINotificationFeedbackGenerator()
    private var selection = UISelectionFeedbackGenerator()
    
    private init() {
        loadSettings()
        prepareGenerators()
    }
    
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
    }
    
    func trigger(_ feedback: HapticFeedback) {
        guard hapticEnabled else { return }
        
        switch feedback {
        case .light:
            impactLight.impactOccurred(intensity: CGFloat(hapticIntensity))
            
        case .medium:
            impactMedium.impactOccurred(intensity: CGFloat(hapticIntensity))
            
        case .heavy:
            impactHeavy.impactOccurred(intensity: CGFloat(hapticIntensity))
            
        case .selection:
            selection.selectionChanged()
            
        case .success:
            notification.notificationOccurred(.success)
            
        case .warning:
            notification.notificationOccurred(.warning)
            
        case .error:
            notification.notificationOccurred(.error)
            
        case .cardFlip:
            impactLight.impactOccurred(intensity: CGFloat(hapticIntensity * 0.8))
            
        case .correctAnswer:
            notification.notificationOccurred(.success)
            
        case .wrongAnswer:
            notification.notificationOccurred(.error)
            
        case .perfectCard:
            // Double tap for perfect
            impactMedium.impactOccurred(intensity: CGFloat(hapticIntensity))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impactMedium.impactOccurred(intensity: CGFloat(self.hapticIntensity))
            }
            
        case .combo(let multiplier):
            // Intensity based on combo multiplier
            let intensity = min(CGFloat(hapticIntensity * Float(multiplier * 0.3)), 1.0)
            impactHeavy.impactOccurred(intensity: intensity)
            
        case .levelUp:
            // Epic level up sequence
            levelUpSequence()
            
        case .achievement(let tier):
            achievementFeedback(tier: tier)
            
        case .streakBonus:
            // Rhythmic pattern for streak
            streakSequence()
            
        case .xpGain:
            impactLight.impactOccurred(intensity: CGFloat(hapticIntensity * 0.6))
            
        case .buttonPress:
            impactLight.impactOccurred(intensity: CGFloat(hapticIntensity * 0.5))
            
        case .swipe:
            selection.selectionChanged()
            
        case .milestone:
            // Triple tap pattern
            milestoneSequence()
        }
    }
    
    private func levelUpSequence() {
        // Dramatic level up haptic sequence
        impactHeavy.impactOccurred(intensity: CGFloat(hapticIntensity))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactHeavy.impactOccurred(intensity: CGFloat(self.hapticIntensity))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impactHeavy.impactOccurred(intensity: CGFloat(self.hapticIntensity))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.notification.notificationOccurred(.success)
        }
    }
    
    private func achievementFeedback(tier: AchievementTier) {
        switch tier {
        case .bronze:
            impactMedium.impactOccurred(intensity: CGFloat(hapticIntensity * 0.7))
            
        case .silver:
            impactMedium.impactOccurred(intensity: CGFloat(hapticIntensity * 0.8))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impactMedium.impactOccurred(intensity: CGFloat(self.hapticIntensity * 0.8))
            }
            
        case .gold:
            impactHeavy.impactOccurred(intensity: CGFloat(hapticIntensity * 0.9))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impactHeavy.impactOccurred(intensity: CGFloat(self.hapticIntensity * 0.9))
            }
            
        case .platinum:
            // Platinum rhythm
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * 0.08)) {
                    self.impactHeavy.impactOccurred(intensity: CGFloat(self.hapticIntensity))
                }
            }
            
        case .diamond:
            // Epic diamond sequence
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * 0.06)) {
                    self.impactHeavy.impactOccurred(intensity: CGFloat(self.hapticIntensity))
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.notification.notificationOccurred(.success)
            }
        }
    }
    
    private func streakSequence() {
        // Fire-like rapid taps
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * 0.05)) {
                self.impactMedium.impactOccurred(intensity: CGFloat(self.hapticIntensity * 0.6))
            }
        }
    }
    
    private func milestoneSequence() {
        // Triple milestone tap
        impactHeavy.impactOccurred(intensity: CGFloat(hapticIntensity))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.impactHeavy.impactOccurred(intensity: CGFloat(self.hapticIntensity))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.impactHeavy.impactOccurred(intensity: CGFloat(self.hapticIntensity))
        }
    }
    
    func setHapticEnabled(_ enabled: Bool) {
        hapticEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "hapticEnabled")
        
        if enabled {
            prepareGenerators()
        }
    }
    
    func setHapticIntensity(_ intensity: Float) {
        hapticIntensity = max(0.0, min(1.0, intensity))
        UserDefaults.standard.set(hapticIntensity, forKey: "hapticIntensity")
    }
    
    private func loadSettings() {
        hapticEnabled = UserDefaults.standard.object(forKey: "hapticEnabled") as? Bool ?? true
        hapticIntensity = UserDefaults.standard.object(forKey: "hapticIntensity") as? Float ?? 1.0
    }
}

enum HapticFeedback {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
    
    // Custom feedback types
    case cardFlip
    case correctAnswer
    case wrongAnswer
    case perfectCard
    case combo(multiplier: Double)
    case levelUp
    case achievement(tier: AchievementTier)
    case streakBonus
    case xpGain
    case buttonPress
    case swipe
    case milestone
    
    var description: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        case .selection: return "Selection"
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        case .cardFlip: return "Card Flip"
        case .correctAnswer: return "Correct Answer"
        case .wrongAnswer: return "Wrong Answer"
        case .perfectCard: return "Perfect Card"
        case .combo: return "Combo"
        case .levelUp: return "Level Up"
        case .achievement: return "Achievement"
        case .streakBonus: return "Streak Bonus"
        case .xpGain: return "XP Gain"
        case .buttonPress: return "Button Press"
        case .swipe: return "Swipe"
        case .milestone: return "Milestone"
        }
    }
}

// MARK: - Haptic Feedback View Modifier
extension View {
    func hapticFeedback(_ feedback: HapticFeedback, trigger: Bool) -> some View {
        self.onChange(of: trigger) { _ in
            HapticFeedbackManager.shared.trigger(feedback)
        }
    }
    
    func onTapHaptic(_ feedback: HapticFeedback = .buttonPress, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticFeedbackManager.shared.trigger(feedback)
            action()
        }
    }
}
