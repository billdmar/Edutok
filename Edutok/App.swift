// App.swift
import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct EdutokApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var topicManager = TopicManager()
    @State private var gamificationManager = GamificationManager()
    // Computed (not stored) so the singleton isn't created during App.init() —
    // FirebaseManager's Firestore/Auth members require FirebaseApp.configure(),
    // which the AppDelegate runs after this struct is initialized.
    private var firebaseManager: FirebaseManager { .shared }
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(topicManager)
                .environment(gamificationManager)
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
        .onChange(of: scenePhase) { _, phase in
            // Returning to the app after midnight should roll over expired daily challenges.
            if phase == .active {
                gamificationManager.refreshDailyChallengesIfNeeded()
            }
        }
    }
}
