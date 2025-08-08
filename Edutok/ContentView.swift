// ContentView.swift
import SwiftUI

enum AppSection {
    case main, flashcards, stats
}

struct ContentView: View {
    @EnvironmentObject var topicManager: TopicManager
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var currentSection: AppSection = .main
    @State private var showSidebar = false
    
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
                case .stats:
                    if firebaseManager.isAuthenticated {
                        StatsSectionView()
                    } else {
                        AuthenticationRequiredView()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentSection)
            
            // Floating navigation bar at bottom (only when not in flashcard view)
            if topicManager.currentTopic == nil {
                VStack {
                    Spacer()
                    floatingNavBar()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Sidebar overlay
            if showSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSidebar = false
                        }
                    }
                
                SidebarView(isShowing: $showSidebar)
                .transition(.move(edge: .leading))
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
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSection = .main
                }
            }
        }
    }
    
    private func floatingNavBar() -> some View {
        HStack(spacing: 0) {
            // Menu button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSidebar = true
                }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Menu")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            
            // Main/Learn button
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
            
            // Stats button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSection = .stats
                    topicManager.currentTopic = nil
                }
            }) {
                VStack(spacing: 6) {
                    ZStack {
                        Image(systemName: currentSection == .stats ? "chart.bar.fill" : "chart.bar")
                            .font(.title3)
                            .foregroundColor(currentSection == .stats ? .blue : .white)
                        
                        // Notification badge for achievements or streaks
                        if let user = firebaseManager.currentUser,
                           user.currentStreak > 0 || !user.dailyStats.isEmpty {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                    
                    Text("Stats")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(currentSection == .stats ? .blue : .white.opacity(0.8))
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
