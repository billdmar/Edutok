/// SettingsView.swift
///
/// User-facing account management: edit username, view stats, sign out, and delete the
/// account. Sign-out previously lived only in the DEBUG-gated DebugView, so Release
/// builds had no way to manage the account — this view restores that to users.
import SwiftUI

struct SettingsView: View {
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @EnvironmentObject var gamificationManager: GamificationManager
    @Environment(\.dismiss) private var dismiss

    @State private var draftUsername = ""
    @State private var showDeleteConfirm = false
    @State private var isWorking = false

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                statsSection
                aboutSection
                dangerSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.screenBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear { draftUsername = firebaseManager.currentUser?.username ?? "" }
            .alert("Delete account?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    Task {
                        isWorking = true
                        await firebaseManager.deleteAccount()
                        isWorking = false
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes your profile, stats, and leaderboard entries. This cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var accountSection: some View {
        Section("Account") {
            HStack {
                TextField("Username", text: $draftUsername)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                Button("Save") {
                    Task { await firebaseManager.updateUsername(draftUsername) }
                }
                .disabled(draftUsername.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var statsSection: some View {
        Section("Your progress") {
            statRow("Level", "\(gamificationManager.userProgress.currentLevel)")
            statRow("Total XP", "\(gamificationManager.userProgress.totalXP)")
            statRow("Current streak", "\(firebaseManager.currentUser?.currentStreak ?? 0) days")
            statRow("Cards flipped", "\(firebaseManager.currentUser?.totalCardsFlipped ?? 0)")
            statRow("Topics explored", "\(firebaseManager.currentUser?.totalTopicsExplored ?? 0)")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            statRow("Version", appVersion)
            Link("Source & docs on GitHub", destination: URL(string: "https://github.com/billdmar/Edutok")!)
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                firebaseManager.signOut()
                dismiss()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Account", systemImage: "trash")
            }
        } footer: {
            Text("Edutok signs you in anonymously by default; sign out to start fresh.")
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(Theme.textSecondary)
        }
    }
}
