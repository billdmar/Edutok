import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var gamificationManager: GamificationManager
    @State private var selectedCategory: AchievementCategory = .social
    @State private var showingMysteryBoxAnimation = false
    @State private var lastOpenedBoxReward: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Achievements")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Unlock achievements to earn XP and show off your progress!")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // Category Tabs
                    HStack(spacing: 0) {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedCategory = category
                                }
                            }) {
                                Text(category.rawValue)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.6))
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        selectedCategory == category ?
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.purple, .blue],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        : RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                    
                    // Achievements Grid for selected category
                    achievementsSection()
                    
                    // Daily Challenges Section
                    dailyChallengesSection()
                    
                    // Mystery Boxes Section
                    mysteryBoxesSection()
                    
                    // Quick Stats
                    quickStatsSection()
                }
                .padding(.bottom, 100)
            }
            .background(
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
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            gamificationManager.checkAndResetDailyMysteryBoxes()
        }
    }
    
    private func achievementsSection() -> some View {
        VStack(spacing: 15) {
            let categoryAchievements = Achievement.allCases.filter { $0.category == selectedCategory }
            
            if categoryAchievements.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "trophy")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No achievements in this category yet")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Keep learning to unlock more achievements!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(categoryAchievements, id: \.rawValue) { achievement in
                        achievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func achievementCard(achievement: Achievement) -> some View {
        let isUnlocked = gamificationManager.userProgress.achievementsUnlocked.contains(achievement.rawValue)
        
        return VStack(spacing: 12) {
            Text(achievement.emoji)
                .font(.system(size: 40))
                .opacity(isUnlocked ? 1.0 : 0.3)
            
            VStack(spacing: 5) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(isUnlocked ? .white.opacity(0.8) : .white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("+\(achievement.xpReward) XP")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isUnlocked ? .yellow : .white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isUnlocked ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isUnlocked ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
    }
    
    private func dailyChallengesSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Daily Challenges")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to challenges
                }
                .foregroundColor(.purple)
                .font(.caption)
            }
            .padding(.horizontal, 20)
            
            Text("Track your progress and unlock rewards!")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)
            
            HStack(spacing: 15) {
                challengeCard(title: "Card Master", progress: 0, total: 15, xp: 50)
                challengeCard(title: "Perfect Score", progress: 0, total: 10, xp: 75)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func challengeCard(title: String, progress: Int, total: Int, xp: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("+\(xp)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.2))
                    )
                
                Spacer()
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress) / CGFloat(total), height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(progress)/\(total)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func mysteryBoxesSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Mystery Boxes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if gamificationManager.remainingMysteryBoxes > 0 {
                    Text("\(gamificationManager.remainingMysteryBoxes) remaining")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 15) {
                ForEach(0..<3) { index in
                    mysteryBoxCard(index: index)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func mysteryBoxCard(index: Int) -> some View {
        let box = index < gamificationManager.userProgress.dailyMysteryBoxes.count ?
                  gamificationManager.userProgress.dailyMysteryBoxes[index] : nil
        let isOpened = box?.isOpened ?? false
        
        return Button(action: {
            if !isOpened {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if let reward = gamificationManager.openMysteryBox(at: index) {
                        lastOpenedBoxReward = reward
                        showingMysteryBoxAnimation = true
                        
                        // Hide animation after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showingMysteryBoxAnimation = false
                        }
                    }
                }
            }
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Image(systemName: isOpened ? "gift.fill" : "gift")
                        .font(.system(size: 40))
                        .foregroundColor(isOpened ? .white.opacity(0.3) : .yellow)
                        .scaleEffect(showingMysteryBoxAnimation && !isOpened ? 1.2 : 1.0)
                        .rotationEffect(.degrees(showingMysteryBoxAnimation && !isOpened ? 10 : 0))
                    
                    if isOpened, let reward = box?.xpReward {
                        Text("+\(reward)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .offset(y: -20)
                    }
                }
                
                Text(isOpened ? "Opened" : "Tap to open")
                    .font(.caption)
                    .foregroundColor(isOpened ? .white.opacity(0.5) : .white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isOpened ? Color.white.opacity(0.05) :
                          LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isOpened ? Color.white.opacity(0.1) : Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(isOpened)
        .scaleEffect(isOpened ? 0.95 : 1.0)
    }
    
    private func quickStatsSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Stats")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            HStack(spacing: 15) {
                statCard(icon: "star.fill", value: "\(gamificationManager.userProgress.achievementsUnlocked.count)", label: "Achievements")
                statCard(icon: "bolt.fill", value: "\(gamificationManager.userProgress.totalXP)", label: "Total XP")
                statCard(icon: "flame.fill", value: "0 days", label: "Streak")
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
