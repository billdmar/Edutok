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
        "Python Programming", "World War 2", "Photosynthesis",
        "Machine Learning", "Spanish Verbs", "Ancient Rome", "Quantum Physics",
        "Shakespeare", "Cell Biology", "Jazz Music", "Renaissance Art",
        "Climate Change", "Cryptocurrency", "Greek Mythology", "Space Exploration",
        "Human Anatomy", "French Cooking", "Stock Market", "Ancient Egypt",
        "Artificial Intelligence", "Guitar Basics", "Marine Biology", "Photography",
        "Meditation", "Economics", "Chess Strategy", "Japanese Culture",
        "Nutrition", "Interior Design", "Dinosaurs", "Psychology",
        "Solar System", "Digital Marketing", "Yoga", "History of Rock Music",
        "Wine Tasting", "Creative Writing", "Chemistry Basics", "Architecture",
        "Gardening", "Philosophy", "Astronomy", "Fitness Training",
        "Cooking Techniques", "Art History", "Computer Science", "Languages",
        "Music Theory", "Environmental Science", "Literature", "Mathematics"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Beautiful animated gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.7),
                        Color.blue.opacity(0.5),
                        Color.purple.opacity(0.3),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated background circles
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -100, y: -200)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: 100, y: 300)
                }
                
                VStack(spacing: 0) {
                    // Top bar with menu and XP
                    HStack {
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
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        
                        Spacer()
                        
                        // XP and Level Display
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
                                    size: 35
                                )
                                
                                Text("\(gamificationManager.userProgress.currentLevel)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.purple.opacity(0.4),
                                            Color.blue.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.yellow.opacity(0.5),
                                                    Color.purple.opacity(0.4)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            // Logo and title section with animation
                            VStack(spacing: 25) {
                                ZStack {
                                    // Glow effect
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    Color.purple.opacity(0.4),
                                                    Color.clear
                                                ]),
                                                center: .center,
                                                startRadius: 5,
                                                endRadius: 60
                                            )
                                        )
                                        .frame(width: 160, height: 160)
                                        .blur(radius: 10)
                                    
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.pink, Color.purple]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 110, height: 110)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.white.opacity(0.5), .clear],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2
                                                )
                                        )
                                    
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 55))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                                }
                                .shadow(color: .purple.opacity(0.5), radius: 25, x: 0, y: 10)
                                
                                VStack(spacing: 8) {
                                    Text("FlashTok")
                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.9)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                                    
                                    Text("Learn anything, TikTok style")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                            .padding(.top, 30)
                            .padding(.bottom, 20)
                            
                            // Enhanced search section
                            VStack(spacing: 20) {
                                VStack(spacing: 0) {
                                    // Search field with glass morphism
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.system(size: 20))
                                        
                                        TextField("What do you want to learn today?", text: $topicInput)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .foregroundColor(.white)
                                            .font(.system(size: 17, weight: .medium, design: .rounded))
                                            .focused($isSearchFocused)
                                            .submitLabel(.go)
                                            .onSubmit {
                                                startLearning()
                                            }
                                            .onChange(of: topicInput) { newValue in
                                                updateSearchSuggestions(for: newValue)
                                            }
                                        
                                        if !topicInput.isEmpty {
                                            Button(action: {
                                                topicInput = ""
                                                showSuggestions = false
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .font(.system(size: 18))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.white.opacity(0.15))
                                            .background(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [
                                                                Color.white.opacity(isSearchFocused ? 0.5 : 0.3),
                                                                Color.white.opacity(isSearchFocused ? 0.3 : 0.1)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: isSearchFocused ? 2 : 1
                                                    )
                                            )
                                    )
                                    .shadow(color: .purple.opacity(isSearchFocused ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
                                    
                                    // Search suggestions (keep as is)
                                    if showSuggestions && !searchSuggestions.isEmpty {
                                        // ... existing suggestions code ...
                                    }
                                }
                                
                                // Beautiful start learning button
                                Button(action: startLearning) {
                                    HStack(spacing: 12) {
                                        if isLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                        
                                        Text(isLoading ? "Creating Your Cards..." : "Start Learning")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 18)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.pink,
                                                Color.purple,
                                                Color.blue.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .pink.opacity(0.5), radius: 20, x: 0, y: 8)
                                }
                                .disabled(topicInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                                .scaleEffect(isLoading ? 0.95 : 1.0)
                                .opacity(topicInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                            }
                            .padding(.horizontal, 25)
                            
                            // Trending topics section - moved up
                            if !showSuggestions {
                                VStack(spacing: 18) {
                                    HStack {
                                        HStack(spacing: 8) {
                                            Text("🔥")
                                                .font(.title2)
                                            Text("Trending Topics")
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            // Refresh topics
                                        }) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    .padding(.horizontal, 25)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(popularTopics.shuffled().prefix(8), id: \.self) { suggestion in
                                                Button(action: {
                                                    topicInput = suggestion
                                                }) {
                                                    Text(suggestion)
                                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 20)
                                                        .padding(.vertical, 12)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 22)
                                                                .fill(
                                                                    LinearGradient(
                                                                        colors: [
                                                                            Color.white.opacity(0.2),
                                                                            Color.white.opacity(0.1)
                                                                        ],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    )
                                                                )
                                                                .overlay(
                                                                    RoundedRectangle(cornerRadius: 22)
                                                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                                                )
                                                        )
                                                        .shadow(color: .purple.opacity(0.2), radius: 5, x: 0, y: 3)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 25)
                                    }
                                }
                                .padding(.top, 10)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.bottom, 100) // Space for nav bar
                    }
                }
                
                // Sidebar overlay - same as ContentView
                if showSidebar {
                    ZStack {
                        // Full screen dimming overlay
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSidebar = false
                                }
                            }
                        
                        HStack(spacing: 0) {
                            SidebarView(isShowing: $showSidebar)
                                .frame(width: 280)
                                .transition(.move(edge: .leading))
                            
                            Spacer()
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
    
    // NEW: Computed property to check for active Phase 1 features
    private var hasActivePhase1Features: Bool {
        let hasUncompletedChallenges = gamificationManager.dailyChallenges.contains { !$0.isCompleted && !$0.isExpired }
        let hasUnopenedMysteryBoxes = gamificationManager.availableMysteryBoxes.contains { !$0.isOpened }
        return hasUncompletedChallenges || hasUnopenedMysteryBoxes
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
