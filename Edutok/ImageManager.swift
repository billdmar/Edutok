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

    // Decoded-image cache so a card scrolling back into view doesn't re-download and
    // re-decode its photo. Bounded; NSCache also evicts under memory pressure.
    private let decodedImageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120
        return cache
    }()

    private let geminiClient = GeminiClient()

    /// Asks Gemini for specific, visual search keywords describing the question.
    /// Always returns a usable string: on any failure (bad URL, non-200, decode/network
    /// error) it returns a fallback derived from the topic and question text.
    func generateImageKeywords(for question: String, topic: String) async -> String {
        // Enhanced fallback that includes question content for more variety.
        // Computed up front so any failure path can return it.
        let fallbackKeywords = "\(topic), \(question.prefix(50))".replacingOccurrences(of: "?", with: "").replacingOccurrences(of: "What", with: "").replacingOccurrences(of: "How", with: "").replacingOccurrences(of: "Why", with: "")

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

        do {
            let keywords = try await geminiClient.generateText(prompt: prompt, maxOutputTokens: 100)
            return keywords.isEmpty ? fallbackKeywords : keywords
        } catch {
            #if DEBUG
            print("Error generating keywords: \(error)")
            #endif
            return fallbackKeywords
        }
    }

    /// Searches Unsplash for the given keywords and returns a small-resolution image URL,
    /// caching the result by keywords (and by question when provided). Returns `nil` when
    /// the request is rate-limited/unauthorized, errors, or yields no results.
    func fetchImage(keywords: String, question: String? = nil) async -> String? {
        // Create a unique cache key that includes both keywords and question
        let cacheKey = question.map { "\(keywords)_\($0.prefix(30))" } ?? keywords

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

    /// Returns the decoded image for a URL, caching the result so repeated appearances
    /// (e.g. scrolling a card back into view) don't re-download or re-decode. The download
    /// and `UIImage(data:)` decode run off the main thread; only the cache read/write and
    /// return happen on the main actor. Returns `nil` on bad URL, network error, or decode
    /// failure (caller falls back to its gradient placeholder).
    func image(for urlString: String) async -> UIImage? {
        let key = urlString as NSString
        if let cached = decodedImageCache.object(forKey: key) {
            return cached
        }
        guard let url = URL(string: urlString) else { return nil }

        let decoded: UIImage? = await Task.detached(priority: .userInitiated) {
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse).map({ $0.statusCode == 200 }) ?? true else {
                return nil
            }
            return UIImage(data: data)
        }.value

        if let decoded {
            decodedImageCache.setObject(decoded, forKey: key)
        }
        return decoded
    }

    // Clear cache to free memory
    func clearCache() {
        imageCache.removeAllObjects()
        questionImageCache.removeAllObjects()
        decodedImageCache.removeAllObjects()
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
        guard let urlString = url else {
            isLoading = false
            return
        }

        Task { @MainActor in
            // Routed through ImageManager's decoded-image cache, so a card returning to
            // screen reuses the cached UIImage instead of re-downloading.
            let loaded = await ImageManager.shared.image(for: urlString)
            withAnimation(.easeIn(duration: 0.3)) {
                self.image = loaded
                self.isLoading = false
            }
        }
    }
}
