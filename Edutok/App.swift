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
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var topicManager = TopicManager()
    @StateObject private var gamificationManager = GamificationManager()
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(topicManager)
                .environmentObject(gamificationManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Schedule initial study reminders
                    gamificationManager.scheduleStudyReminder()
                    
                    // Auto-authenticate user if not already authenticated
                    if !firebaseManager.isAuthenticated {
                        Task {
                            try? await firebaseManager.signInAnonymously()
                        }
                    }
                }
        }
    }
}
