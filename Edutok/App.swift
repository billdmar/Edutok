// App.swift
import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FlashTokApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var topicManager = TopicManager()
    @StateObject private var gamificationManager = GamificationManager()
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var soundManager = SoundEffectsManager.shared        // NEW
    @StateObject private var hapticManager = HapticFeedbackManager.shared     // NEW
    @StateObject private var challengesManager = DailyChallengesManager.shared // NEW
    @StateObject private var streakManager = StreakProtectionManager.shared   // NEW
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(topicManager)
                .environmentObject(gamificationManager)
                .environmentObject(soundManager)        // NEW
                .environmentObject(hapticManager)       // NEW
                .environmentObject(challengesManager)   // NEW
                .environmentObject(streakManager)       // NEW
                .preferredColorScheme(.dark)
                .onAppear {
                    setupInitialState()
                }
        }
    }
    
    private func setupInitialState() {
        gamificationManager.scheduleStudyReminder()
        challengesManager.checkForNewDay()  // NEW
        
        if !firebaseManager.isAuthenticated {
            Task {
                try? await firebaseManager.signInAnonymously()
            }
        }
    }
}
