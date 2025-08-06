import SwiftUI

struct MainView: View {
    @EnvironmentObject var topicManager: TopicManager
    @State private var topicInput = ""
    @State private var isLoading = false
    @State private var showSidebar = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.8),
                        Color.blue.opacity(0.6),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo and title
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.pink, Color.purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 5) {
                            Text("FlashTok")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Learn anything, TikTok style")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Input section
                    VStack(spacing: 20) {
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                TextField("What do you want to learn?", text: $topicInput)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        startLearning()
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Button(action: startLearning) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.headline)
                                }
                                
                                Text(isLoading ? "Creating Cards..." : "Start Learning")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.pink, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .pink.opacity(0.3), radius: 15, x: 0, y: 5)
                        }
                        .disabled(topicInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .scaleEffect(isLoading ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isLoading)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Quick suggestions
                    VStack(spacing: 15) {
                        Text("Popular topics")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(["Python Programming", "World War 2", "Photosynthesis", "Machine Learning", "Spanish Verbs"], id: \.self) { suggestion in
                                    Button(action: {
                                        topicInput = suggestion
                                    }) {
                                        Text(suggestion)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                    
                    Spacer()
                }
                
                // Sidebar button
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSidebar = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()
                    }
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
    
    private func startLearning() {
        let topic = topicInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !topic.isEmpty, !isLoading else { return }
        
        isLoading = true
        
        Task {
            await topicManager.generateFlashcards(for: topic)
            
            await MainActor.run {
                isLoading = false
                topicInput = ""
            }
        }
    }
}
