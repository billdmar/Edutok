import SwiftUI

struct ContentView: View {
    @EnvironmentObject var topicManager: TopicManager
    @State private var showSidebar = false
    
    var body: some View {
        ZStack {
            // Main content
            if topicManager.currentTopic != nil {
                FlashcardView()
            } else {
                MainView()
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
        }
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
