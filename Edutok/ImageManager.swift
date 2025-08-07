import Foundation
import SwiftUI

@MainActor
class ImageManager: ObservableObject {
    static let shared = ImageManager()
    
    private let unsplashAccessKey = "I0EJ10tuuAYutgLBHLQ7TTlQRqxbT3W2goFQTWPeHCo"
    private let geminiAPIKey = "AIzaSyAR4ta577a14bej9zoN4cYWVgdbGiWCwzg"
    private var imageCache: [String: String] = [:] // Cache for image URLs
    
    // Generate image search keywords using Gemini
    func generateImageKeywords(for question: String, topic: String) async -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(geminiAPIKey)")!
        
        let prompt = """
        Generate 2-3 highly relevant image search keywords for this educational flashcard question.
        Topic: \(topic)
        Question: \(question)
        
        Return ONLY the keywords separated by commas, no explanation.
        Make keywords specific and visual. Example: "DNA helix, molecular biology"
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
                "temperature": 0.3,
                "maxOutputTokens": 50
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
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
            if let keywords = response.candidates.first?.content.parts.first?.text {
                return keywords.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Error generating keywords: \(error)")
        }
        
        // Fallback to topic if Gemini fails
        return topic
    }
    
    // Fetch image from Unsplash API
    func fetchImage(keywords: String) async -> String? {
        // Check cache first
        if let cachedURL = imageCache[keywords] {
            return cachedURL
        }
        
        // Clean up keywords for Unsplash search
        let searchQuery = keywords.replacingOccurrences(of: ",", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        // Use Unsplash API with access key
        let urlString = "https://api.unsplash.com/search/photos?query=\(encodedQuery)&per_page=1&orientation=landscape&client_id=\(unsplashAccessKey)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            struct UnsplashResponse: Codable {
                let results: [Photo]
                
                struct Photo: Codable {
                    let urls: URLs
                    
                    struct URLs: Codable {
                        let regular: String
                        let small: String
                    }
                }
            }
            
            let response = try JSONDecoder().decode(UnsplashResponse.self, from: data)
            
            if let firstPhoto = response.results.first {
                let imageURL = firstPhoto.urls.small // Use small size for performance
                imageCache[keywords] = imageURL
                return imageURL
            }
        } catch {
            print("Error fetching from Unsplash: \(error)")
        }
        
        // Fallback to direct Unsplash source (no API key needed)
        let fallbackURL = "https://source.unsplash.com/400x300/?\(encodedQuery)"
        imageCache[keywords] = fallbackURL
        return fallbackURL
    }
    
    // Generate and fetch image for a flashcard
    func generateImageForFlashcard(question: String, topic: String) async -> String? {
        // Generate keywords using Gemini
        let keywords = await generateImageKeywords(for: question, topic: topic)
        
        // Fetch image using keywords
        return await fetchImage(keywords: keywords)
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
