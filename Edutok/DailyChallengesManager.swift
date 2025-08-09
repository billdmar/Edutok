import Foundation
import SwiftUI

@MainActor
class DailyChallengesManager: ObservableObject {
    static let shared = DailyChallengesManager()
    
    @Published var todaysChallenges: [DailyChallenge] = []
    @Published var completedChallenges: Set<String> = []
    @Published var showChallengeComplete = false
    @Published var newlyCompletedChallenge: DailyChallenge?
    
    private let userDefaultsKey = "DailyChallenges"
    private let completedKey = "CompletedChallenges"
    private let lastUpdateKey = "LastChallengeUpdate"
    
    private init() {
        loadChallenges()
        checkForNewDay()
    }
    
    func checkForNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date ?? Date.distantPast
        
        if !Calendar.current.isDate(lastUpdate, inSameDayAs: today) {
            generateTodaysChallenges()
            completedChallenges.removeAll()
            saveChallenges()
            UserDefaults.standard.set(today, forKey: lastUpdateKey)
        }
    }
    
    private func generateTodaysChallenges() {
        let allChallengeTypes = ChallengeType.allCases
        var selectedChallenges: [DailyChallenge] = []
        
        // Always include one streak protection challenge
        selectedChallenges.append(createChallenge(.maintainStreak))
        
        // Add 2-3 random challenges based on difficulty
        let remainingTypes = allChallengeTypes.filter { $0 != .maintainStreak }
        let selectedTypes = Array(remainingTypes.shuffled().prefix(3))
        
        for type in selectedTypes {
            selectedChallenges.append(createChallenge(type))
        }
        
        todaysChallenges = selectedChallenges
    }
    
    private func createChallenge(_ type: ChallengeType) -> DailyChallenge {
        let id = "\(type.rawValue)_\(Date().timeIntervalSince1970)"
        let baseReward = 100
        
        switch type {
        case .completeCards:
            let target = [10, 15, 20, 25].randomElement() ?? 15
            return DailyChallenge(
                id: id,
                type: type,
                title: "Card Master",
                description: "Complete \(target) flashcards",
                target: target,
                current: 0,
                xpReward: baseReward + (target * 5),
                difficulty: target <= 15 ? .easy : target <= 20 ? .medium : .hard
            )
            
        case .perfectStreak:
            let target = [5, 8, 10, 12].randomElement() ?? 8
            return DailyChallenge(
                id: id,
                type: type,
                title: "Perfect Streak",
                description: "Get \(target) perfect cards in a row",
                target: target,
                current: 0,
                xpReward: baseReward + (target * 15),
                difficulty: target <= 6 ? .easy : target <= 10 ? .medium : .hard
            )
            
        case .exploreTopics:
            let target = [3, 4, 5, 6].randomElement() ?? 4
            return DailyChallenge(
                id: id,
                type: type,
                title: "Explorer",
                description: "Study \(target) different topics",
                target: target,
                current: 0,
                xpReward: baseReward + (target * 20),
                difficulty: target <= 3 ? .easy : target <= 5 ? .medium : .hard
            )
            
        case .speedChallenge:
            let target = [20, 30, 40, 50].randomElement() ?? 30
            return DailyChallenge(
                id: id,
                type: type,
                title: "Speed Demon",
                description: "Complete \(target) cards in 10 minutes",
                target: target,
                current: 0,
                xpReward: baseReward + (target * 8),
                difficulty: target <= 25 ? .easy : target <= 40 ? .medium : .hard
            )
            
        case .comboMaster:
            let target = [15, 20, 25, 30].randomElement() ?? 20
            return DailyChallenge(
                id: id,
                type: type,
                title: "Combo Master",
                description: "Achieve a \(target)x combo",
                target: target,
                current: 0,
                xpReward: baseReward + (target * 10),
                difficulty: target <= 18 ? .easy : target <= 25 ? .medium : .hard
            )
            
        case .maintainStreak:
            return DailyChallenge(
                id: id,
                type: type,
                title: "Streak Guardian",
                description: "Don't break your learning streak",
                target: 1,
                current: 0,
                xpReward: baseReward,
                difficulty: .easy
            )
            
        case .accuracyChallenge:
            let target = [85, 90, 95].randomElement() ?? 90
            return DailyChallenge(
                id: id,
                type: type,
                title: "Accuracy Expert",
                description: "Maintain \(target)% accuracy (min 20 cards)",
                target: target,
                current: 0,
                xpReward: baseReward + (target * 2),
                difficulty: target <= 85 ? .easy : target <= 90 ? .medium : .hard
            )
        }
    }
    
    func updateProgress(_ type: ChallengeType, amount: Int = 1) {
        guard let challengeIndex = todaysChallenges.firstIndex(where: { $0.type == type && !completedChallenges.contains($0.id) }) else {
            return
        }
        
        var challenge = todaysChallenges[challengeIndex]
        challenge.current = min(challenge.current + amount, challenge.target)
        todaysChallenges[challengeIndex] = challenge
        
        if challenge.current >= challenge.target && !completedChallenges.contains(challenge.id) {
            completeChallenge(challenge)
        }
        
        saveChallenges()
    }
    
    func updateComboProgress(_ combo: Int) {
        guard let challengeIndex = todaysChallenges.firstIndex(where: { $0.type == .comboMaster && !completedChallenges.contains($0.id) }) else {
            return
        }
        
        var challenge = todaysChallenges[challengeIndex]
        challenge.current = max(challenge.current, combo)
        todaysChallenges[challengeIndex] = challenge
        
        if challenge.current >= challenge.target && !completedChallenges.contains(challenge.id) {
            completeChallenge(challenge)
        }
        
        saveChallenges()
    }
    
    func updateAccuracy(correct: Int, total: Int) {
        guard let challengeIndex = todaysChallenges.firstIndex(where: { $0.type == .accuracyChallenge && !completedChallenges.contains($0.id) }) else {
            return
        }
        
        guard total >= 20 else { return } // Minimum cards required
        
        let accuracy = Int((Double(correct) / Double(total)) * 100)
        var challenge = todaysChallenges[challengeIndex]
        challenge.current = accuracy
        todaysChallenges[challengeIndex] = challenge
        
        if challenge.current >= challenge.target && !completedChallenges.contains(challenge.id) {
            completeChallenge(challenge)
        }
        
        saveChallenges()
    }
    
    private func completeChallenge(_ challenge: DailyChallenge) {
        completedChallenges.insert(challenge.id)
        newlyCompletedChallenge = challenge
        showChallengeComplete = true
        
        // Award XP through gamification manager
        GamificationManager.shared.awardXP(.dailyGoal)
        
        // Play celebration effects
        SoundEffectsManager.shared.playSound(.achievement)
        HapticFeedbackManager.shared.trigger(.achievement(tier: .gold))
        
        // Track in Firebase
        Task {
            await FirebaseManager.shared.trackAchievement("daily_challenge_\(challenge.type.rawValue)")
        }
        
        saveChallenges()
    }
    
    var completionPercentage: Double {
        guard !todaysChallenges.isEmpty else { return 0 }
        return Double(completedChallenges.count) / Double(todaysChallenges.count)
    }
    
    var totalXPAvailable: Int {
        return todaysChallenges.reduce(0) { $0 + $1.xpReward }
    }
    
    var earnedXP: Int {
        return todaysChallenges.filter { completedChallenges.contains($0.id) }.reduce(0) { $0 + $1.xpReward }
    }
    
    private func saveChallenges() {
        do {
            let challengesData = try JSONEncoder().encode(todaysChallenges)
            let completedData = try JSONEncoder().encode(Array(completedChallenges))
            
            UserDefaults.standard.set(challengesData, forKey: userDefaultsKey)
            UserDefaults.standard.set(completedData, forKey: completedKey)
        } catch {
            print("Error saving challenges: \(error)")
        }
    }
    
    private func loadChallenges() {
        // Load challenges
        if let challengesData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                todaysChallenges = try JSONDecoder().decode([DailyChallenge].self, from: challengesData)
            } catch {
                print("Error loading challenges: \(error)")
                todaysChallenges = []
            }
        }
        
        // Load completed challenges
        if let completedData = UserDefaults.standard.data(forKey: completedKey) {
            do {
                let completed = try JSONDecoder().decode([String].self, from: completedData)
                completedChallenges = Set(completed)
            } catch {
                print("Error loading completed challenges: \(error)")
                completedChallenges = []
            }
        }
    }
}

