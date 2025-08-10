import Foundation
import AVFoundation
import SwiftUI

@MainActor
class SoundEffectsManager: ObservableObject {
    static let shared = SoundEffectsManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    @Published var soundEnabled = true
    @Published var volume: Float = 0.7
    
    private let soundEffects: [SoundEffect: String] = [
        .cardFlip: "card_flip",
        .correctAnswer: "correct_ding",
        .wrongAnswer: "wrong_buzz",
        .perfectCard: "perfect_chime",
        .combo: "combo_whoosh",
        .levelUp: "level_up_fanfare",
        .achievement: "achievement_unlock",
        .xpGain: "xp_coin",
        .streakBonus: "streak_fire",
        .buttonTap: "button_click",
        .pageSwipe: "page_swipe",
        .notification: "gentle_bell"
    ]
    
    private init() {
        setupAudioSession()
        preloadSounds()
        loadSettings()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        // In a real app, you would add actual sound files to your bundle
        // For now, we'll use system sounds as placeholders
        for (effect, _) in soundEffects {
            // You would load actual audio files here
            // let url = Bundle.main.url(forResource: filename, withExtension: "mp3")
            // This is a placeholder implementation
        }
    }
    
    func playSound(_ effect: SoundEffect, volume: Float? = nil) {
        guard soundEnabled else { return }
        
        // Use system sounds for now - in production you'd use custom audio files
        let systemSoundID: SystemSoundID
        
        switch effect {
        case .cardFlip, .pageSwipe:
            systemSoundID = 1519 // Swipe
        case .correctAnswer, .perfectCard:
            systemSoundID = 1103 // Success
        case .wrongAnswer:
            systemSoundID = 1107 // Error
        case .combo, .streakBonus:
            systemSoundID = 1519 // Whoosh
        case .levelUp:
            systemSoundID = 1103 // Celebration (you'd want a longer sound)
        case .achievement:
            systemSoundID = 1106 // Achievement
        case .xpGain:
            systemSoundID = 1104 // Coin
        case .buttonTap:
            systemSoundID = 1104 // Click
        case .notification:
            systemSoundID = 1005 // Bell
        }
        
        AudioServicesPlaySystemSound(systemSoundID)
        
        // For custom sounds, you would use:
        /*
        guard let filename = soundEffects[effect],
              let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume ?? self.volume
            player.play()
            
            // Store player to prevent deallocation
            audioPlayers[effect.rawValue] = player
        } catch {
            print("Failed to play sound \(effect): \(error)")
        }
        */
    }
    
    func playSequence(_ effects: [SoundEffect], delay: TimeInterval = 0.1) {
        for (index, effect) in effects.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(index) * delay)) {
                self.playSound(effect)
            }
        }
    }
    
    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "soundEnabled")
        
        if !enabled {
            stopAllSounds()
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        UserDefaults.standard.set(volume, forKey: "soundVolume")
        
        // Update existing players
        audioPlayers.values.forEach { $0.volume = volume }
    }
    
    private func loadSettings() {
        soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        volume = UserDefaults.standard.object(forKey: "soundVolume") as? Float ?? 0.7
    }
}

enum SoundEffect: String, CaseIterable {
    case cardFlip = "card_flip"
    case correctAnswer = "correct_answer"
    case wrongAnswer = "wrong_answer"
    case perfectCard = "perfect_card"
    case combo = "combo"
    case levelUp = "level_up"
    case achievement = "achievement"
    case xpGain = "xp_gain"
    case streakBonus = "streak_bonus"
    case buttonTap = "button_tap"
    case pageSwipe = "page_swipe"
    case notification = "notification"
    
    var description: String {
        switch self {
        case .cardFlip: return "Card Flip"
        case .correctAnswer: return "Correct Answer"
        case .wrongAnswer: return "Wrong Answer"
        case .perfectCard: return "Perfect Card"
        case .combo: return "Combo"
        case .levelUp: return "Level Up"
        case .achievement: return "Achievement"
        case .xpGain: return "XP Gain"
        case .streakBonus: return "Streak Bonus"
        case .buttonTap: return "Button Tap"
        case .pageSwipe: return "Page Swipe"
        case .notification: return "Notification"
        }
    }
}
