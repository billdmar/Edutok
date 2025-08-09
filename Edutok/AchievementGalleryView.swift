import SwiftUI

struct AchievementGalleryView: View {
    @StateObject private var gamificationManager = GamificationManager.shared
    @State private var selectedCategory: AchievementCategory = .all
    @State private var selectedAchievement: Achievement?
    @State private var showAchievementDetail = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
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
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerView()
                    
                    // Category filter
                    categoryFilterView()
                    
                    // Achievement grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredAchievements, id: \.rawValue) { achievement in
                                AchievementCardView(
                                    achievement: achievement,
                                    isUnlocked: gamificationManager.userProgress.achievementsUnlocked.contains(achievement.rawValue)
                                )
                                .onTapGesture {
                                    selectedAchievement = achievement
                                    showAchievementDetail = true
                                    HapticFeedbackManager.shared.trigger(.selection)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAchievementDetail) {
                if let achievement = selectedAchievement {
                    AchievementDetailView(achievement: achievement)
                }
            }
        }
    }
    
    private func headerView() -> some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Collection")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(unlockedCount)/\(totalAchievements) Unlocked")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: Double(unlockedCount) / Double(totalAchievements),
                    size: 60,
                    lineWidth: 6
                )
            }
            
            // Achievement stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Bronze",
                    count: tierCount(.bronze),
                    color: Color(hex: "#CD7F32")
                )
                
                StatCard(
                    title: "Silver",
                    count: tierCount(.silver),
                    color: Color(hex: "#C0C0C0")
                )
                
                StatCard(
                    title: "Gold",
                    count: tierCount(.gold),
                    color: Color(hex: "#FFD700")
                )
                
                StatCard(
                    title: "Platinum",
                    count: tierCount(.platinum),
                    color: Color(hex: "#E5E4E2")
                )
                
                StatCard(
                    title: "Diamond",
                    count: tierCount(.diamond),
                    color: Color(hex: "#B9F2FF")
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private func categoryFilterView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCategory = category
                        }
                        HapticFeedbackManager.shared.trigger(.selection)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 15)
    }
    
    private var filteredAchievements: [Achievement] {
        let allAchievements = Achievement.allCases
        
        switch selectedCategory {
        case .all:
            return allAchievements
        case .scholar:
            return allAchievements.filter { $0.rawValue.contains("scholar") }
        case .speed:
            return allAchievements.filter { $0.rawValue.contains("speed") }
        case .combo:
            return allAchievements.filter { $0.rawValue.contains("combo") }
        case .dedication:
            return allAchievements.filter { $0.rawValue.contains("dedicated") || $0 == .unstoppable }
        case .perfectionist:
            return allAchievements.filter { $0.rawValue.contains("perfect") }
        case .special:
            return [.nightOwl, .earlyBird, .explorer, .weekendWarrior, .firstCard]
        }
    }
    
    private var unlockedCount: Int {
        return gamificationManager.userProgress.achievementsUnlocked.count
    }
    
    private var totalAchievements: Int {
        return Achievement.allCases.count
    }
    
    private func tierCount(_ tier: AchievementTier) -> Int {
        return gamificationManager.userProgress.achievementsUnlocked.compactMap { achievementId in
            Achievement.allCases.first { $0.rawValue == achievementId }
        }.filter { $0.tier == tier }.count
    }
}

