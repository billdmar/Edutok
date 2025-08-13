// StandaloneCalendarView.swift
import SwiftUI

struct StandaloneCalendarView: View {
    @Binding var isShowing: Bool
    @State private var showSidebar = false
    
    var body: some View {
        ZStack {
            // Calendar content (your existing view)
            StreakCalendarView()
            
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
