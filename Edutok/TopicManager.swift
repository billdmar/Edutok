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
            
            // Generate images for each flashcard
            for index in initialFacts.indices {
                let imageURL = await ImageManager.shared.generateImageForFlashcard(
                    question: initialFacts[index].question,
                    topic: topicTitle
                )
                initialFacts[index].imageURL = imageURL
            }
            
            let newTopic = Topic(title: topicTitle, flashcards: initialFacts)
            
            savedTopics.insert(newTopic, at: 0)
            currentTopic = newTopic
            saveTopics()
        } catch {
            print("Error generating flashcards: \(error)")
            // Create mock data as fallback
            var mockFlashcards = createMockFlashcards(for: topicTitle)
            
            // Add placeholder images for mock data
            for index in mockFlashcards.indices {
                mockFlashcards[index].imageURL = "https://source.unsplash.com/400x300/?education,\(topicTitle)"
            }
            
            let newTopic = Topic(title: topicTitle, flashcards: mockFlashcards)
            
            savedTopics.insert(newTopic, at: 0)
            currentTopic = newTopic
            saveTopics()
        }
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
            
            // Generate images for new facts
            for index in newFacts.indices {
                let imageURL = await ImageManager.shared.generateImageForFlashcard(
                    question: newFacts[index].question,
                    topic: topic.title
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
            }
        } catch {
            print("Error generating more facts: \(error)")
            // Add some mock facts as fallback
            var mockFacts = createAdditionalMockFacts(for: topic.title, batchNumber: (topic.flashcards.count / 15) + 2)
            
            // Add placeholder images for mock facts
            for index in mockFacts.indices {
                mockFacts[index].imageURL = "https://source.unsplash.com/400x300/?education,\(topic.title)"
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
        
        let prompt = createInfiniteFactsPrompt(for: topic, batchNumber: batchNumber)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "maxOutputTokens": 2048,
                "topP": 0.9
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
                // Normalize the type string
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
    
    private func createInfiniteFactsPrompt(for topic: String, batchNumber: Int) -> String {
        let aspectFocus = getTopicAspect(for: batchNumber)
        
        return """
        You are creating an endless stream of fascinating facts and learning content about "\(topic)". This is batch #\(batchNumber) - make each batch explore different aspects and depths of the topic.

        BATCH FOCUS: \(aspectFocus)

        INFINITE CONTENT GUIDELINES:
        1. Create exactly 15 diverse fact cards (not just 10)
        2. Each batch should explore NEW angles, facts, and perspectives about "\(topic)"
        3. Mix difficulty levels - some basic, some advanced, some quirky/surprising
        4. Include historical facts, modern applications, scientific details, cultural aspects, fun trivia
        5. Make facts addictive and "wow-factor" worthy - things people didn't know
        6. Use perfect grammar and make each fact standalone interesting
        7. Vary question types extensively

        VARIETY REQUIREMENTS:
        - Historical facts and timeline events
        - Scientific/technical details
        - Cultural and social aspects  
        - Economic or practical applications
        - Surprising statistics and comparisons
        - Future developments and research
        - Common myths vs reality
        - Regional or global variations
        
        QUESTION STYLES TO USE:
        - "Did you know that..." interesting facts
        - Comparison questions ("How does X compare to Y?")
        - Process questions ("How does X work?")
        - Historical questions ("When did X happen?")
        - "What would happen if..." hypotheticals
        - Statistical facts with numbers
        - True/false with surprising twists

        Return exactly 15 fact cards in JSON format:
        [
            {
                "type": "question",
                "question": "What surprising defense mechanism do betta fish use when threatened?",
                "answer": "Betta fish can change their color instantly when threatened, becoming darker to appear more intimidating to predators."
            },
            {
                "type": "truefalse", 
                "question": "Betta fish can recognize their owners and show excitement when they approach.",
                "answer": "True! Bettas have excellent vision and memory, often swimming excitedly toward their owners and can be trained to perform simple tricks."
            }
        ]

        Focus specifically on "\(topic)" and create mind-blowing, shareable facts that will keep users endlessly scrolling for more knowledge!
        """
    }
    
    private func getTopicAspect(for batchNumber: Int) -> String {
        let aspects = [
            "Basic fundamentals and core concepts",
            "Historical background and origins",
            "Scientific and technical details",
            "Cultural and social significance",
            "Modern applications and uses",
            "Surprising facts and statistics",
            "Common misconceptions and myths",
            "Future developments and research",
            "Comparisons with similar topics",
            "Regional variations and differences",
            "Economic and practical aspects",
            "Fun trivia and interesting stories"
        ]
        
        return aspects[(batchNumber - 1) % aspects.count]
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
    
    private func createMockFlashcards(for topic: String) -> [Flashcard] {
        // Enhanced mock data that creates an infinite feel
        return createAdditionalMockFacts(for: topic, batchNumber: 1)
    }
    
    private func createAdditionalMockFacts(for topic: String, batchNumber: Int) -> [Flashcard] {
        let mockTemplates: [(FlashcardType, String, String)] = [
            (.question, "What fascinating aspect of \(topic) surprises most people?", "There are many surprising elements that reveal the complexity and uniqueness of this subject."),
            (.truefalse, "\(topic) has been studied extensively for over a century.", "True - research and understanding of this topic has evolved significantly over time."),
            (.definition, "What makes \(topic) unique in its field?", "Its distinctive characteristics and specific properties set it apart from similar concepts."),
            (.fillblank, "The most important factor in understanding \(topic) is ______.", "recognizing its core principles and foundational concepts"),
            (.question, "How has \(topic) evolved in recent years?", "Modern developments have expanded our understanding and applications significantly."),
            (.truefalse, "\(topic) only affects a small, specialized community.", "False - it has broader implications and relevance than commonly assumed."),
            (.definition, "What role does \(topic) play in everyday life?", "It influences various aspects of daily experience in both obvious and subtle ways."),
            (.question, "What would happen if \(topic) didn't exist?", "The absence would create significant gaps in understanding and practical applications."),
            (.fillblank, "Experts consider ______ the most crucial aspect of \(topic).", "proper understanding and application of its fundamental principles"),
            (.question, "How does \(topic) compare to related concepts?", "While sharing some similarities, it has distinct characteristics that make it unique."),
            (.truefalse, "\(topic) is becoming less relevant in modern times.", "False - it remains highly relevant and continues to gain importance."),
            (.definition, "What are the latest developments in \(topic)?", "Recent advances have opened new possibilities and applications."),
            (.question, "Why do experts recommend learning about \(topic)?", "Understanding it provides valuable insights and practical knowledge."),
            (.fillblank, "The future of \(topic) depends on ______.", "continued research, innovation, and practical application"),
            (.question, "What surprising connections does \(topic) have with other fields?", "It intersects with various disciplines in unexpected and meaningful ways.")
        ]
        
        return mockTemplates.map { (type, question, answer) in
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
