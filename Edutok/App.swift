import SwiftUI

@main
struct EdutokApp: App {
    @StateObject private var topicManager = TopicManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(topicManager)
                .preferredColorScheme(.dark)
        }
    }
}
