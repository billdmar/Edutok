import SwiftUI

@main
struct FlashTokApp: App {
    @StateObject private var topicManager = TopicManager()
    @StateObject private var gamificationManager = GamificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(topicManager)
                .environmentObject(gamificationManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Schedule initial study reminders
                    gamificationManager.scheduleStudyReminder()
                }
        }
    }
}
