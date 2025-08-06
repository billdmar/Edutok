import SwiftUI

@main
struct FlashTokApp: App {
    @StateObject private var topicManager = TopicManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(topicManager)
                .preferredColorScheme(.dark)
        }
    }
}
