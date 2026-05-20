// LeaderboardWrapper.swift
import SwiftUI

struct LeaderboardWrapper: View {
    @State private var showSidebar = false
    
    var body: some View {
        ZStack {
            // Leaderboard content (your existing view)
            LeaderboardView()
            
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
    }
}
