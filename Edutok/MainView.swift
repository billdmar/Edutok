import SwiftUI

struct MainView: View {
    @EnvironmentObject var topicManager: TopicManager
    @EnvironmentObject var gamificationManager: GamificationManager
    @State private var topicInput = ""
    @State private var isLoading = false
    @State private var showSidebar = false
    @State private var searchSuggestions: [String] = []
    @State private var showSuggestions = false
    @FocusState private var isSearchFocused: Bool
    
    // Enhanced topic suggestions with better variety
    private let popularTopics = [
        "Betta Fish Care", "Python Programming", "World War 2", "Photosynthesis",
        "Machine Learning", "Spanish Verbs", "Ancient Rome", "Quantum Physics",
        "Shakespeare", "Cell Biology", "Jazz Music", "Renaissance Art",
        "Climate Change", "Cryptocurrency", "Greek Mythology", "Space Exploration"
    ]
    
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
                    
                    // Enhanced input section
                    VStack(spacing: 20) {
                        VStack(spacing: 0) {
                            // Search field
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 18))
                                
                                TextField("What do you want to learn today?", text: $topicInput)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .focused($isSearchFocused)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        startLearning()
                                    }
                                    .onChange(of: topicInput) { newValue in
                                        updateSearchSuggestions(for: newValue)
                                    }
                                    .onChange(of: isSearchFocused) { focused in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showSuggestions = focused && !topicInput.isEmpty
                                        }
                                    }
                                
                                if !topicInput.isEmpty {
                                    Button(action: {
                                        topicInput = ""
                                        showSuggestions = false
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.white.opacity(isSearchFocused ? 0.4 : 0.2), lineWidth: isSearchFocused ? 2 : 1)
                                    )
                            )
                            
                            // Search suggestions dropdown
                            if showSuggestions && !searchSuggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(searchSuggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            topicInput = suggestion
                                            showSuggestions = false
                                            isSearchFocused = false
                                        }) {
                                            HStack {
                                                Image(systemName: "magnifyingglass")
                                                    .foregroundColor(.white.opacity(0.5))
                                                    .font(.caption)
                                                
                                                Text(suggestion)
                                                    .foregroundColor(.white.opacity(0.9))
                                                    .font(.body)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "arrow.up.left")
                                                    .foregroundColor(.white.opacity(0.3))
                                                    .font(.caption)
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                        }
                                        .background(Color.white.opacity(0.05))
                                        
                                        if suggestion != searchSuggestions.last {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                                .padding(.top, 5)
                                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                            }
                        }
                        
                        // Start learning button
                        Button(action: startLearning) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.headline)
                                }
                                
                                Text(isLoading ? "Creating Your Cards..." : "Start Learning")
                                    .fontWeight(.semibold)
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 35)
                            .padding(.vertical, 18)
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
                        .opacity(topicInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Enhanced popular topics section
                    if !showSuggestions {
                        VStack(spacing: 15) {
                            HStack {
                                Text("🔥 Trending Topics")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 30)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(popularTopics.shuffled().prefix(8), id: \.self) { suggestion in
                                        Button(action: {
                                            topicInput = suggestion
                                        }) {
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(Color.white.opacity(0.1))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 20)
                                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                        )
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 30)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    Spacer()
                }
                
                // Sidebar button and XP display - moved to very top
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
                        .padding(.top, 5) // Minimal top padding
                        
                        Spacer()
                        
                        // XP and Level Display on main view with beautiful rectangle
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Level \(gamificationManager.userProgress.currentLevel)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                                
                                Text("\(gamificationManager.userProgress.totalXP) XP")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            ZStack {
                                ProgressRing(
                                    progress: gamificationManager.userProgress.levelProgress,
                                    lineWidth: 3,
                                    size: 30
                                )
                                
                                Text("\(gamificationManager.userProgress.currentLevel)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.purple.opacity(0.3),
                                            Color.blue.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.yellow.opacity(0.4),
                                                    Color.purple.opacity(0.3)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 5, x: 0, y: 2)
                        .padding(.trailing, 20)
                        .padding(.top, 5)
                    }
                    Spacer()
                }
                
                // Sidebar overlay
                                if showSidebar {
                                    HStack(spacing: 0) {
                                        SidebarView(isShowing: $showSidebar)
                                            .frame(width: 280)
                                            .transition(.move(edge: .leading))
                                        
                                        // Transparent overlay area - shows main view with slight dimming
                                        Color.black.opacity(0.7)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    showSidebar = false
                                                }
                                            }
                                    }
                                    .zIndex(1000)
                                }
            }
        }
        .onTapGesture {
            if showSuggestions {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSuggestions = false
                    isSearchFocused = false
                }
            }
        }
    }
    
    private func updateSearchSuggestions(for input: String) {
        guard !input.isEmpty else {
            searchSuggestions = []
            showSuggestions = false
            return
        }
        
        let filtered = popularTopics.filter { topic in
            topic.localizedCaseInsensitiveContains(input)
        }
        
        searchSuggestions = Array(filtered.prefix(5))
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showSuggestions = !filtered.isEmpty && isSearchFocused
        }
    }
    
    private func startLearning() {
        let topic = topicInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !topic.isEmpty, !isLoading else { return }
        
        // Hide suggestions and unfocus
        withAnimation(.easeInOut(duration: 0.2)) {
            showSuggestions = false
            isSearchFocused = false
        }
        
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
