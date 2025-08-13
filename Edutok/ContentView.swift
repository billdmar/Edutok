// ContentView.swift
import SwiftUI

enum AppSection {
    case main, flashcards, leaderboard, calendar
}

struct ContentView: View {
    @EnvironmentObject var topicManager: TopicManager
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var currentSection: AppSection = .main
    
    var body: some View {
        ZStack {
            // Main content based on current section
            Group {
                switch currentSection {
                case .main:
                    if topicManager.currentTopic != nil {
                        FlashcardView()
                    } else {
                        MainView()
                    }
                case .flashcards:
                    if topicManager.currentTopic != nil {
                        FlashcardView()
                    } else {
                        MainView()
                    }
                case .leaderboard:
                    LeaderboardWrapper()
                case .calendar:
                    StandaloneCalendarView(isShowing: .constant(true))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentSection)
            
            // Floating navigation bar at bottom (show for all main sections, hide only during flashcard study)
            if currentSection != .flashcards {
                VStack {
                    Spacer()
                    floatingNavBar()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000) // Ensure nav bar appears above other content
            }
        }
        .onAppear {
            topicManager.loadSavedTopics()
            
            // Auto-authenticate if not already authenticated
            if !firebaseManager.isAuthenticated {
                Task {
                    try? await firebaseManager.signInAnonymously()
                }
            }
        }
        .onChange(of: topicManager.currentTopic) { topic in
            // Automatically switch to flashcards section when a topic is selected
            if topic != nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSection = .flashcards
                }
            } else if currentSection == .flashcards {
                // Return to main when exiting flashcard mode
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSection = .main
                }
            }
        }
    }
    
    private func floatingNavBar() -> some View {
        HStack(spacing: 0) {
            // Leaderboard button (left)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSection = .leaderboard
                    topicManager.currentTopic = nil
                }
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Image(systemName: currentSection == .leaderboard ? "trophy.fill" : "trophy")
                            .font(.title3)
                            .foregroundColor(currentSection == .leaderboard ? .yellow : .white)
                        
                        // Notification badge for achievements or streaks
                        if let user = firebaseManager.currentUser,
                           user.currentStreak > 0 || !user.dailyStats.isEmpty {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                    
                    Text("Leaderboard")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(currentSection == .leaderboard ? .yellow : .white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            
            // Main/Learn button (center)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSection = .main
                    topicManager.currentTopic = nil
                }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: currentSection == .main ? "brain.head.profile.fill" : "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(currentSection == .main ? .purple : .white)
                    
                    Text("Learn")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(currentSection == .main ? .purple : .white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            
            // Calendar button (right)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSection = .calendar
                    topicManager.currentTopic = nil
                }
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Image(systemName: currentSection == .calendar ? "calendar.circle.fill" : "calendar")
                            .font(.title3)
                            .foregroundColor(currentSection == .calendar ? .blue : .white)
                        
                        // Streak indicator
                        if let user = firebaseManager.currentUser, user.currentStreak > 0 {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                    
                    Text("Calendar")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(currentSection == .calendar ? .blue : .white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
}

// MARK: - Extensions
extension Color {
    static let flashTokPurple = Color(red: 0.6, green: 0.4, blue: 0.8)
    static let flashTokPink = Color(red: 0.9, green: 0.4, blue: 0.6)
    static let flashTokBlue = Color(red: 0.3, green: 0.6, blue: 0.9)
}

extension View {
    func flashTokStyle() -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: [Color.flashTokPurple, Color.flashTokPink]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
