// AuthenticationRequiredView.swift
import SwiftUI

struct AuthenticationRequiredView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showAuthenticationView = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 15) {
                Text("Join the Community!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Sign in to track your progress, compete on leaderboards, and see your learning streaks.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                showAuthenticationView = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.title3)
                    
                    Text("Sign In / Sign Up")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 5)
            }
            
            Text("No personal information required - completely anonymous!")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 40)
                .multilineTextAlignment(.center)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.purple.opacity(0.3),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showAuthenticationView) {
            AuthenticationView()
        }
    }
}
