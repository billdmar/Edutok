import SwiftUI

struct SidebarView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var topicManager: TopicManager
    @EnvironmentObject var gamificationManager: GamificationManager
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showDebugView = false
    @State private var showCalendar = false  // Add this for calendar access
    @State private var showPhase1Dashboard = false // Add this for Phase 1 Dashboard
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Button(action: {
                            topicManager.currentTopic = nil
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                        }) {
                            VStack(alignment: .leading) {
                                Text("FlashTok")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Your Learning Journey")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // User stats summary (if authenticated)
                    if let user = firebaseManager.currentUser {
                        VStack(spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Welcome back!")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text(user.username)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("🔥 \(user.currentStreak)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    
                                    Text("streak")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            // Quick stats
                            HStack {
                                VStack {
                                    Text("\(user.totalCardsFlipped)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    
                                    Text("Cards")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack {
                                    Text("\(user.totalTopicsExplored)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    Text("Topics")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.05))
                            )
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // Quick Actions Section - ADD THIS
                VStack(spacing: 12) {
                    HStack {
                        Text("Quick Actions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Phase 1 Dashboard button
                    Button(action: {
                        showPhase1Dashboard = true
                    }) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Learning Dashboard")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("Daily challenges & rewards")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Calendar button
                    Button(action: {
                        showCalendar = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Learning Calendar")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                if let user = firebaseManager.currentUser {
                                    Text("🔥 \(user.currentStreak) day streak")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Topics list MOVED TO TOP
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Recent Topics")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(topicManager.savedTopics.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(topicManager.savedTopics) { topic in
                                TopicRowView(topic: topic, onTap: {
                                    topicManager.currentTopic = topic
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isShowing = false
                                    }
                                }, onDelete: {
                                    topicManager.deleteTopic(topic)
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 200) // Limit height to make room for quick actions
                }
                
                Spacer()
                
                // Quick Actions MOVED TO BOTTOM
                VStack(alignment: .leading, spacing: 15) {
                    Text("Quick Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            // Navigate to stats/leaderboard
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                VStack(alignment: .leading) {
                                    Text("Learning Dashboard")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text("Daily challenges & rewards")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                        }
                        
                        Button(action: {
                            // Navigate to calendar
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text("Learning Calendar")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text("🔥 14 day streak")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 15) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    Button(action: {
                        topicManager.currentTopic = nil
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.pink)
                            
                            Text("Learn Something New")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.95),
                            Color.purple.opacity(0.7),
                            Color.black.opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Rectangle()
                            .fill(.ultraThinMaterial.opacity(0.8))
                    )
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showDebugView) {
                DebugView()
            }
            .fullScreenCover(isPresented: $showCalendar) {
                StandaloneCalendarView(isShowing: $showCalendar)
            }
            .sheet(isPresented: $showPhase1Dashboard) {
                Phase1DashboardView(gamificationManager: gamificationManager)
            }
        }
    }
    
    struct TopicRowView: View {
        let topic: Topic
        let onTap: () -> Void
        let onDelete: () -> Void
        @State private var showDeleteAlert = false
        
        var body: some View {
            HStack {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(topic.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                HStack(spacing: 15) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "rectangle.stack.fill")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Text("\(topic.flashcards.count)")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    if topic.isLiked {
                                        HStack(spacing: 4) {
                                            Image(systemName: "heart.fill")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                            
                                            Text("Liked")
                                                .font(.caption2)
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 5) {
                                Text("\(topic.progressPercentage)%")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.pink, Color.purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(topic.progressPercentage) / 100, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(15)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Delete button
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .alert("Delete Topic", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete '\(topic.title)'? This action cannot be undone.")
            }
        }
    }
}
