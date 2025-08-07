import SwiftUI

@main
struct FlashTokApp: App {
    @StateObject private var topicManager = TopicManager()
    @StateObject private var gamificationManager = GamificationManager()
    @StateObject private var imageManager = ImageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(topicManager)
                .environmentObject(gamificationManager)
                .environmentObject(imageManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Schedule initial study reminders
                    gamificationManager.scheduleStudyReminder()
                }
        }
    }
}
