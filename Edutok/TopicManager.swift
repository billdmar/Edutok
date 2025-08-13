import Foundation
import SwiftUI

@MainActor
class TopicManager: ObservableObject {
    @Published var savedTopics: [Topic] = []
    @Published var currentTopic: Topic?
    
    private let geminiAPIKey = "AIzaSyCs5jpHB0v_FqxPzFWVOA4F3dSAWyRew_c"
    private let unsplashAPIKey = "I0EJ10tuuAYutgLBHLQ7TTlQRqxbT3W2goFQTWPeHCo"
    private let userDefaultsKey = "SavedTopics"
    
    func generateFlashcards(for topicTitle: String) async {
        do {
            // Generate initial batch of facts
            var initialFacts = try await fetchFlashcardsFromGemini(topic: topicTitle, batchNumber: 1)
            
            // Generate unique images for each flashcard with variation
            for index in initialFacts.indices {
                let imageURL = await ImageManager.shared.generateDiverseImageForFlashcard(
                    question: initialFacts[index].question,
                    topic: topicTitle,
                    variation: index
                )
                initialFacts[index].imageURL = imageURL
            }
            
            let newTopic = Topic(title: topicTitle, flashcards: initialFacts)
            
            savedTopics.insert(newTopic, at: 0)
            currentTopic = newTopic
            saveTopics()
            await FirebaseManager.shared.trackTopicExplored()
            
            // NEW: Update challenge progress for topic exploration
            updateTopicExplorationChallenge()

        } catch {
            print("Error generating flashcards: \(error)")
            // Create enhanced mock data as fallback
            var mockFlashcards = createEnhancedMockFlashcards(for: topicTitle)
            
            // Generate unique images for each mock flashcard with variation
            for index in mockFlashcards.indices {
                let imageURL = await ImageManager.shared.generateDiverseImageForFlashcard(
                    question: mockFlashcards[index].question,
                    topic: topicTitle,
                    variation: index
                )
                mockFlashcards[index].imageURL = imageURL
            }
            
            let newTopic = Topic(title: topicTitle, flashcards: mockFlashcards)
            
            savedTopics.insert(newTopic, at: 0)
            currentTopic = newTopic
            saveTopics()
            
            // NEW: Update challenge progress for topic exploration
            updateTopicExplorationChallenge()
        }
    }
    
    // NEW: Helper function to update topic exploration challenge
    private func updateTopicExplorationChallenge() {
        // This will be called from the GamificationManager when it's available
        // For now, we'll use a simple notification approach
        NotificationCenter.default.post(
            name: NSNotification.Name("TopicExplored"),
            object: nil
        )
    }
    
    func deleteTopic(_ topic: Topic) {
        savedTopics.removeAll { $0.id == topic.id }
        
        // If the deleted topic is currently active, clear it
        if currentTopic?.id == topic.id {
            currentTopic = nil
        }
        
        saveTopics()
    }
    
    func generateMoreFacts(for topic: Topic) async {
        do {
            let batchNumber = (topic.flashcards.count / 15) + 2 // Generate next batch
            var newFacts = try await fetchFlashcardsFromGemini(topic: topic.title, batchNumber: batchNumber)
            
            // Generate unique images for new facts with variation
            for index in newFacts.indices {
                let imageURL = await ImageManager.shared.generateDiverseImageForFlashcard(
                    question: newFacts[index].question,
                    topic: topic.title,
                    variation: (topic.flashcards.count + index) % 12
                )
                newFacts[index].imageURL = imageURL
            }
            
            // Add new facts to existing topic
            if let topicIndex = savedTopics.firstIndex(where: { $0.id == topic.id }) {
                savedTopics[topicIndex].flashcards.append(contentsOf: newFacts)
                
                // Update current topic if it matches
                if currentTopic?.id == topic.id {
                    currentTopic?.flashcards.append(contentsOf: newFacts)
                }
                
                saveTopics()
                await FirebaseManager.shared.trackTopicExplored()
            }
        } catch {
            print("Error generating more facts: \(error)")
            // Add enhanced mock facts as fallback
            var mockFacts = createEnhancedMockFlashcards(for: topic.title, batchNumber: (topic.flashcards.count / 15) + 2)
            
            // Generate unique images for each mock flashcard with variation
            for index in mockFacts.indices {
                let imageURL = await ImageManager.shared.generateDiverseImageForFlashcard(
                    question: mockFacts[index].question,
                    topic: topic.title,
                    variation: (topic.flashcards.count + index) % 12
                )
                mockFacts[index].imageURL = imageURL
            }
            
            if let topicIndex = savedTopics.firstIndex(where: { $0.id == topic.id }) {
                savedTopics[topicIndex].flashcards.append(contentsOf: mockFacts)
                
                if currentTopic?.id == topic.id {
                    currentTopic?.flashcards.append(contentsOf: mockFacts)
                }
                
                saveTopics()
            }
        }
    }
    
