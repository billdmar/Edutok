// LeaderboardView.swift
import SwiftUI

struct LeaderboardView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var selectedType: LeaderboardType = .cardsFlipped
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with type selection
            VStack(spacing: 20) {
                Text("Daily Leaderboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Type toggle buttons
                HStack(spacing: 0) {
                    ForEach(LeaderboardType.allCases, id: \.self) { type in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedType = type
                                loadLeaderboard()
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: type.icon)
                                    .font(.title2)
                                
                                Text(type.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                            }
                            .foregroundColor(selectedType == type ? .white : .white.opacity(0.6))
                            .padding(.vertical, 15)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        selectedType == type
                                        ? LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.white.opacity(selectedType == type ? 0.3 : 0.1), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            
            // Current user stats
            if let user = firebaseManager.currentUser {
                currentUserStatsView(user: user)
            }
            
            // Leaderboard list
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isLoading {
                        ForEach(0..<10, id: \.self) { _ in
                            leaderboardLoadingRow()
                        }
                    } else if leaderboardEntries.isEmpty {
                        emptyLeaderboardView()
                    } else {
                        ForEach(leaderboardEntries) { entry in
                            leaderboardRow(entry: entry)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .refreshable {
                await refreshLeaderboard()
            }
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
        .onAppear {
            loadLeaderboard()
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }
    
    private func currentUserStatsView(user: AppUser) -> some View {
        VStack(spacing: 15) {
            HStack {
                Text("Your Daily Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("🔥 \(user.currentStreak) day streak")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.orange.opacity(0.2))
                    )
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Cards Flipped",
                    value: user.todayStats?.cardsFlipped ?? 0,
                    icon: "rectangle.stack.fill",
                    color: .purple,
                    isSelected: selectedType == .cardsFlipped
                )
                
                StatCard(
                    title: "Topics Explored",
                    value: user.todayStats?.topicsExplored ?? 0,
                    icon: "book.fill",
                    color: .blue,
                    isSelected: selectedType == .topicsExplored
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
        .padding(.bottom, 20)
    }
    
    private func leaderboardRow(entry: LeaderboardEntry) -> some View {
        HStack(spacing: 15) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor(entry.rank))
                    .frame(width: 40, height: 40)
                
                if entry.rank <= 3 {
                    Text(rankEmoji(entry.rank))
                        .font(.title3)
                } else {
                    Text("\(entry.rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.username)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if entry.isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("\(entry.value) \(selectedType == .cardsFlipped ? "cards" : "topics")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Value badge
            Text("\(entry.value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: selectedType == .cardsFlipped ? [.purple, .blue] : [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    entry.isCurrentUser
                    ? Color.yellow.opacity(0.1)
                    : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            entry.isCurrentUser
                            ? Color.yellow.opacity(0.3)
                            : Color.white.opacity(0.1),
                            lineWidth: entry.isCurrentUser ? 2 : 1
                        )
                )
        )
        .scaleEffect(entry.isCurrentUser ? 1.02 : 1.0)
        .shadow(
            color: entry.isCurrentUser ? .yellow.opacity(0.3) : .clear,
            radius: entry.isCurrentUser ? 8 : 0
        )
    }
    
    private func leaderboardLoadingRow() -> some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 20)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 14)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .frame(width: 60, height: 35)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .redacted(reason: .placeholder)
    }
    
    private func emptyLeaderboardView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No data yet today")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Start learning to appear on the leaderboard!")
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
    
    private func rankColor(_ rank: Int) -> LinearGradient {
        switch rank {
        case 1:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return LinearGradient(colors: [.gray, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            return LinearGradient(colors: [.orange, .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        
        Task {
            do {
                let entries = try await firebaseManager.fetchDailyLeaderboard(type: selectedType)
                
                await MainActor.run {
                    leaderboardEntries = entries
                    isLoading = false
                }
            } catch {
                print("Error loading leaderboard: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func refreshLeaderboard() async {
        do {
            let entries = try await firebaseManager.fetchDailyLeaderboard(type: selectedType)
            leaderboardEntries = entries
        } catch {
            print("Error refreshing leaderboard: \(error)")
        }
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await refreshLeaderboard()
            }
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    isSelected
                    ? LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            isSelected ? color.opacity(0.4) : Color.white.opacity(0.1),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
