// StatsSectionView.swift
import SwiftUI

enum StatsViewMode: String, CaseIterable {
    case calendar = "calendar"
    case leaderboard = "leaderboard"
    
    var title: String {
        switch self {
        case .calendar:
            return "Calendar"
        case .leaderboard:
            return "Leaderboard"
        }
    }
    
    var icon: String {
        switch self {
        case .calendar:
            return "calendar"
        case .leaderboard:
            return "trophy.fill"
        }
    }
}

struct StatsSectionView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var selectedMode: StatsViewMode = .calendar
    
    var body: some View {
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
                // Header with mode toggle
                headerView()
                
                // Content based on selected mode
                Group {
                    switch selectedMode {
                    case .calendar:
                        StreakCalendarView()
                    case .leaderboard:
                        LeaderboardView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            // Ensure user is authenticated
            if !firebaseManager.isAuthenticated {
                Task {
                    try? await firebaseManager.signInAnonymously()
                }
            }
        }
    }
    
    private func headerView() -> some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Text("Your Progress")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // User info (if authenticated)
                if let user = firebaseManager.currentUser {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(user.username)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Joined \(joinDateString(user.joinDate))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Mode toggle
            HStack(spacing: 0) {
                ForEach(StatsViewMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedMode = mode
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                            
                            Text(mode.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.6))
                        .padding(.vertical, 15)
                        .padding(.horizontal, 25)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    selectedMode == mode
                                    ? LinearGradient(
                                        colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            selectedMode == mode ? Color.white.opacity(0.3) : Color.clear,
                                            lineWidth: selectedMode == mode ? 1 : 0
                                        )
                                )
                        )
                    }
                    .scaleEffect(selectedMode == mode ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMode)
                }
            }
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            
            // Quick stats bar
            if let user = firebaseManager.currentUser {
                quickStatsBar(user: user)
            }
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }
    
    private func quickStatsBar(user: AppUser) -> some View {
        HStack(spacing: 20) {
            QuickStatItem(
                title: "Topics",
                value: "\(user.todayStats?.topicsExplored ?? 0)",
                subtitle: "explored",
                icon: "book.fill",
                color: .blue
            )
            
            Divider()
                .background(Color.white.opacity(0.2))
                .frame(height: 30)
            
            QuickStatItem(
                title: "Streak",
                value: "\(user.currentStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange
            )
            
            Divider()
                .background(Color.white.opacity(0.2))
                .frame(height: 30)
            
            QuickStatItem(
                title: "Cards",
                value: "\(user.todayStats?.cardsFlipped ?? 0)",
                subtitle: "flipped",
                icon: "rectangle.stack.fill",
                color: .purple
            )
        }
        .padding(.horizontal, 25)
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
    }
    
    private func joinDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Quick Stat Item Component
struct QuickStatItem: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Authentication Helper View
struct AuthenticationRequiredView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 15) {
                Text("Join the Community!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Sign in to track your progress, compete on leaderboards, and see your learning streaks.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                Task {
                    try? await firebaseManager.signInAnonymously()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.title3)
                    
                    Text("Join Now (Anonymous)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 5)
            }
            
            Text("No personal information required - completely anonymous!")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 40)
                .multilineTextAlignment(.center)
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
    }
}
