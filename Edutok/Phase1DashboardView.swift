import SwiftUI

struct Phase1DashboardView: View {
    @ObservedObject var gamificationManager: GamificationManager
    @State private var showDailyChallenges = false
    @State private var showEnhancedAchievements = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.purple.opacity(0.3),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 10) {
                            Text("Learning Dashboard")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Track your progress and unlock rewards!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        // Daily Challenges Section
                        VStack(spacing: 15) {
                            HStack {
                                Text("Daily Challenges")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showDailyChallenges = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.purple)
                            }
                            
                            // Challenge preview cards
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(gamificationManager.dailyChallenges.prefix(2)) { challenge in
                                        ChallengePreviewCard(challenge: challenge)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Mystery Boxes Section
                        if !gamificationManager.availableMysteryBoxes.isEmpty {
                            VStack(spacing: 15) {
                                HStack {
                                    Text("Mystery Boxes")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(gamificationManager.availableMysteryBoxes.filter { !$0.isOpened }.count) remaining")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.yellow.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(gamificationManager.availableMysteryBoxes) { box in
                                            MysteryBoxPreviewCard(box: box) {
                                                gamificationManager.openMysteryBox(box)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Enhanced Achievements Section
                        VStack(spacing: 15) {
                            HStack {
                                Text("Recent Achievements")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showEnhancedAchievements = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.purple)
                            }
                            
                            // Achievement preview cards
                            let unlockedAchievements = gamificationManager.enhancedAchievements.filter { $0.isUnlocked }
                            if unlockedAchievements.isEmpty {
                                emptyAchievementsView()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(Array(unlockedAchievements.prefix(3))) { achievement in
                                            AchievementPreviewCard(achievement: achievement)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Quick Stats Section
                        VStack(spacing: 15) {
                            Text("Quick Stats")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                StatPreviewCard(
                                    title: "Level",
                                    value: "\(gamificationManager.userProgress.currentLevel)",
                                    icon: "star.fill",
                                    color: .yellow
                                )
                                
                                StatPreviewCard(
                                    title: "XP Today",
                                    value: "\(gamificationManager.userProgress.xpGainedToday)",
                                    icon: "bolt.fill",
                                    color: .orange
                                )
                                
                                StatPreviewCard(
                                    title: "Streak",
                                    value: "\(gamificationManager.userProgress.currentStreak) days",
                                    icon: "flame.fill",
                                    color: .red
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showDailyChallenges) {
            DailyChallengesView(gamificationManager: gamificationManager)
        }
        .sheet(isPresented: $showEnhancedAchievements) {
            EnhancedAchievementsView(gamificationManager: gamificationManager)
        }
        .sheet(isPresented: $gamificationManager.shouldShowMysteryBox) {
            if let box = gamificationManager.currentMysteryBox {
                MysteryBoxRewardView(box: box)
            }
        }
    }
    
    private func emptyAchievementsView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "trophy")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No achievements unlocked yet")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .padding(.horizontal, 20)
    }
}

struct ChallengePreviewCard: View {
    let challenge: DailyChallenge
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: challenge.type.icon)
                    .foregroundColor(Color(challenge.type.color))
                    .font(.title2)
                
                Spacer()
                
                Text("+\(challenge.xpReward)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
            
            Text(challenge.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            ProgressView(value: challenge.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: challenge.isCompleted ? .green : .purple))
            
            HStack {
                Text("\(challenge.currentValue)/\(challenge.targetValue)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if challenge.isCompleted {
                    Text("✓")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(15)
        .frame(width: 160, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    challenge.isCompleted
                    ? Color.green.opacity(0.1)
                    : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            challenge.isCompleted ? Color.green.opacity(0.3) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct MysteryBoxPreviewCard: View {
    let box: MysteryBox
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(box.rarity.color),
                                    Color(box.rarity.color).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    if box.isOpened {
                        Text("+\(box.xpAmount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                Text(box.isOpened ? "Opened" : "Tap to Open")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text(box.rarity.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(Color(box.rarity.color))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(box.rarity.color).opacity(0.2))
                    .cornerRadius(6)
            }
            .frame(width: 100, height: 120)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        box.isOpened
                        ? Color.gray.opacity(0.1)
                        : Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                box.isOpened ? Color.gray.opacity(0.3) : Color(box.rarity.color).opacity(0.5),
                                lineWidth: box.isOpened ? 1 : 2
                            )
                    )
            )
        }
        .disabled(box.isOpened)
    }
}

struct AchievementPreviewCard: View {
    let achievement: EnhancedAchievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(achievement.rarity.color),
                                Color(achievement.rarity.color).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("+\(achievement.xpReward) XP")
                .font(.caption2)
                .foregroundColor(.yellow)
                .fontWeight(.bold)
        }
        .frame(width: 100, height: 120)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct StatPreviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    Phase1DashboardView(gamificationManager: GamificationManager())
} 