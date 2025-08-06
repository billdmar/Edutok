import SwiftUI

struct FlashcardView: View {
    @EnvironmentObject var topicManager: TopicManager
    @State private var currentCardIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var showAnswer = false
    @State private var cardRotation: Double = 0
    @State private var showSidebar = false
    
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
                        
                        // Flashcard stack
                        ZStack {
                            ForEach(Array(topic.flashcards.enumerated()), id: \.offset) { index, card in
                                if index >= currentCardIndex && index < currentCardIndex + 3 {
                                    flashcardContent(card: card, index: index, geometry: geometry)
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        // Action buttons
                        actionButtons(geometry: geometry)
                    }
                } else {
                    // Loading or error state
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
                
                VStack(spacing: 5) {
                    Text(topic.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text("Card \(currentCardIndex + 1) of \(topic.flashcards.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    topicManager.currentTopic = nil
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Progress bar
            ProgressView(value: Double(currentCardIndex + 1), total: Double(topic.flashcards.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                .scaleEffect(y: 2)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    private func flashcardContent(card: Flashcard, index: Int, geometry: GeometryProxy) -> some View {
        let isCurrentCard = index == currentCardIndex
        let cardOffset = CGFloat(index - currentCardIndex)
        
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
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
            
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
                }
            }
        }
        .frame(width: geometry.size.width - 40, height: geometry.size.height * 0.7)
        .scaleEffect(isCurrentCard ? 1.0 : 0.95 - (cardOffset * 0.05))
        .offset(x: isCurrentCard ? dragOffset.width : 0, y: cardOffset * 10)
        .rotation3DEffect(
            .degrees(isCurrentCard ? cardRotation : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .opacity(isCurrentCard ? 1.0 : 0.7 - (cardOffset * 0.2))
        .zIndex(isCurrentCard ? 1 : 0)
        .onTapGesture {
            if isCurrentCard {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showAnswer.toggle()
                    cardRotation = showAnswer ? 180 : 0
                }
            }
        }
        .gesture(
            isCurrentCard ?
            DragGesture()
                .onChanged { gesture in
                    dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    let swipeThreshold: CGFloat = 100
                    
                    if gesture.translation.x > swipeThreshold {
                        markAsUnderstood()
                        nextCard()
                    } else if gesture.translation.x < -swipeThreshold {
                        nextCard()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = CGSize.zero
                        }
                    }
                }
            : nil
        )
    }
    
    private func actionButtons(geometry: GeometryProxy) -> some View {
        HStack(spacing: 30) {
            // Skip button
            Button(action: {
                nextCard()
            }) {
                VStack {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())
            }
            
            // Bookmark button
            Button(action: {
                toggleBookmark()
            }) {
                VStack {
                    Image(systemName: currentCard?.isBookmarked == true ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
            }
            
            // Understood button
            Button(action: {
                markAsUnderstood()
                nextCard()
            }) {
                VStack {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(Color.green.opacity(0.8))
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
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
        withAnimation(.easeInOut(duration: 0.3)) {
            showAnswer = false
            cardRotation = 0
            dragOffset = CGSize.zero
            
            if let topic = topicManager.currentTopic,
               currentCardIndex < topic.flashcards.count - 1 {
                currentCardIndex += 1
            } else {
                // Completed all cards
                topicManager.currentTopic = nil
            }
        }
    }
    
    private func markAsUnderstood() {
        guard let topic = topicManager.currentTopic,
              currentCardIndex < topic.flashcards.count else { return }
        
        topicManager.markCardAsUnderstood(topicId: topic.id, cardIndex: currentCardIndex)
    }
    
    private func toggleBookmark() {
        guard let topic = topicManager.currentTopic,
              currentCardIndex < topic.flashcards.count else { return }
        
        topicManager.toggleBookmark(topicId: topic.id, cardIndex: currentCardIndex)
    }
}
