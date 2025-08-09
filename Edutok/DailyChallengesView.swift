import SwiftUI

// MARK: - Daily Challenges Overview
struct DailyChallengesView: View {
    @StateObject private var challengesManager = DailyChallengesManager.shared
    @State private var showChallengeDetail = false
    @State private var selectedChallenge: DailyChallenge?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.orange.opacity(0.3),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with progress
                        headerView()
                        
                        // Challenges list
                        VStack(spacing: 15) {
                            ForEach(challengesManager.todaysChallenges) { challenge in
                                DailyChallengeCard(challenge: challenge) {
                                    selectedChallenge = challenge
                                    showChallengeDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Completion bonus section
                        if challengesManager.completionPercentage > 0 {
                            completionBonusView()
                        }
                        
                        Color.clear.frame(height: 100) // Navigation padding
                    }
                }
            }
            .navigationTitle("Daily Challenges")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                challengesManager.checkForNewDay()
            }
            .sheet(isPresented: $showChallengeDetail) {
                if let challenge = selectedChallenge {
                    ChallengeDetailView(challenge: challenge)
                }
            }
            .overlay(
                // Challenge completion notification
                VStack {
                    Spacer()
                    if challengesManager.showChallengeComplete,
                       let challenge = challengesManager.newlyCompletedChallenge {
                        ChallengeCompleteView(challenge: challenge, isShowing: $challengesManager.showChallengeComplete)
                            .padding(.bottom, 120)
                    }
                }
                .animation(.spring(), value: challengesManager.showChallengeComplete)
            )
        }
    }
    
    private func headerView() -> some View {
        VStack(spacing: 20) {
            // Progress ring and stats
            HStack(spacing: 30) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: challengesManager.completionPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: challengesManager.completionPercentage)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(challengesManager.completionPercentage * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🎯")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today's Challenges")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(challengesManager.completedChallenges.count)/\(challengesManager.todaysChallenges.count) Completed")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(challengesManager.earnedXP)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                            
                            Text("XP Earned")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(challengesManager.totalXPAvailable)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            
                            Text("XP Available")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
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
    
    private func completionBonusView() -> some View {
        VStack(spacing: 15) {
            Text("🎉 Daily Challenge Bonus 🎉")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
            
            if challengesManager.completionPercentage >= 1.0 {
                VStack(spacing: 8) {
                    Text("All Challenges Complete!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("You've earned a 50% XP bonus for tomorrow!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 8) {
                    Text("Complete all challenges for bonus XP!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("\(challengesManager.todaysChallenges.count - challengesManager.completedChallenges.count) left to go!")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Daily Challenge Card
struct DailyChallengeCard: View {
    let challenge: DailyChallenge
    let onTap: () -> Void
    @StateObject private var challengesManager = DailyChallengesManager.shared
    
    private var isCompleted: Bool {
        challengesManager.completedChallenges.contains(challenge.id)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 15) {
                HStack {
                    // Challenge icon and type
                    HStack(spacing: 10) {
                        Text(challenge.type.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(challenge.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Spacer()
                    
                    // Completion status
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.green : Color.white.opacity(0.2))
                            .frame(width: 30, height: 30)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Progress bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress: \(challenge.progressText)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("+\(challenge.xpReward) XP")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(challenge.difficulty.text)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(challenge.difficulty.color)
                        }
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: isCompleted ? [.green, .mint] : [challenge.type.color, challenge.type.color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * challenge.progress, height: 6)
                                .animation(.easeInOut(duration: 0.5), value: challenge.progress)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        isCompleted ?
                        Color.green.opacity(0.1) :
                        Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isCompleted ?
                                Color.green.opacity(0.3) :
                                challenge.type.color.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isCompleted ? 0.98 : 1.0)
            .opacity(isCompleted ? 0.8 : 1.0)
        }
        .disabled(isCompleted)
        .onTapHaptic(.selection) {
            // Action handled by button
        }
    }
}

// MARK: - Challenge Detail View
struct ChallengeDetailView: View {
    let challenge: DailyChallenge
    @Environment(\.dismiss) private var dismiss
    @StateObject private var challengesManager = DailyChallengesManager.shared
    
    private var isCompleted: Bool {
        challengesManager.completedChallenges.contains(challenge.id)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(challenge.difficulty.text)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(challenge.difficulty.color.opacity(0.3))
                        )
                }
                .padding()
                
                Spacer()
                
                // Challenge details
                VStack(spacing: 25) {
                    Text(challenge.type.emoji)
                        .font(.system(size: 80))
                    
                    VStack(spacing: 15) {
                        Text(challenge.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(challenge.description)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Progress section
                    VStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 10)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: challenge.progress)
                                .stroke(
                                    LinearGradient(
                                        colors: [challenge.type.color, challenge.type.color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: challenge.progress)
                            
                            VStack(spacing: 2) {
                                Text(challenge.progressText)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("\(Int(challenge.progress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        if isCompleted {
                            VStack(spacing: 8) {
                                Text("🎉 Challenge Complete! 🎉")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                
                                Text("You earned \(challenge.xpReward) XP!")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                            }
                        } else {
                            Text("Keep going! You're doing great!")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Reward info
                    VStack(spacing: 10) {
                        Text("Reward")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("+\(challenge.xpReward) XP")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Challenge Complete Notification
struct ChallengeCompleteView: View {
    let challenge: DailyChallenge
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 15) {
            Text(challenge.type.emoji)
                .font(.system(size: 40))
                .rotationEffect(.degrees(rotation))
            
            VStack(spacing: 8) {
                Text("Challenge Complete!")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text(challenge.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("+\(challenge.xpReward) XP Earned!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green, lineWidth: 2)
                )
                .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 5)
        )
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                rotation = 15
            }
            
            // Auto dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scale = 0.1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Compact Daily Challenges Widget (for main screen)
struct DailyChallengesWidget: View {
    @StateObject private var challengesManager = DailyChallengesManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🎯 Daily Challenges")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(challengesManager.completedChallenges.count)/\(challengesManager.todaysChallenges.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.2))
                    )
            }
            
            VStack(spacing: 8) {
                ForEach(challengesManager.todaysChallenges.prefix(2)) { challenge in
                    HStack(spacing: 10) {
                        Text(challenge.type.emoji)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(challenge.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 3)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(challenge.type.color)
                                        .frame(width: geometry.size.width * challenge.progress, height: 3)
                                }
                            }
                            .frame(height: 3)
                        }
                        
                        Spacer()
                        
                        if challengesManager.completedChallenges.contains(challenge.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                if challengesManager.todaysChallenges.count > 2 {
                    Text("+ \(challengesManager.todaysChallenges.count - 2) more")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            challengesManager.checkForNewDay()
        }
    }
}
