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
            // Simple header with toggle
            VStack(spacing: 15) {
                Text("Daily Leaderboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                // Compact toggle
                HStack(spacing: 0) {
                    ForEach(LeaderboardType.allCases, id: \.self) { type in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedType = type
                                loadLeaderboard()
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.title3)
                                
                                Text(type == .cardsFlipped ? "Cards" : "Topics")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(selectedType == type ? .white : .white.opacity(0.6))
                            .padding(.vertical, 12)
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
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.8), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .top)
            )
            
            // Leaderboard list - takes up full remaining space
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Current user highlight at top
                    if let user = firebaseManager.currentUser,
                       let userEntry = leaderboardEntries.first(where: { $0.isCurrentUser }) {
                        VStack(spacing: 10) {
                            Text("Your Rank")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.7))
                            
                            leaderboardRow(entry: userEntry)
                        }
                        .padding(.bottom, 15)
                    }
                    
                    if isLoading {
                        ForEach(0..<15, id: \.self) { _ in
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
                .padding(.bottom, 120) // Extra padding for floating nav
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
        .refreshable {
            await refreshLeaderboard()
        }
        .onAppear {
            loadLeaderboard()
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
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
