// StandaloneCalendarView.swift
import SwiftUI

struct StandaloneCalendarView: View {
    @Binding var isShowing: Bool
    @State private var showSidebar = false
    
    var body: some View {
        ZStack {
            // Calendar content (your existing view)
            StreakCalendarView()
            
            // Floating menu button overlay (top-right only)
            VStack {
                HStack {
                    Spacer()
                    
                    // Menu button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSidebar = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
            }
            
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
