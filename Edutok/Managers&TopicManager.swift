import Foundation
import SwiftUI

@MainActor
class TopicManager: ObservableObject {
    @Published var savedTopics: [Topic] = []
    @Published var currentTopic: Topic?
    
    private let geminiAPIKey = "AIzaSyCs5jpHB0v_FqxPzFWVOA4F3dSAWyRew_c"
    private let userDefaultsKey = "SavedTopics"
    
    func generateFlashcards(for topicTitle: String) async {
        do {
            let flashcards = try await fetchFlashcardsFromGemini(topic: topicTitle)
            let newTopic = Topic(title: topicTitle, flashcards: flashcards)
            
            savedTopics.insert(newTopic, at: 0)
            currentTopic = newTopic
            saveTopics()
        } catch {
            print("Error generating flashcards: \(error)")
            // Create mock data as fallback
            let mockFlashcards = createMockFlashcards(for: topicTitle)
            let newTopic = Topic(title: topicTitle, flashcards: mockFlashcards)
            
            savedTopics.insert(newTopic, at: 0)
            currentTopic = newTopic
            saveTopics()
        }
    }
    
    private func fetchFlashcardsFromGemini(topic: String) async throws -> [Flashcard] {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(geminiAPIKey)")!
        
        let prompt = """
        Create exactly 10 educational flashcards about "\(topic)". Return ONLY a valid JSON array with this exact structure:
        [
            {
                "type": "definition",
                "question": "What is photosynthesis?",
                "answer": "The process by which plants convert sunlight into energy"
            },
            {
                "type": "question",
                "question": "Where does photosynthesis occur in plants?",
                "answer": "In the chloroplasts of plant cells"
            }
        ]
        
        Use these types: "definition", "question", "true/false", "fill in the blank"
        Make questions engaging and answers concise but informative.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
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
        
        let jsonText = firstPart.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        struct FlashcardData: Codable {
            let type: String
            let question: String
            let answer: String
        }
        
        let flashcardData = try JSONDecoder().decode([FlashcardData].self, from: jsonText.data(using: .utf8)!)
        
        return flashcardData.compactMap { data in
            guard let type = FlashcardType(rawValue: data.type) else { return nil }
            return Flashcard(type: type, question: data.question, answer: data.answer)
        }
    }
    
    private func createMockFlashcards(for topic: String) -> [Flashcard] {
        let mockData: [(FlashcardType, String, String)] = [
            (.definition, "What is \(topic)?", "A comprehensive subject that involves multiple interconnected concepts and principles."),
            (.question, "Why is \(topic) important?", "It provides foundational knowledge that helps us understand complex systems and relationships."),
            (.truefalse, "\(topic) is a fundamental concept in its field.", "True - it serves as a building block for more advanced understanding."),
            (.fillblank, "The main characteristic of \(topic) is ____.", "its ability to explain and predict various phenomena."),
            (.definition, "What are the key components of \(topic)?", "Multiple elements that work together to form a cohesive understanding."),
            (.question, "How does \(topic) relate to other concepts?", "It connects various ideas and provides a framework for deeper analysis."),
            (.truefalse, "\(topic) can be learned in isolation.", "False - it's best understood in context with related concepts."),
            (.fillblank, "Students often find \(topic) ____ when first learning it.", "challenging but rewarding once they grasp the fundamentals."),
            (.question, "What makes \(topic) unique?", "Its distinctive approach to solving problems and explaining phenomena."),
            (.definition, "How would you summarize \(topic)?", "An essential area of study that builds critical thinking and analytical skills.")
        ]
        
        return mockData.map { (type, question, answer) in
            Flashcard(type: type, question: question, answer: answer)
        }
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
