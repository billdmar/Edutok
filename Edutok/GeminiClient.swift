/// GeminiClient.swift
///
/// Small networking layer for Google's Gemini generative-language REST API. Both
/// `TopicManager` (flashcard generation) and `ImageManager` (image-search keywords)
/// previously duplicated the same URL construction, request body, status check, and
/// nested-response decoding; that logic now lives here behind one `generateText` call.
import Foundation

/// Typed errors for the app's network calls. Replaces the previous two-case
/// `APIError`, so callers (and tests) can distinguish failure modes.
enum APIError: Error, Equatable {
    case invalidURL
    case transport(String)
    case httpStatus(Int)
    case decoding(String)
    case emptyResponse
}

/// Stateless client for the Gemini `generateContent` endpoint.
struct GeminiClient {
    /// The single place the model id is defined (was hardcoded in two managers).
    static let model = "gemini-1.5-flash-latest"

    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = Secrets.geminiAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    private var endpoint: URL? {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(Self.model):generateContent?key=\(apiKey)")
    }

    /// Sends `prompt` to Gemini and returns the first candidate's text, trimmed.
    /// Throws a typed `APIError` on any failure so the caller can decide how to degrade.
    func generateText(
        prompt: String,
        maxOutputTokens: Int,
        temperature: Double = 0.7,
        topP: Double? = nil,
        timeout: TimeInterval = 20
    ) async throws -> String {
        guard let url = endpoint else { throw APIError.invalidURL }

        var generationConfig: [String: Any] = [
            "temperature": temperature,
            "maxOutputTokens": maxOutputTokens
        ]
        if let topP { generationConfig["topP"] = topP }

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": generationConfig
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        if let status = (response as? HTTPURLResponse)?.statusCode, status != 200 {
            throw APIError.httpStatus(status)
        }

        let decoded: GeminiResponse
        do {
            decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }

        guard let text = decoded.candidates.first?.content.parts.first?.text else {
            throw APIError.emptyResponse
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Response shape

    private struct GeminiResponse: Decodable {
        let candidates: [Candidate]
        struct Candidate: Decodable {
            let content: Content
            struct Content: Decodable {
                let parts: [Part]
                struct Part: Decodable { let text: String }
            }
        }
    }
}

// MARK: - JSON extraction (pure + testable)

enum LLMJSON {
    /// Strips markdown code fences and smart quotes from an LLM reply, then narrows the
    /// text to the outermost `[ ... ]` array so it can be decoded. Pure — unit-tested in
    /// `EdutokTests`. (Previously a private method on `TopicManager`.)
    static func extractJSONArray(from text: String) -> String {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        cleaned = cleaned
            .replacingOccurrences(of: "\u{201C}", with: "\"") // “
            .replacingOccurrences(of: "\u{201D}", with: "\"") // ”
            .replacingOccurrences(of: "\u{2018}", with: "'")  // ‘
            .replacingOccurrences(of: "\u{2019}", with: "'")  // ’

        if let start = cleaned.firstIndex(of: "["),
           let end = cleaned.lastIndex(of: "]") {
            return String(cleaned[start...end])
        }
        return cleaned
    }
}
