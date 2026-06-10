/// ImageManager.swift
///
/// Resolves a relevant image URL for each flashcard. Gemini is asked to produce
/// descriptive search keywords from the card's question/topic, those keywords are
/// queried against the Unsplash search API (landscape, small resolution), and a
/// result is picked for visual variety. Resolved URLs are cached in bounded
/// `NSCache`s; if any step fails the card simply shows its gradient placeholder.
import Foundation
import SwiftUI

/// Shared, main-actor service for generating and caching flashcard image URLs.
@MainActor
class ImageManager: ObservableObject {
    static let shared = ImageManager()

    // Bounded LRU caches (NSCache) so resolved image URLs don't grow without limit.
    // NSCache evicts automatically under memory pressure and respects countLimit.
    private let imageCache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 500
        return cache
    }() // Cache for image URLs
    private let questionImageCache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 500
        return cache
    }() // Cache for specific question-image pairs

    /// Asks Gemini for specific, visual search keywords describing the question.
    /// Always returns a usable string: on any failure (bad URL, non-200, decode/network
    /// error) it returns a fallback derived from the topic and question text.
    func generateImageKeywords(for question: String, topic: String) async -> String {
        // Enhanced fallback that includes question content for more variety.
        // Computed up front so any early-exit path can return it.
        let fallbackKeywords = "\(topic), \(question.prefix(50))".replacingOccurrences(of: "?", with: "").replacingOccurrences(of: "What", with: "").replacingOccurrences(of: "How", with: "").replacingOccurrences(of: "Why", with: "")

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(Secrets.geminiAPIKey)") else {
            return fallbackKeywords
        }

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
        request.timeoutInterval = 20

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            // Send the POST `request` we just built (not a bare GET to `url`).
            let (data, response) = try await URLSession.shared.data(for: request)

            // Fall through to the keyword fallback on any non-200 response.
            if (response as? HTTPURLResponse)?.statusCode != 200 {
                return fallbackKeywords
            }

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

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            if let keywords = geminiResponse.candidates.first?.content.parts.first?.text {
                return keywords.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            #if DEBUG
            print("Error generating keywords: \(error)")
            #endif
        }

        return fallbackKeywords
    }

    /// Searches Unsplash for the given keywords and returns a small-resolution image URL,
    /// caching the result by keywords (and by question when provided). Returns `nil` when
    /// the request is rate-limited/unauthorized, errors, or yields no results.
    func fetchImage(keywords: String, question: String? = nil) async -> String? {
        // Create a unique cache key that includes both keywords and question
        let cacheKey = question != nil ? "\(keywords)_\(question!.prefix(30))" : keywords

        // Check question-specific cache first
        if question != nil, let cachedURL = questionImageCache.object(forKey: cacheKey as NSString) {
            return cachedURL as String
        }

        // Check general cache
        if let cachedURL = imageCache.object(forKey: keywords as NSString) {
            return cachedURL as String
        }

        // Clean up keywords for Unsplash search
        let searchQuery = keywords.replacingOccurrences(of: ",", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        // Use Unsplash API with access key and get multiple results for variety
        let urlString = "https://api.unsplash.com/search/photos?query=\(encodedQuery)&per_page=5&orientation=landscape&client_id=\(Secrets.unsplashAccessKey)"

        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Surface API problems (401 invalid key, 403 rate-limited, etc.)
            // instead of silently falling through to no image.
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                #if DEBUG
                let body = String(data: data, encoding: .utf8) ?? ""
                print("[Unsplash] HTTP \(http.statusCode): \(body.prefix(200))")
                #endif
                return nil
            }

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

            let unsplash = try JSONDecoder().decode(UnsplashResponse.self, from: data)

            if !unsplash.results.isEmpty {
                // Select a random photo from the results for more variety
                let randomIndex = Int.random(in: 0..<min(unsplash.results.count, 3))
                let selectedPhoto = unsplash.results[randomIndex]
                let imageURL = selectedPhoto.urls.small

                // Cache both by keywords and by question
                imageCache.setObject(imageURL as NSString, forKey: keywords as NSString)
                if question != nil {
                    questionImageCache.setObject(imageURL as NSString, forKey: cacheKey as NSString)
                }

                return imageURL
            }
        } catch {
            #if DEBUG
            print("Error fetching from Unsplash: \(error)")
            #endif
        }

        // No image found. Return nil so the card shows its gradient placeholder.
        // (The old source.unsplash.com fallback was removed — that service was
        // permanently shut down by Unsplash and always failed to load.)
        return nil
    }

    // Generate and fetch unique image for a flashcard
    func generateImageForFlashcard(question: String, topic: String) async -> String? {
        // Generate unique keywords using Gemini
        let keywords = await generateImageKeywords(for: question, topic: topic)

        // Fetch image using keywords and question for unique caching
        return await fetchImage(keywords: keywords, question: question)
    }

    /// Generates keywords and fetches an image, appending a per-index variation modifier
    /// (e.g. "close-up", "wide angle") so cards in the same topic get distinct images.
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
        imageCache.removeAllObjects()
        questionImageCache.removeAllObjects()
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
