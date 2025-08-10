import SwiftUI

enum CardTransitionDirection {
    case none, fromTop, fromBottom
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .brightness(configuration.isPressed ? 0.2 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct HeartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FlashcardView: View {
    @EnvironmentObject var topicManager: TopicManager
    @EnvironmentObject var gamificationManager: GamificationManager
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var currentCardIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var showAnswer = false
    @State private var cardRotation: Double = 0
    @State private var showSidebar = false
    @State private var isTransitioning = false
    @State private var dotIndex = 2 // Start at middle dot (0-4 range)
    @State private var cardTransitionDirection: CardTransitionDirection = .none
    @State private var answerStartTime: Date?
    @State private var hasTrackedCardFlip = false
    @State private var cardXPAwarded: Set<UUID> = []
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
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
                
                if let topic = topicManager.currentTopic,
                   !topic.flashcards.isEmpty {
                    
                    VStack(spacing: 0) {
                        // Header
                        headerView(topic: topic, geometry: geometry)
                        
                        // Infinite scroll flashcard stack
                        ZStack {
                            ForEach(Array(infiniteCards.enumerated()), id: \.offset) { index, card in
                                let relativeIndex = index - 1 // Center card is at index 1
                                if abs(relativeIndex) <= 2 { // Show 3 cards: previous, current, next (and one more for smooth transition)
                                    flashcardContent(card: card, relativeIndex: relativeIndex, geometry: geometry)
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .clipped()
                        
                        // Action overlay buttons (floating)
                        actionOverlayButtons(geometry: geometry)
                    }
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("Creating your flashcards...")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.top)
                    }
                }
                
                // Sidebar overlay
                                if showSidebar {
                                    ZStack {
                                        // Full screen dimming overlay
                                        Color.black.opacity(0.3)
                                            .blur(radius: 2)
                                            .ignoresSafeArea()
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    showSidebar = false
                                                }
                                            }
                                        
                                        // Sidebar positioned on left
                                        HStack {
                                            SidebarView(isShowing: $showSidebar)
                                                .frame(width: 280)
                                                .transition(.move(edge: .leading))
                                            
                                            Spacer()
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .zIndex(1000)
                                }
                
                // XP Gain Animations
                ForEach(gamificationManager.recentXPGains) { xpEvent in
                    XPGainView(xpEvent: xpEvent)
                        .position(x: geometry.size.width - 100, y: 100)
                        .zIndex(100)
                }
                
                // Particle Effects
                ForEach(gamificationManager.particleEffects) { effect in
                    ParticleSystemView(effect: effect)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .zIndex(99)
                }
                
                // Level Up Overlay
                if gamificationManager.shouldShowLevelUp {
                    LevelUpView(
                        isShowing: $gamificationManager.shouldShowLevelUp,
                        level: gamificationManager.userProgress.currentLevel
                    )
                    .zIndex(1000)
                }
                
                // Achievement Overlay
                if gamificationManager.shouldShowAchievement,
                   let achievement = gamificationManager.newAchievement {
                    AchievementView(
                        isShowing: $gamificationManager.shouldShowAchievement,
                        achievement: achievement
                    )
                    .zIndex(1000)
                }
            }
        }
    }
    
    // Create infinite scrolling array
    private var infiniteCards: [Flashcard] {
        guard let topic = topicManager.currentTopic, !topic.flashcards.isEmpty else { return [] }
        
        let cards = topic.flashcards
        let totalCards = cards.count
        
        // Create array with previous, current, and next cards for smooth infinite scrolling
        var infiniteArray: [Flashcard] = []
        
        // Previous card
        let prevIndex = (currentCardIndex - 1 + totalCards) % totalCards
        infiniteArray.append(cards[prevIndex])
        
        // Current card
        infiniteArray.append(cards[currentCardIndex])
        
        // Next card
        let nextIndex = (currentCardIndex + 1) % totalCards
        infiniteArray.append(cards[nextIndex])
        
        // Card after next (for smoother transitions)
        let afterNextIndex = (currentCardIndex + 2) % totalCards
        infiniteArray.append(cards[afterNextIndex])
        
        return infiniteArray
    }
    
