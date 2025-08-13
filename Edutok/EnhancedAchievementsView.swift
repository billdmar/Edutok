import SwiftUI

struct EnhancedAchievementsView: View {
    @ObservedObject var gamificationManager: GamificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: AchievementCategory = .learning
    
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
                
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Achievements")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Unlock achievements to earn XP and show off your progress!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Category selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(AchievementCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Achievements list
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            let filteredAchievements = gamificationManager.enhancedAchievements.filter { $0.category == selectedCategory }
                            
                            if filteredAchievements.isEmpty {
                                emptyCategoryView()
                            } else {
                                ForEach(filteredAchievements) { achievement in
                                    AchievementCard(achievement: achievement)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
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
    }
    
    private func emptyCategoryView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No achievements in this category yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Keep learning to unlock more achievements!")
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
}

struct CategoryButton: View {
    let category: AchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
                )
        }
    }
}

struct AchievementCard: View {
    let achievement: EnhancedAchievement
    
    var body: some View {
        HStack(spacing: 20) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked
                        ? LinearGradient(
                            colors: [
                                Color(achievement.rarity.color),
                                Color(achievement.rarity.color).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.displayIcon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.5))
            }
            
            // Achievement details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(achievement.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if achievement.isUnlocked {
                        Text("+\(achievement.xpReward)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                
                HStack {
                    // Rarity badge
                    Text(achievement.rarity.rawValue.capitalized)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(achievement.rarity.color).opacity(0.3))
                        .cornerRadius(8)
                    
                    // Category badge
                    Text(achievement.category.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if achievement.isUnlocked {
                        Text("Unlocked")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    } else {
                        Text("Locked")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    achievement.isUnlocked
                    ? Color.green.opacity(0.05)
                    : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            achievement.isUnlocked ? Color.green.opacity(0.2) : Color.white.opacity(0.1),
                            lineWidth: achievement.isUnlocked ? 2 : 1
                        )
                )
        )
        .scaleEffect(achievement.isUnlocked ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: achievement.isUnlocked)
    }
}

#Preview {
    EnhancedAchievementsView(gamificationManager: GamificationManager())
} 