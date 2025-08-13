import Foundation
import SwiftUI

@MainActor
class ImageManager: ObservableObject {
    static let shared = ImageManager()
    
    private let unsplashAccessKey = "I0EJ10tuuAYutgLBHLQ7TTlQRqxbT3W2goFQTWPeFQTWPeHCo"
    private let geminiAPIKey = "AIzaSyAR4ta577a14bej9zoN4cYWVgdbGiWCwzg"
    private var imageCache: [String: String] = [:] // Cache for image URLs
    private var questionImageCache: [String: String] = [:] // Cache for specific question-image pairs
    
    // Generate unique image search keywords using Gemini with more variety
    func generateImageKeywords(for question: String, topic: String) async -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(geminiAPIKey)")!
        
        // Create a more specific and varied prompt for unique images
        let prompt = """
        Generate 3-4 highly specific and visual image search keywords for this educational flashcard question.
        Topic: \(topic)
        Question: \(question)
        
        Make each set of keywords unique and specific to the question content.
        Include visual elements, objects, concepts, or scenarios that would make a compelling image.
        Avoid generic terms - be specific and descriptive.
        
        Return ONLY the keywords separated by commas, no explanation.
        Example format: "DNA double helix structure, molecular biology laboratory, genetic code visualization"
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7, // Increased temperature for more variety
                "maxOutputTokens": 100
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, _) = try await URLSession.shared.data(from: url)
            
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
            if let keywords = response.candidates.first?.content.parts.first?.text {
                return keywords.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Error generating keywords: \(error)")
        }
        
        // Enhanced fallback that includes question content for more variety
        let fallbackKeywords = "\(topic), \(question.prefix(50))".replacingOccurrences(of: "?", with: "").replacingOccurrences(of: "What", with: "").replacingOccurrences(of: "How", with: "").replacingOccurrences(of: "Why", with: "")
        return fallbackKeywords
    }
    
    // Fetch image from Unsplash API with more variety
    func fetchImage(keywords: String, question: String? = nil) async -> String? {
        // Create a unique cache key that includes both keywords and question
        let cacheKey = question != nil ? "\(keywords)_\(question!.prefix(30))" : keywords
        
        // Check question-specific cache first
        if let question = question, let cachedURL = questionImageCache[cacheKey] {
            return cachedURL
        }
        
        // Check general cache
        if let cachedURL = imageCache[keywords] {
            return cachedURL
        }
        
        // Clean up keywords for Unsplash search
        let searchQuery = keywords.replacingOccurrences(of: ",", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        // Use Unsplash API with access key and get multiple results for variety
        let urlString = "https://api.unsplash.com/search/photos?query=\(encodedQuery)&per_page=5&orientation=landscape&client_id=\(unsplashAccessKey)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            struct UnsplashResponse: Codable {
                let results: [Photo]
                
                struct Photo: Codable {
                    let urls: URLs
                    let id: String
                    
                    struct URLs: Codable {
                        let regular: String
                        let small: String
                    }
                }
            }
            
            let response = try JSONDecoder().decode(UnsplashResponse.self, from: data)
            
            if !response.results.isEmpty {
                // Select a random photo from the results for more variety
                let randomIndex = Int.random(in: 0..<min(response.results.count, 3))
                let selectedPhoto = response.results[randomIndex]
                let imageURL = selectedPhoto.urls.small
                
                // Cache both by keywords and by question
                imageCache[keywords] = imageURL
                if let question = question {
                    questionImageCache[cacheKey] = imageURL
                }
                
                return imageURL
            }
        } catch {
            print("Error fetching from Unsplash: \(error)")
        }
        
        // Enhanced fallback with more variety
        let fallbackURL = "https://source.unsplash.com/400x300/?\(encodedQuery)&\(Int.random(in: 1...1000))"
        imageCache[keywords] = fallbackURL
        if let question = question {
            questionImageCache[cacheKey] = fallbackURL
        }
        return fallbackURL
    }
    
    // Generate and fetch unique image for a flashcard
    func generateImageForFlashcard(question: String, topic: String) async -> String? {
        // Generate unique keywords using Gemini
        let keywords = await generateImageKeywords(for: question, topic: topic)
        
        // Fetch image using keywords and question for unique caching
        return await fetchImage(keywords: keywords, question: question)
    }
    
    // Generate a more diverse image by adding variety to the search
    func generateDiverseImageForFlashcard(question: String, topic: String, variation: Int = 0) async -> String? {
        // Generate base keywords
        let baseKeywords = await generateImageKeywords(for: question, topic: topic)
        
        // Add variation to make each image unique
        let variedKeywords = addVariationToKeywords(baseKeywords, variation: variation)
        
        // Fetch image with varied keywords
        return await fetchImage(keywords: variedKeywords, question: question)
    }
    
    // Add variation to keywords to ensure uniqueness
    private func addVariationToKeywords(_ keywords: String, variation: Int) -> String {
        let variations = [
            "close-up", "wide angle", "detailed", "abstract", "modern", "vintage",
            "scientific", "artistic", "technical", "creative", "professional", "casual"
        ]
        
        if variation < variations.count {
            return "\(keywords), \(variations[variation])"
        } else {
            // Add random elements for more variety
            let randomElements = ["detailed", "modern", "professional", "scientific"]
            let randomElement = randomElements[Int.random(in: 0..<randomElements.count)]
            return "\(keywords), \(randomElement)"
        }
    }
    
    // Clear cache to free memory
    func clearCache() {
        imageCache.removeAll()
        questionImageCache.removeAll()
    }
    
    // Get cache statistics
    func getCacheStats() -> (generalCache: Int, questionCache: Int) {
        return (imageCache.count, questionImageCache.count)
    }
    
    // Debug method to check if images are unique
    func checkImageUniqueness(for topic: String) -> [String: Int] {
        var imageCounts: [String: Int] = [:]
        
        for (_, imageURL) in imageCache {
            imageCounts[imageURL, default: 0] += 1
        }
        
        return imageCounts
    }
    
    // Method to force refresh images for a topic (useful for testing)
    func refreshImagesForTopic(_ topic: String) {
        // Remove cached images for this topic to force regeneration
        let keysToRemove = imageCache.keys.filter { $0.contains(topic) }
        for key in keysToRemove {
            imageCache.removeValue(forKey: key)
        }
        
        let questionKeysToRemove = questionImageCache.keys.filter { $0.contains(topic) }
        for key in questionKeysToRemove {
            questionImageCache.removeValue(forKey: key)
        }
    }
}

// Image loader view for async image loading
struct AsyncImageLoader: View {
    let url: String?
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            } else if isLoading {
                // Loading state
                ZStack {
                    Color.white.opacity(0.1)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
            } else {
                // Fallback gradient if image fails
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let urlString = url, let imageURL = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        withAnimation(.easeIn(duration: 0.3)) {
                            self.image = loadedImage
                            self.isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }
            } catch {
                print("Error loading image: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