    private func fetchFlashcardsFromGemini(topic: String, batchNumber: Int) async throws -> [Flashcard] {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(geminiAPIKey)")!
        
        let prompt = createEnhancedFactsPrompt(for: topic, batchNumber: batchNumber)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 3000,
                "topP": 0.8
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        struct GeminiResponse: Codable {
            let candidates: [Candidate]
            
            struct Candidate: Codable {
                let content: Content
                
                struct Content: Codable {
                    let parts: [Part]
                    
                    struct Part: Codable {
                        let text: String
                    }
                }
            }
        }
        
        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let firstCandidate = response.candidates.first,
              let firstPart = firstCandidate.content.parts.first else {
            throw APIError.invalidResponse
        }
        
        let jsonText = cleanJSONResponse(firstPart.text)
        
        struct FlashcardData: Codable {
            let type: String
            let question: String
            let answer: String
        }
        
        do {
            let flashcardData = try JSONDecoder().decode([FlashcardData].self, from: jsonText.data(using: .utf8)!)
            
            return flashcardData.compactMap { data in
                let normalizedType = data.type.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "_", with: "")
                
                let flashcardType: FlashcardType?
                switch normalizedType {
                case "definition":
                    flashcardType = .definition
                case "question":
                    flashcardType = .question
                case "truefalse", "true/false":
                    flashcardType = .truefalse
                case "fillinblank", "fillblank", "fill-in-blank", "fillintheblank":
                    flashcardType = .fillblank
                default:
                    flashcardType = .question // Default fallback
                }
                
                guard let type = flashcardType else { return nil }
                return Flashcard(type: type, question: data.question, answer: data.answer)
            }
        } catch {
            print("JSON parsing error: \(error)")
            print("Received JSON: \(jsonText)")
            throw APIError.invalidResponse
        }
    }
    
    private func createEnhancedFactsPrompt(for topic: String, batchNumber: Int) -> String {
        let aspectFocus = getEnhancedTopicAspect(for: batchNumber)
        let depthLevel = getDepthLevel(for: batchNumber)
        
        return """
        You are an expert educator creating high-quality, educational flashcards about "\(topic)". This is batch #\(batchNumber) with focus: \(aspectFocus).

        CONTENT QUALITY STANDARDS:
        • Each fact must be accurate, specific, and intellectually enriching
        • Content should be suitable for learners seeking deep understanding
        • Balance accessibility with sophistication - explain complex concepts clearly
        • Include precise details, specific examples, and concrete information
        • Avoid oversimplification while maintaining clarity
        
        TOPIC ADAPTABILITY:
        • For SPECIFIC topics (e.g., "Betta Fish Care"): Provide detailed, practical insights
        • For GENERAL topics (e.g., "Biology"): Cover fundamental principles and key concepts
        • For ABSTRACT topics (e.g., "Philosophy"): Use concrete examples to illustrate ideas
        • For TECHNICAL topics: Explain mechanisms, processes, and applications
        
        DEPTH LEVEL: \(depthLevel)
        
        VARIETY REQUIREMENTS (exactly 15 cards):
        1. Historical context and timeline events
        2. Scientific mechanisms and processes
        3. Practical applications and real-world uses
        4. Surprising statistics with context
        5. Cause-and-effect relationships
        6. Comparative analysis with similar concepts
        7. Common misconceptions vs. reality
        8. Current research and developments
        9. Cultural or geographical variations
        10. Problem-solving scenarios
        11. Critical thinking challenges
        12. Interdisciplinary connections
        13. Case studies or examples
        14. Future implications and trends
        15. Fundamental principles and core concepts
        
        QUESTION CONSTRUCTION:
        • Use varied, engaging question stems that promote learning
        • Include "How does...", "Why do...", "What happens when...", "Which factor..."
        • Create questions that test understanding, not just memory
        • Ensure each question has educational value beyond the answer
        
        ANSWER QUALITY:
        • Provide comprehensive yet concise explanations (2-4 sentences max)
        • Include the 'why' behind facts, not just the 'what'
        • Use specific examples and concrete details
        • Connect information to broader concepts when relevant
        • Ensure answers teach something meaningful
        
        ENGAGEMENT STANDARDS:
        • Write in clear, professional language without excessive casualness
        • Use compelling facts that make users think "I didn't know that!"
        • Create intellectual curiosity and encourage further learning
        • Maintain academic rigor while being accessible
        • No emoji overuse - let content quality drive engagement
        
        Return exactly 15 cards in JSON format:
        [
            {
                "type": "question",
                "question": "How do electric eels generate electricity without harming themselves?",
                "answer": "Electric eels have specialized cells called electrocytes that act like biological batteries. They're insulated by layers of fat and generate current in controlled directions, with the electric organs making up 80% of their body length."
            },
            {
                "type": "truefalse",
                "question": "Electric eels are actually a type of fish, not true eels.",
                "answer": "True. Despite their name, electric eels are knife fish more closely related to catfish and carp. True eels belong to a completely different order and cannot generate electricity."
            }
        ]

        Focus specifically on "\(topic)" and create intellectually stimulating content that genuinely educates users while maintaining their interest through quality, not gimmicks.
        """
    }
    
    private func getEnhancedTopicAspect(for batchNumber: Int) -> String {
        let aspects = [
            "Core fundamentals and essential principles",
            "Historical development and key discoveries",
            "Scientific mechanisms and underlying processes",
            "Real-world applications and practical implications",
            "Current research and cutting-edge developments",
            "Comparative analysis and relationships to other fields",
            "Problem-solving applications and case studies",
            "Misconceptions versus established facts",
            "Future trends and emerging developments",
            "Cultural, geographical, or contextual variations",
            "Interdisciplinary connections and broader impacts",
            "Critical thinking challenges and complex scenarios",
            "Detailed examples and specific implementations",
            "Advanced concepts and specialized knowledge",
            "Synthesis and integration of multiple aspects"
        ]
        
        return aspects[(batchNumber - 1) % aspects.count]
    }
    
    private func getDepthLevel(for batchNumber: Int) -> String {
        switch batchNumber % 4 {
        case 1: return "Foundational - Core concepts everyone should know"
        case 2: return "Intermediate - Detailed understanding with practical applications"
        case 3: return "Advanced - Nuanced concepts and complex relationships"
        case 0: return "Expert - Cutting-edge insights and sophisticated analysis"
        default: return "Comprehensive - Balanced mix of all levels"
        }
    }
    
    private func cleanJSONResponse(_ text: String) -> String {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace smart quotes with regular quotes
        cleaned = cleaned.replacingOccurrences(of: "\u{201C}", with: "\"") // Left double quote
        cleaned = cleaned.replacingOccurrences(of: "\u{201D}", with: "\"") // Right double quote
        cleaned = cleaned.replacingOccurrences(of: "\u{2018}", with: "'")  // Left single quote
        cleaned = cleaned.replacingOccurrences(of: "\u{2019}", with: "'")  // Right single quote
        
        // Find the JSON array bounds
        if let startIndex = cleaned.firstIndex(of: "["),
           let endIndex = cleaned.lastIndex(of: "]") {
            return String(cleaned[startIndex...endIndex])
        }
        
        return cleaned
    }
    
    private func createEnhancedMockFlashcards(for topic: String, batchNumber: Int = 1) -> [Flashcard] {
        let templates: [(FlashcardType, String, String)] = [
            (.question, "What fundamental principle underlies how \(topic) operates in its primary context?", "The core mechanism involves specific interactions between key components, creating measurable effects that can be observed and studied through established methodologies."),
            
            (.truefalse, "The development of \(topic) knowledge has remained relatively unchanged over the past century.", "False. Significant advances in research methods, technology, and theoretical understanding have dramatically expanded our knowledge and applications in recent decades."),
            
            (.definition, "How does \(topic) demonstrate cause-and-effect relationships in practical applications?", "It exhibits clear patterns where specific inputs or conditions lead to predictable outcomes, allowing for systematic study and practical implementation across various contexts."),
            
            (.question, "What makes \(topic) particularly significant in its broader field of study?", "Its unique characteristics provide insights into fundamental processes that apply across multiple disciplines, making it a valuable model for understanding complex systems."),
            
            (.fillblank, "The most critical factor determining success in \(topic) applications is ______.", "understanding the underlying principles and their practical limitations"),
            
            (.truefalse, "Current research in \(topic) focuses primarily on traditional approaches rather than innovative methods.", "False. Contemporary research emphasizes cutting-edge techniques, interdisciplinary collaboration, and novel applications that challenge conventional understanding."),
            
            (.question, "How do experts differentiate between various approaches within \(topic)?", "They analyze specific criteria including effectiveness, scope of application, underlying assumptions, and measurable outcomes to establish clear distinctions and best practices."),
            
            (.definition, "What role does \(topic) play in addressing contemporary challenges?", "It provides essential tools and frameworks for tackling complex problems, offering evidence-based solutions that can be adapted to diverse situations and requirements."),
            
            (.question, "What surprising connections exist between \(topic) and other fields of study?", "Research reveals unexpected parallels and shared principles that cross traditional disciplinary boundaries, creating opportunities for innovative approaches and applications."),
            
            (.fillblank, "The future development of \(topic) will likely depend on advances in ______.", "technology, interdisciplinary research, and practical implementation strategies"),
            
            (.truefalse, "Mastery of \(topic) requires only theoretical knowledge without practical experience.", "False. True expertise demands integration of theoretical understanding with hands-on experience, critical thinking, and adaptive problem-solving skills."),
            
            (.question, "How do cultural or contextual factors influence approaches to \(topic)?", "Different backgrounds and environments create varying perspectives, methodologies, and applications, enriching the overall understanding and effectiveness of the field."),
            
            (.definition, "What distinguishes expert-level understanding from basic knowledge in \(topic)?", "Expert comprehension involves nuanced appreciation of complex relationships, ability to adapt principles to novel situations, and deep insight into underlying mechanisms."),
            
            (.question, "What evidence supports the effectiveness of current approaches to \(topic)?", "Rigorous research demonstrates measurable improvements in outcomes, validated through peer review, replication studies, and real-world implementation across diverse contexts."),
            
            (.fillblank, "The most common misconception about \(topic) is that it ______.", "only applies to specialized situations rather than having broad practical relevance")
        ]
        
        return templates.map { (type, question, answer) in
            Flashcard(type: type, question: question, answer: answer)
        }
    }
    
    func toggleTopicLike(topicId: UUID) {
        guard let topicIndex = savedTopics.firstIndex(where: { $0.id == topicId }) else { return }
        
        savedTopics[topicIndex].isLiked.toggle()
        
        // Update current topic if it matches
        if currentTopic?.id == topicId {
            currentTopic?.isLiked.toggle()
        }
        
        saveTopics()
    }
    
    func markCardAsUnderstood(topicId: UUID, cardIndex: Int) {
        guard let topicIndex = savedTopics.firstIndex(where: { $0.id == topicId }),
              cardIndex < savedTopics[topicIndex].flashcards.count else { return }
        
        savedTopics[topicIndex].flashcards[cardIndex].isUnderstood = true
        
        // Update current topic if it matches
        if currentTopic?.id == topicId {
            currentTopic?.flashcards[cardIndex].isUnderstood = true
        }
        
        saveTopics()
        Task {
            await FirebaseManager.shared.trackCardFlipped()
        }
    }
    
    func toggleBookmark(topicId: UUID, cardIndex: Int) {
        guard let topicIndex = savedTopics.firstIndex(where: { $0.id == topicId }),
              cardIndex < savedTopics[topicIndex].flashcards.count else { return }
        
        savedTopics[topicIndex].flashcards[cardIndex].isBookmarked.toggle()
        
        // Update current topic if it matches
        if currentTopic?.id == topicId {
            currentTopic?.flashcards[cardIndex].isBookmarked.toggle()
        }
        
        saveTopics()
    }
    
    func saveTopics() {
        do {
            let data = try JSONEncoder().encode(savedTopics)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error saving topics: \(error)")
        }
    }
    
    func loadSavedTopics() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            savedTopics = try JSONDecoder().decode([Topic].self, from: data)
        } catch {
            print("Error loading topics: \(error)")
            savedTopics = []
        }
    }
}

enum APIError: Error {
    case invalidResponse
    case noData
}

// Card flipping tracking (for any card interaction)
func trackCardFlip() {
    Task {
        await FirebaseManager.shared.trackCardFlipped()
    }
}
