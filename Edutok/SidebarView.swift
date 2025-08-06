import SwiftUI

struct SidebarView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var topicManager: TopicManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("FlashTok")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your Learning Journey")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
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
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // Topics list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(topicManager.savedTopics) { topic in
                            TopicRowView(topic: topic) {
                                topicManager.currentTopic = topic
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }
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
            }
            .frame(width: 300)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.95),
                        Color.purple.opacity(0.3),
                        Color.black.opacity(0.95)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
            
            Spacer()
        }
    }
}

struct TopicRowView: View {
    let topic: Topic
    let onTap: () -> Void
    
    var body: some View {
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
                        
                        Text("\(topic.flashcards.count) cards")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(topic.progressPercentage)%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
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
    }
}
