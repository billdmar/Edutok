// DebugView.swift
import SwiftUI

struct DebugView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var debugLog: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection()
                    
                    // Current User Info
                    if let user = firebaseManager.currentUser {
                        currentUserSection(user: user)
                    } else {
                        noUserSection()
                    }
                    
                    // Action Buttons
                    actionButtonsSection()
                    
                    // Debug Log
                    debugLogSection()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
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
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Log") {
                        debugLog.removeAll()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            addToLog("Debug view opened")
            if firebaseManager.isAuthenticated {
                addToLog("User is authenticated: \(firebaseManager.currentUser?.username ?? "Unknown")")
            } else {
                addToLog("User is not authenticated")
            }
        }
    }
    
    private func headerSection() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Firebase Debug Console")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Test Firebase functionality and tracking")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private func currentUserSection(user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Current User")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Text("Online")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .offset(x: 25)
                    )
            }
            
            VStack(spacing: 12) {
                DebugInfoRow(label: "ID", value: user.id)
                DebugInfoRow(label: "Username", value: user.username)
                DebugInfoRow(label: "Total Cards", value: "\(user.totalCardsFlipped)")
                DebugInfoRow(label: "Total Topics", value: "\(user.totalTopicsExplored)")
                DebugInfoRow(label: "Current Streak", value: "\(user.currentStreak) days")
                DebugInfoRow(label: "Longest Streak", value: "\(user.longestStreak) days")
                DebugInfoRow(label: "Join Date", value: formatDate(user.joinDate))
                DebugInfoRow(label: "Last Active", value: formatDate(user.lastActiveDate))
                DebugInfoRow(label: "Daily Stats Count", value: "\(user.dailyStats.count)")
                
                if let todayStats = user.todayStats {
                    DebugInfoRow(label: "Today Cards", value: "\(todayStats.cardsFlipped)")
                    DebugInfoRow(label: "Today Topics", value: "\(todayStats.topicsExplored)")
                    DebugInfoRow(label: "Today Achievements", value: "\(todayStats.achievements.count)")
                } else {
                    DebugInfoRow(label: "Today Stats", value: "No activity")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func noUserSection() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("No User Authenticated")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Sign in to test user functionality")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Button("Sign In Anonymously") {
                signInAnonymously()
            }
            .buttonStyle(DebugButtonStyle(color: .blue))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func actionButtonsSection() -> some View {
        VStack(spacing: 15) {
            Text("Test Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                // Card tracking
                Button("Track 1 Card Flipped") {
                    trackCardFlipped()
                }
                .buttonStyle(DebugButtonStyle(color: .purple))
                
                Button("Track 5 Cards Flipped") {
                    trackMultipleCards(5)
                }
                .buttonStyle(DebugButtonStyle(color: .purple))
                
                // Topic tracking
                Button("Track 1 Topic Explored") {
                    trackTopicExplored()
                }
                .buttonStyle(DebugButtonStyle(color: .blue))
                
                Button("Track 3 Topics Explored") {
                    trackMultipleTopics(3)
                }
                .buttonStyle(DebugButtonStyle(color: .blue))
                
                // Achievement tracking
                Button("Award First Card Achievement") {
                    trackAchievement(.firstCard)
                }
                .buttonStyle(DebugButtonStyle(color: .yellow))
                
                Button("Award Scholar Achievement") {
                    trackAchievement(.scholar)
                }
                .buttonStyle(DebugButtonStyle(color: .yellow))
                
                // Leaderboard testing
                Button("Fetch Cards Leaderboard") {
                    fetchLeaderboard(.cardsFlipped)
                }
                .buttonStyle(DebugButtonStyle(color: .green))
                
                Button("Fetch Topics Leaderboard") {
                    fetchLeaderboard(.topicsExplored)
                }
                .buttonStyle(DebugButtonStyle(color: .green))
                
                // Reset actions
                Button("Sign Out") {
                    signOut()
                }
                .buttonStyle(DebugButtonStyle(color: .red))
                
                Button("Reset Daily Stats") {
                    resetDailyStats()
                }
                .buttonStyle(DebugButtonStyle(color: .orange))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
    
    private func debugLogSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Debug Log")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(debugLog.count) entries")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(debugLog.enumerated().reversed()), id: \.offset) { index, entry in
                        HStack(alignment: .top) {
                            Text("\(debugLog.count - index).")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 30, alignment: .trailing)
                            
                            Text(entry)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.03))
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Debug Actions
    
    private func signInAnonymously() {
        isLoading = true
        addToLog("Attempting anonymous sign in...")
        
        Task {
            do {
                try await firebaseManager.signInAnonymously()
                await MainActor.run {
                    addToLog("✅ Successfully signed in anonymously")
                    addToLog("User ID: \(firebaseManager.currentUser?.id ?? "Unknown")")
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    addToLog("❌ Error signing in: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }
    
    private func trackCardFlipped() {
        addToLog("Tracking 1 card flipped...")
        
        Task {
            await firebaseManager.trackCardFlipped()
            await MainActor.run {
                addToLog("✅ Card flipped tracked successfully")
                if let user = firebaseManager.currentUser {
                    addToLog("Total cards: \(user.totalCardsFlipped)")
                    addToLog("Today cards: \(user.todayStats?.cardsFlipped ?? 0)")
                }
            }
        }
    }
    
    private func trackMultipleCards(_ count: Int) {
        addToLog("Tracking \(count) cards flipped...")
        
        Task {
            for i in 1...count {
                await firebaseManager.trackCardFlipped()
                await MainActor.run {
                    addToLog("Card \(i)/\(count) tracked")
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
            }
            await MainActor.run {
                addToLog("✅ All \(count) cards tracked successfully")
            }
        }
    }
    
    private func trackTopicExplored() {
        addToLog("Tracking 1 topic explored...")
        
        Task {
            await firebaseManager.trackTopicExplored()
            await MainActor.run {
                addToLog("✅ Topic explored tracked successfully")
                if let user = firebaseManager.currentUser {
                    addToLog("Total topics: \(user.totalTopicsExplored)")
                    addToLog("Today topics: \(user.todayStats?.topicsExplored ?? 0)")
                }
            }
        }
    }
    
    private func trackMultipleTopics(_ count: Int) {
        addToLog("Tracking \(count) topics explored...")
        
        Task {
            for i in 1...count {
                await firebaseManager.trackTopicExplored()
                await MainActor.run {
                    addToLog("Topic \(i)/\(count) tracked")
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
            }
            await MainActor.run {
                addToLog("✅ All \(count) topics tracked successfully")
            }
        }
    }
    
    private func trackAchievement(_ achievement: Achievement) {
        addToLog("Tracking achievement: \(achievement.title)")
        
        Task {
            await firebaseManager.trackAchievement(achievement.rawValue)
            await MainActor.run {
                addToLog("✅ Achievement tracked: \(achievement.emoji) \(achievement.title)")
            }
        }
    }
    
    private func fetchLeaderboard(_ type: LeaderboardType) {
        addToLog("Fetching \(type.title) leaderboard...")
        
        Task {
            do {
                let entries = try await firebaseManager.fetchDailyLeaderboard(type: type)
                await MainActor.run {
                    addToLog("✅ Leaderboard fetched: \(entries.count) entries")
                    for (index, entry) in entries.prefix(3).enumerated() {
                        let position = index + 1
                        let indicator = entry.isCurrentUser ? " (YOU)" : ""
                        addToLog("  \(position). \(entry.username): \(entry.value)\(indicator)")
                    }
                }
            } catch {
                await MainActor.run {
                    addToLog("❌ Error fetching leaderboard: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func signOut() {
        addToLog("Signing out...")
        firebaseManager.signOut()
        addToLog("✅ Signed out successfully")
    }
    
    private func resetDailyStats() {
        guard var user = firebaseManager.currentUser else {
            addToLog("❌ No user to reset stats for")
            return
        }
        
        addToLog("Resetting daily stats...")
        
        // Reset today's stats
        let today = Calendar.current.startOfDay(for: Date())
        if let todayIndex = user.dailyStats.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            user.dailyStats[todayIndex].cardsFlipped = 0
            user.dailyStats[todayIndex].topicsExplored = 0
            user.dailyStats[todayIndex].achievements = []
        }
        
        // Note: In a real app, you'd save this back to Firebase
        addToLog("✅ Daily stats reset (local only - not saved to Firebase)")
    }
    
    // MARK: - Helper Functions
    
    private func addToLog(_ message: String) {
        let timestamp = DateFormatter.timeFormatter.string(from: Date())
        debugLog.append("[\(timestamp)] \(message)")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views and Styles

struct DebugInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct DebugButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(configuration.isPressed ? 0.8 : 0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.8), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}