// MARK: - Challenge Models
struct DailyChallenge: Identifiable, Codable {
    let id: String
    let type: ChallengeType
    let title: String
    let description: String
    let target: Int
    var current: Int
    let xpReward: Int
    let difficulty: ChallengeDifficulty
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var isCompleted: Bool {
        return current >= target
    }
    
    var progressText: String {
        return "\(current)/\(target)"
    }
}

enum ChallengeType: String, CaseIterable, Codable {
    case completeCards = "complete_cards"
    case perfectStreak = "perfect_streak"
    case exploreTopics = "explore_topics"
    case speedChallenge = "speed_challenge"
    case comboMaster = "combo_master"
    case maintainStreak = "maintain_streak"
    case accuracyChallenge = "accuracy_challenge"
    
    var emoji: String {
        switch self {
        case .completeCards: return "📚"
        case .perfectStreak: return "🌟"
        case .exploreTopics: return "🗺️"
        case .speedChallenge: return "⚡"
        case .comboMaster: return "🔥"
        case .maintainStreak: return "📅"
        case .accuracyChallenge: return "🎯"
        }
    }
    
    var color: Color {
        switch self {
        case .completeCards: return .blue
        case .perfectStreak: return .yellow
        case .exploreTopics: return .green
        case .speedChallenge: return .orange
        case .comboMaster: return .red
        case .maintainStreak: return .purple
        case .accuracyChallenge: return .pink
        }
    }
}

enum ChallengeDifficulty: String, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var text: String {
        return rawValue.capitalized
    }
}
