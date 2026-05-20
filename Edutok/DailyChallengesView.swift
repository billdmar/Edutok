import SwiftUI

struct DailyChallengesView: View {
    @ObservedObject var gamificationManager: GamificationManager
    @Environment(\.dismiss) private var dismiss
    
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
                        Text("Daily Challenges")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Complete challenges to earn bonus XP!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Challenges list
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(gamificationManager.dailyChallenges) { challenge in
                                ChallengeCard(challenge: challenge)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Mystery boxes section
                    if !gamificationManager.availableMysteryBoxes.isEmpty {
                        VStack(spacing: 15) {
                            Text("Mystery Boxes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(gamificationManager.availableMysteryBoxes) { box in
                                        MysteryBoxCard(
                                            box: box,
                                            onTap: {
                                                gamificationManager.openMysteryBox(box)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
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
        .sheet(isPresented: $gamificationManager.shouldShowMysteryBox) {
            if let box = gamificationManager.currentMysteryBox {
                MysteryBoxRewardView(box: box)
            }
        }
    }
}

struct ChallengeCard: View {
    let challenge: DailyChallenge
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(challenge.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("+\(challenge.xpReward)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("XP")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.8))
                }
            }
            
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("\(challenge.currentValue)/\(challenge.targetValue)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    if challenge.isCompleted {
                        Text("Completed! 🎉")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                ProgressView(value: challenge.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: challenge.isCompleted ? .green : .purple))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Challenge type indicator
            HStack {
                Image(systemName: challenge.type.icon)
                    .foregroundColor(Color(challenge.type.color))
                
                Text(challenge.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if challenge.isExpired {
                    Text("Expired")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    challenge.isCompleted
                    ? Color.green.opacity(0.1)
                    : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            challenge.isCompleted ? Color.green.opacity(0.3) : Color.white.opacity(0.1),
                            lineWidth: challenge.isCompleted ? 2 : 1
                        )
                )
        )
        .scaleEffect(challenge.isCompleted ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: challenge.isCompleted)
    }
}

struct MysteryBoxCard: View {
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
                        .frame(width: 60, height: 60)
                    
                    if box.isOpened {
                        Text("+\(box.xpAmount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("?")
                            .font(.title)
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(box.rarity.color).opacity(0.2))
                    .cornerRadius(8)
            }
            .frame(width: 100, height: 120)
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        box.isOpened
                        ? Color.gray.opacity(0.1)
                        : Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                box.isOpened ? Color.gray.opacity(0.3) : Color(box.rarity.color).opacity(0.5),
                                lineWidth: box.isOpened ? 1 : 2
                            )
                    )
            )
        }
        .disabled(box.isOpened)
        .scaleEffect(box.isOpened ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: box.isOpened)
    }
}

struct MysteryBoxRewardView: View {
    let box: MysteryBox
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Mystery box animation
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
                        .frame(width: 120, height: 120)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 0.5).repeatCount(3), value: box.xpAmount)
                    
                    Text("+\(box.xpAmount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 15) {
                    Text("You got \(box.xpAmount) XP!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(box.rarity.rawValue.capitalized) Mystery Box")
                        .font(.headline)
                        .foregroundColor(Color(box.rarity.color))
                    
                    Text("Great job! Keep learning to earn more rewards.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Button("Continue") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(40)
        }
    }
}

#Preview {
    DailyChallengesView(gamificationManager: GamificationManager())
} 