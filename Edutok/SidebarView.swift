import SwiftUI

struct SidebarView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var topicManager: TopicManager
    @EnvironmentObject var gamificationManager: GamificationManager
    @StateObject private var challengesManager = DailyChallengesManager()
    
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
                
                // Topics list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Section header
                        HStack {
                            Text("Recent Topics")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(topicManager.savedTopics.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        
                        if topicManager.savedTopics.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                VStack(spacing: 8) {
                                    Text("No topics yet!")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Start learning to see your topics here")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.vertical, 30)
                            .padding(.horizontal, 20)
                        } else {
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
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Footer with actions
                VStack(spacing: 15) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    // Daily Challenges Button
                                        NavigationLink(destination: DailyChallengesView()) {
                                            HStack {
                                                Text("🎯")
                                                    .font(.title3)
                                                Text("Daily Challenges")
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                Spacer()
                                                // Show completion badge
                                                if challengesManager.completionPercentage > 0 {
                                                    Text("\(Int(challengesManager.completionPercentage * 100))%")
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(15)
                                        }
                                        .padding(.horizontal, 20)
                                        
                                        // Achievement Gallery Button
                                        NavigationLink(destination: AchievementGalleryView()) {
                                            HStack {
                                                Text("🏆")
                                                    .font(.title3)
                                                Text("Achievements")
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                Spacer()
                                                // Show achievement count
                                                Text("\(gamificationManager.userProgress.achievementsUnlocked.count)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.yellow)
                                            }
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(15)
                                        }
                                        .padding(.horizontal, 20)
                    // Create new topic button
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
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Debug tools button (always visible, not just debug builds)
                    Button(action: {
                        showDebugView = true
                    }) {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                            
                            Text("Debug Tools")
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Version info
                    VStack(spacing: 5) {
                        Text("FlashTok v1.0")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.5))
                        
                        if firebaseManager.isAuthenticated {
                            Text("Connected to Firebase")
                                .font(.caption2)
                                .foregroundColor(.green.opacity(0.7))
                        } else {
                            Text("Offline Mode")
                                .font(.caption2)
                                .foregroundColor(.yellow.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .frame(width: 280)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.999),
                        Color.purple.opacity(0.4),
                        Color.black.opacity(0.999)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.6))
                )
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showDebugView) {
            DebugView()
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
