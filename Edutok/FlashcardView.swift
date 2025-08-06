import SwiftUI

enum CardTransitionDirection {
    case none, fromTop, fromBottom
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
    @State private var currentCardIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var showAnswer = false
    @State private var cardRotation: Double = 0
    @State private var showSidebar = false
    @State private var isTransitioning = false
    @State private var dotIndex = 2 // Start at middle dot (0-4 range)
    @State private var cardTransitionDirection: CardTransitionDirection = .none
    
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
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSidebar = true
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Centered topic title and cycling dots
                VStack(spacing: 8) {
                    Text(topic.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    // Cycling dot indicator (like TikTok)
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
                
                Spacer()
                
                Button(action: {
                    topicManager.currentTopic = nil
                }) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .padding(.bottom, 20)
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
                    Image(systemName: cardTypeIcon(for: card.type))
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text(card.type.rawValue.capitalized)
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
                
                // Card content
                VStack(spacing: 25) {
                    Text(card.question)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    
                    if showAnswer && isCurrentCard {
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        Text(card.answer)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
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
                            .foregroundColor(.white.opacity(0.6))
                        
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
                            // Skip button
                            Button(action: {
                                nextCard()
                                
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Skip")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.orange.opacity(0.7))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
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
                                markAsUnderstood()
                                nextCard()
                                
                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                impactFeedback.impactOccurred()
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Got it")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.green.opacity(0.7))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showAnswer.toggle()
                    cardRotation = showAnswer ? 180 : 0
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
            
            // Like button at bottom center (replacing save button)
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
            .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 5))
        }
    }
    
    private var currentCard: Flashcard? {
        guard let topic = topicManager.currentTopic,
              currentCardIndex < topic.flashcards.count else { return nil }
        return topic.flashcards[currentCardIndex]
    }
    
    private func cardTypeIcon(for type: FlashcardType) -> String {
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
        }
        
        // Reset transition direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardTransitionDirection = .none
        }
    }
    
    private func markAsUnderstood() {
        guard let topic = topicManager.currentTopic else { return }
        topicManager.markCardAsUnderstood(topicId: topic.id, cardIndex: currentCardIndex)
    }
    
    private func toggleBookmark() {
        guard let topic = topicManager.currentTopic else { return }
        topicManager.toggleBookmark(topicId: topic.id, cardIndex: currentCardIndex)
    }
}