// MARK: - Achievement Card View
struct AchievementCardView: View {
    let achievement: Achievement
    let isUnlocked: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                // Glow effect for unlocked achievements
                if isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: tierGradientColors(achievement.tier).map { $0.opacity(0.3) },
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 10)
                        .opacity(isAnimating ? 0.8 : 0.4)
                }
                
                // Achievement badge
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked ?
                            LinearGradient(
                                colors: tierGradientColors(achievement.tier),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(
                                    isUnlocked ? Color.white.opacity(0.3) : Color.gray.opacity(0.2),
                                    lineWidth: 2
                                )
                        )
                    
                    Text(achievement.emoji)
                        .font(.system(size: 35))
                        .grayscale(isUnlocked ? 0 : 1)
                        .opacity(isUnlocked ? 1 : 0.5)
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
            }
            
            VStack(spacing: 8) {
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(isUnlocked ? 0.7 : 0.4))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                if isUnlocked {
                    HStack(spacing: 5) {
                        Text("+\(achievement.xpReward) XP")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(achievement.tier.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(tierColor(achievement.tier))
                    }
                } else {
                    Text("Locked")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isUnlocked ?
                    Color.white.opacity(0.08) :
                    Color.white.opacity(0.03)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isUnlocked ?
                            LinearGradient(
                                colors: tierGradientColors(achievement.tier).map { $0.opacity(0.5) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            if isUnlocked {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func tierGradientColors(_ tier: AchievementTier) -> [Color] {
        switch tier {
        case .bronze:
            return [Color(hex: "#CD7F32"), Color(hex: "#D2B48C")]
        case .silver:
            return [Color(hex: "#C0C0C0"), Color(hex: "#E5E5E5")]
        case .gold:
            return [Color(hex: "#FFD700"), Color(hex: "#FFA500")]
        case .platinum:
            return [Color(hex: "#E5E4E2"), Color(hex: "#F8F8FF")]
        case .diamond:
            return [Color(hex: "#B9F2FF"), Color(hex: "#87CEEB")]
        }
    }
    
    private func tierColor(_ tier: AchievementTier) -> Color {
        Color(hex: tier.color)
    }
}

// MARK: - Achievement Detail View
struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gamificationManager = GamificationManager.shared
    
    private var isUnlocked: Bool {
        gamificationManager.userProgress.achievementsUnlocked.contains(achievement.rawValue)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Close button
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                Spacer()
                
                // Achievement display
                VStack(spacing: 25) {
                    ZStack {
                        if isUnlocked {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.yellow.opacity(0.3), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                        }
                        
                        Circle()
                            .fill(
                                isUnlocked ?
                                LinearGradient(
                                    colors: tierGradientColors(achievement.tier),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            )
                        
                        Text(achievement.emoji)
                            .font(.system(size: 60))
                            .grayscale(isUnlocked ? 0 : 1)
                    }
                    
                    VStack(spacing: 15) {
                        Text(achievement.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(achievement.description)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(achievement.xpReward)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                                
                                Text("XP Reward")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            VStack {
                                Text(achievement.tier.rawValue.capitalized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: achievement.tier.color))
                                
                                Text("Tier")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                        
                        if isUnlocked {
                            Text("🎉 Achievement Unlocked! 🎉")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            Text("🔒 Keep learning to unlock!")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func tierGradientColors(_ tier: AchievementTier) -> [Color] {
        switch tier {
        case .bronze:
            return [Color(hex: "#CD7F32"), Color(hex: "#D2B48C")]
        case .silver:
            return [Color(hex: "#C0C0C0"), Color(hex: "#E5E5E5")]
        case .gold:
            return [Color(hex: "#FFD700"), Color(hex: "#FFA500")]
        case .platinum:
            return [Color(hex: "#E5E4E2"), Color(hex: "#F8F8FF")]
        case .diamond:
            return [Color(hex: "#B9F2FF"), Color(hex: "#87CEEB")]
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct CategoryButton: View {
    let category: AchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                    .font(.caption)
                
                Text(category.title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Achievement Categories
enum AchievementCategory: String, CaseIterable {
    case all = "all"
    case scholar = "scholar"
    case speed = "speed"
    case combo = "combo"
    case dedication = "dedication"
    case perfectionist = "perfectionist"
    case special = "special"
    
    var title: String {
        switch self {
        case .all: return "All"
        case .scholar: return "Scholar"
        case .speed: return "Speed"
        case .combo: return "Combo"
        case .dedication: return "Dedication"
        case .perfectionist: return "Perfect"
        case .special: return "Special"
        }
    }
    
    var emoji: String {
        switch self {
        case .all: return "🏆"
        case .scholar: return "📚"
        case .speed: return "⚡"
        case .combo: return "🔥"
        case .dedication: return "🎯"
        case .perfectionist: return "💎"
        case .special: return "⭐"
        }
    }
}