    private func headerView(topic: Topic, geometry: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            HStack {
                // Menu button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSidebar = true
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44) // Fixed square button
                
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 5)
            
            // Centered topic title and dots - now in separate layer
            VStack(spacing: 8) {
                Text(topic.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Cycling dot indicator
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(index == dotIndex ? 1.0 : 0.3))
                            .frame(width: index == dotIndex ? 8 : 6, height: index == dotIndex ? 8 : 6)
                            .scaleEffect(index == dotIndex ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: dotIndex)
                    }
                }
            }
            .frame(maxWidth: .infinity) // This ensures full width centering
        }
        .padding(.bottom, 15)
    }
    private func enhancedHeaderView(topic: Topic, geometry: GeometryProxy) -> some View {
            VStack(spacing: 10) {
                HStack {
                    // Menu button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSidebar = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    // Enhanced XP and Level Display with multipliers
                    VStack(spacing: 8) {
                        // Current XP and Level
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
                        
                        // Active Multipliers Display
                        HStack(spacing: 6) {
                            if gamificationManager.userProgress.comboXPMultiplier > 1.0 {
                                Text("🔥×\(String(format: "%.1f", gamificationManager.userProgress.comboXPMultiplier))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.orange.opacity(0.2))
                                    )
                            }
                            
                            if gamificationManager.userProgress.dailyXPMultiplier > 1.0 {
                                Text("📅×\(String(format: "%.1f", gamificationManager.userProgress.dailyXPMultiplier))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.blue.opacity(0.2))
                                    )
                            }
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 5)
                
                // Centered topic title and dots
                VStack(spacing: 8) {
                    Text(topic.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    // Cycling dot indicator
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(index == dotIndex ? 1.0 : 0.3))
                                .frame(width: index == dotIndex ? 8 : 6, height: index == dotIndex ? 8 : 6)
                                .scaleEffect(index == dotIndex ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: dotIndex)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 15)
        }
    private func flashcardContent(card: Flashcard, relativeIndex: Int, geometry: GeometryProxy) -> some View {
        let isCurrentCard = relativeIndex == 0
        let cardOffset = CGFloat(relativeIndex)
        
        // ⚠️ OPACITY CONTROL SECTION - ADJUST HERE TO CHANGE BACKGROUND CARD VISIBILITY ⚠️
        let cardOpacity = isCurrentCard ? 1.0 : max(0.3 - (abs(cardOffset) * 0.15), 0.1)
        
        // TikTok-style transition offsets
        let transitionOffset: CGFloat = {
            switch cardTransitionDirection {
            case .fromTop:
                return isCurrentCard ? 0 : (relativeIndex > 0 ? -geometry.size.height : geometry.size.height)
            case .fromBottom:
                return isCurrentCard ? 0 : (relativeIndex > 0 ? geometry.size.height : -geometry.size.height)
            case .none:
                return 0
            }
        }()
        
        return ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.8),
                            Color.blue.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(isCurrentCard ? 0.4 : 0.2),
                    radius: isCurrentCard ? 20 : 10,
                    x: 0,
                    y: isCurrentCard ? 15 : 5
                )
            
        
            VStack(spacing: 30) {
                // Card type indicator
                HStack {
                    Image(systemName: cardTypeIcon(for: card.type, showAnswer: showAnswer && isCurrentCard))
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text(showAnswer && isCurrentCard ? "Answer" : card.type.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    if card.isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 25)
                .rotation3DEffect(
                    .degrees(isCurrentCard && showAnswer ? -cardRotation : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                
               
                
                
                // Card content with boundary-based auto-sizing
                                VStack(spacing: 15) {
                                    
                                                        AutoSizedText(
                                                            text: card.question,
                                                            maxWidth: geometry.size.width - 100, // More conservative padding
                                                            maxHeight: card.imageURL != nil && !showAnswer ? 100 : 180, // More conservative height
                                                            fontWeight: .bold,
                                                            color: .white
                                                        )
                                    
                                    // Image display (now at bottom, only on question side)
                                    if !showAnswer && isCurrentCard && card.imageURL != nil {
                                        AsyncImageLoader(url: card.imageURL)
                                            .frame(height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                            .transition(.opacity.combined(with: .scale))
                                    }
                                    
                                    if showAnswer && isCurrentCard {
                                        Divider()
                                            .background(Color.white.opacity(0.3))
                                            .padding(.horizontal, 10)
                                        
                                      
                                        
                                                                AutoSizedText(
                                                                    text: card.answer,
                                                                    maxWidth: geometry.size.width - 100, // More conservative padding
                                                                    maxHeight: 130, // More conservative answer area height
                                                                    fontWeight: .medium,
                                                                    color: .white.opacity(0.9)
                                                                )
                                        .transition(.opacity.combined(with: .scale))
                                    }
                                }
                .padding(.horizontal, 25)
                .rotation3DEffect(
                    .degrees(isCurrentCard && showAnswer ? -cardRotation : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                
                Spacer()
                
                // Tap to reveal hint
                if !showAnswer && isCurrentCard {
                    VStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                                                    .font(.title3)
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .symbolEffect(.pulse, options: .repeat(.continuous).speed(0.8))
                                                    .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 0)
                        
                        Text("Tap to reveal answer")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 25)
                    .rotation3DEffect(
                        .degrees(isCurrentCard && showAnswer ? -cardRotation : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                } else if isCurrentCard {
                    // Swipe hint and action buttons when answer is showing
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Image(systemName: "arrow.up")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.4))
                                .scaleEffect(1.2)
                            
                            Text("Swipe up for next card")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .rotation3DEffect(
                            .degrees(isCurrentCard && showAnswer ? -cardRotation : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showAnswer)
                        
                        // Action buttons on card
                        HStack(spacing: 30) {
                            // Skip button with enhanced animations
                            Button(action: {
                                                            // Reset combo on skip
                                                            gamificationManager.userProgress.resetCombo()
                                                            gamificationManager.showComboDisplay = false
                                                            
                                                            nextCard()
                                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                            impactFeedback.impactOccurred()
                                                        }) {
                                                            VStack(spacing: 6) {
                                                                                                Image(systemName: "arrow.right.circle.fill")
                                                                                                    .font(.title2)
                                                                                                    .foregroundColor(.white)
                                                                                                    .symbolEffect(.bounce, options: .repeat(.continuous).speed(0.5))
                                                                                                
                                                                                                Text("Skip")
                                                                                                    .font(.caption)
                                                                                                    .fontWeight(.semibold)
                                                                                                    .foregroundColor(.white.opacity(0.8))
                                                                                            }
                                                                                            .padding(.horizontal, 20)
                                                                                            .padding(.vertical, 12)
                                                                                            .background(
                                                                                                RoundedRectangle(cornerRadius: 20)
                                                                                                    .fill(
                                                                                                        LinearGradient(
                                                                                                            gradient: Gradient(colors: [Color.orange, Color.red.opacity(0.8)]),
                                                                                                            startPoint: .topLeading,
                                                                                                            endPoint: .bottomTrailing
                                                                                                        )
                                                                                                    )
                                                                                                    .overlay(
                                                                                                        RoundedRectangle(cornerRadius: 20)
                                                                                                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                                                                                    )
                                                                                                    .shadow(color: .orange.opacity(0.5), radius: 8, x: 0, y: 4)
                                                                                            )
                            }
                            .scaleEffect(isCurrentCard ? 1.0 : 0.8)
                            .buttonStyle(BouncyButtonStyle())
                            .rotation3DEffect(
                                .degrees(isCurrentCard && showAnswer ? -cardRotation : 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            
                            // Got it button
                            Button(action: {
                                                            // Enhanced XP and combo tracking
                                                            let timeToAnswer = answerStartTime?.timeIntervalSinceNow ?? 0
                                                            gamificationManager.awardXPForCardCompletion(
                                                                wasCorrect: true,
                                                                isFirstTry: true,
                                                                timeToAnswer: abs(timeToAnswer)
                                                            )
                                                            
                                                            markAsUnderstood()
                                                            nextCard()
                                                            
                                                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                                            impactFeedback.impactOccurred()
                                                        }) {
                                                            VStack(spacing: 6) {
                                                                                                HStack(spacing: 4) {
                                                                                                    Image(systemName: "checkmark.circle.fill")
                                                                                                        .font(.title2)
                                                                                                        .foregroundColor(.white)
                                                                                                        .symbolEffect(.pulse, options: .repeat(.continuous).speed(0.7))
                                                                                                    
                                                                                                    if gamificationManager.userProgress.currentCombo > 2 {
                                                                                                        Text("\(gamificationManager.userProgress.currentCombo)x")
                                                                                                            .font(.caption)
                                                                                                            .fontWeight(.bold)
                                                                                                            .foregroundColor(.orange)
                                                                                                    }
                                                                                                }
                                                                                                
                                                                                                Text("Got it")
                                                                                                    .font(.caption)
                                                                                                    .fontWeight(.semibold)
                                                                                                    .foregroundColor(.white.opacity(0.8))
                                                                                            }
                                                                .padding(.horizontal, 20)
                                                                .padding(.vertical, 12)
                                                                .background(
                                                                    RoundedRectangle(cornerRadius: 20)
                                                                        .fill(
                                                                            LinearGradient(
                                                                                gradient: Gradient(colors: [Color.green, Color.mint]),
                                                                                startPoint: .topLeading,
                                                                                endPoint: .bottomTrailing
                                                                            )
                                                                        )
                                                                        .overlay(
                                                                            RoundedRectangle(cornerRadius: 20)
                                                                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                                                        )
                                                                        .shadow(
                                                                                                                    color: gamificationManager.userProgress.currentCombo > 2 ?
                                                                                                                        .orange.opacity(0.5) : .green.opacity(0.5),
                                                                                                                    radius: 8, x: 0, y: 4
                                                                                                                )
                            }
                            .scaleEffect(isCurrentCard ? 1.0 : 0.8)
                            .buttonStyle(BouncyButtonStyle())
                            .rotation3DEffect(
                                .degrees(isCurrentCard && showAnswer ? -cardRotation : 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                        }
                        .padding(.horizontal, 25)
                    }
                    .padding(.bottom, 25)
                }
            }
        }
        .frame(width: geometry.size.width - 40, height: geometry.size.height * 0.75)
        .scaleEffect(isCurrentCard ? 1.0 : max(0.85 - (abs(cardOffset) * 0.1), 0.6))
        .offset(
            x: isCurrentCard ? dragOffset.width * 0.3 : 0,
            y: isCurrentCard ? dragOffset.height : (cardOffset * geometry.size.height * 0.1) + transitionOffset
        )
        .rotation3DEffect(
            .degrees(isCurrentCard ? cardRotation : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .opacity(cardOpacity)
        .zIndex(isCurrentCard ? 10 : Double(10 - abs(relativeIndex)))
        .onTapGesture {
            if isCurrentCard {
                if !showAnswer {
                    // Record answer start time
                    answerStartTime = Date()
                    
                    // Track card flip in Firebase if not already tracked
                    if !hasTrackedCardFlip {
                        Task {
                            await firebaseManager.trackCardFlipped()
                        }
                        hasTrackedCardFlip = true
                    }
                }
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showAnswer.toggle()
                    cardRotation = showAnswer ? 180 : 0
                }
                
                
                // Enhanced XP and combo tracking
                                if showAnswer && !cardXPAwarded.contains(card.id) {
                                    cardXPAwarded.insert(card.id)
                                    let timeToAnswer = answerStartTime?.timeIntervalSinceNow ?? 0
                                    
                                    gamificationManager.awardXPForCardCompletion(
                                        wasCorrect: true, // Assume correct for tap to reveal
                                        isFirstTry: true,
                                        timeToAnswer: abs(timeToAnswer)
                                    )
                                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .gesture(
            isCurrentCard ?
            DragGesture()
                .onChanged { gesture in
                    dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    let swipeThreshold: CGFloat = 50
                    let velocityThreshold: CGFloat = 500
                    
                    // Vertical swipe detection (infinite scroll)
                    if gesture.translation.height < -swipeThreshold || gesture.predictedEndTranslation.height < -velocityThreshold {
                        // Swipe up - next card
                        nextCard()
                        let snapFeedback = UIImpactFeedbackGenerator(style: .medium)
                        snapFeedback.impactOccurred()
                    } else if gesture.translation.height > swipeThreshold || gesture.predictedEndTranslation.height > velocityThreshold {
                        // Swipe down - previous card
                        previousCard()
                        let snapFeedback = UIImpactFeedbackGenerator(style: .medium)
                        snapFeedback.impactOccurred()
                    } else if gesture.translation.width > swipeThreshold * 2 {
                        // Swipe right - mark as understood
                        markAsUnderstood()
                        nextCard()
                        let snapFeedback = UIImpactFeedbackGenerator(style: .medium)
                        snapFeedback.impactOccurred()
                    } else if gesture.translation.width < -swipeThreshold * 2 {
                        // Swipe left - bookmark
                        toggleBookmark()
                        
                        // Return to center with bounce
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            dragOffset = CGSize.zero
                        }
                        let snapFeedback = UIImpactFeedbackGenerator(style: .medium)
                        snapFeedback.impactOccurred()
                    } else {
                        // Return to center
                        withAnimation(.spring()) {
                            dragOffset = CGSize.zero
                        }
                    }
                }
            : nil
        )
    }
    
    private func actionOverlayButtons(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            HStack {
                // Back button at bottom left
                Button(action: {
                    topicManager.currentTopic = nil
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Back")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(BouncyButtonStyle())
                .frame(width: 120) // Fixed width
                
                Spacer()
                
                // Like button at bottom center - perfectly centered
                Button(action: {
                    if let topic = topicManager.currentTopic {
                        topicManager.toggleTopicLike(topicId: topic.id)
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: topicManager.currentTopic?.isLiked == true ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(topicManager.currentTopic?.isLiked == true ? .red : .white)
                            .scaleEffect(topicManager.currentTopic?.isLiked == true ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: topicManager.currentTopic?.isLiked)
                        
                        Text(topicManager.currentTopic?.isLiked == true ? "Liked" : "Like")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(topicManager.currentTopic?.isLiked == true ? .red : .white.opacity(0.8))
                            .animation(.easeInOut(duration: 0.2), value: topicManager.currentTopic?.isLiked)
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(topicManager.currentTopic?.isLiked == true ? Color.red.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(HeartButtonStyle())
                
                Spacer()
                
                // Invisible spacer to balance the layout
                Color.clear
                    .frame(width: 120, height: 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 5))
        }
    }
    
    private var currentCard: Flashcard? {
        guard let topic = topicManager.currentTopic,
              currentCardIndex < topic.flashcards.count else { return nil }
        return topic.flashcards[currentCardIndex]
    }
    
    private func cardTypeIcon(for type: FlashcardType, showAnswer: Bool) -> String {
        if showAnswer {
            return "lightbulb.fill"
        }
        
        switch type {
        case .definition: return "book.fill"
        case .question: return "questionmark.circle.fill"
        case .truefalse: return "checkmark.circle.fill"
        case .fillblank: return "pencil.circle.fill"
        }
    }
    
    private func nextCard() {
        guard let topic = topicManager.currentTopic else { return }
        
        // Set transition direction from top
        cardTransitionDirection = .fromTop
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showAnswer = false
            cardRotation = 0
            dragOffset = CGSize.zero
            
            // Cycle dot to the left (next position)
            dotIndex = (dotIndex + 1) % 5
            
            // Infinite scroll - wrap around to beginning
            currentCardIndex = (currentCardIndex + 1) % topic.flashcards.count
            hasTrackedCardFlip = false

            // Generate more facts when approaching the end
            if currentCardIndex >= topic.flashcards.count - 5 {
                Task {
                    await topicManager.generateMoreFacts(for: topic)
                }
            }
        }
        
        // Reset transition direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardTransitionDirection = .none
        }
    }
    
    private func previousCard() {
        guard let topic = topicManager.currentTopic else { return }
        
        // Set transition direction from bottom
        cardTransitionDirection = .fromBottom
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showAnswer = false
            cardRotation = 0
            dragOffset = CGSize.zero
            
            // Cycle dot to the right (previous position)
            dotIndex = (dotIndex - 1 + 5) % 5
            
            // Infinite scroll - wrap around to end
            currentCardIndex = (currentCardIndex - 1 + topic.flashcards.count) % topic.flashcards.count
            hasTrackedCardFlip = false

        }
        
        // Reset transition direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardTransitionDirection = .none
        }
    }
    
    private func markAsUnderstood() {
        guard let topic = topicManager.currentTopic else { return }
        topicManager.markCardAsUnderstood(topicId: topic.id, cardIndex: currentCardIndex)
        
        // Award XP for understanding the card
        gamificationManager.awardXP(.perfectCard)
    }
    
    private func toggleBookmark() {
        guard let topic = topicManager.currentTopic else { return }
        topicManager.toggleBookmark(topicId: topic.id, cardIndex: currentCardIndex)
    }
    // Improved AutoSizedText component with precise boundary fitting
    struct AutoSizedText: View {
        let text: String
        let maxWidth: CGFloat
        let maxHeight: CGFloat
        let fontWeight: Font.Weight
        let color: Color
        
        @State private var fontSize: CGFloat = 20
        
        var body: some View {
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: maxWidth)
                .onAppear {
                    calculateOptimalFontSize()
                }
                .onChange(of: text) { _ in
                    calculateOptimalFontSize()
                }
        }
        // MARK: - Combo Display Component
        struct ComboDisplay: View {
            let combo: Int
            let multiplier: Double
            
            var body: some View {
                HStack(spacing: 10) {
                    Text("🔥")
                        .font(.title2)
                        .scaleEffect(1.2)
                    
                    VStack(spacing: 2) {
                        Text("\(combo) Combo!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("×\(String(format: "%.1f", multiplier)) XP")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(
                                                            LinearGradient(
                                                                gradient: Gradient(colors:
                                                                    gamificationManager.userProgress.currentCombo > 2 ?
                                                                        [Color.green, Color.mint, Color.orange] :
                                                                        [Color.green, Color.mint]
                                                                ),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                )
                .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
            }
        }
        private func calculateOptimalFontSize() {
            let maxFontSize: CGFloat = 32
            let minFontSize: CGFloat = 8
            var bestSize: CGFloat = minFontSize
            
            // Binary search for the optimal font size
            var low: CGFloat = minFontSize
            var high: CGFloat = maxFontSize
            
            while high - low > 0.5 {
                let mid = (low + high) / 2
                let textSize = measureText(fontSize: mid)
                
                if textSize.width <= maxWidth && textSize.height <= maxHeight {
                    bestSize = mid
                    low = mid
                } else {
                    high = mid - 0.5
                }
            }
            
            // Final verification and adjustment
            var finalSize = bestSize
            while finalSize > minFontSize {
                let testSize = measureText(fontSize: finalSize)
                if testSize.width <= maxWidth && testSize.height <= maxHeight {
                    break
                }
                finalSize -= 0.5
            }
            
            fontSize = max(finalSize, minFontSize)
        }
        
        private func measureText(fontSize: CGFloat) -> CGSize {
            let font = UIFont.systemFont(ofSize: fontSize, weight: uiFontWeight(from: fontWeight))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
            
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            
            // Use a slightly smaller width for measurement to account for padding
            let constraintWidth = maxWidth - 4
            let constraintSize = CGSize(width: constraintWidth, height: CGFloat.greatestFiniteMagnitude)
            
            let boundingRect = attributedString.boundingRect(
                with: constraintSize,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            
            // Add small buffer to ensure no truncation
            return CGSize(
                width: ceil(boundingRect.width) + 2,
                height: ceil(boundingRect.height) + 2
            )
        }
        
        private func uiFontWeight(from fontWeight: Font.Weight) -> UIFont.Weight {
            switch fontWeight {
            case .ultraLight: return .ultraLight
            case .thin: return .thin
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            case .black: return .black
            default: return .regular
            }
        }
    }
}
