//
//  TopicManagerIntegrationTests.swift
//  EdutokTests
//
//  Integration tests proving the generate->parse->fallback pipeline:
//  GeminiClient.generateText -> LLMJSON.extractJSONArray -> JSONDecoder.
//  Exercises the full path that TopicManager.fetchFlashcardsFromGemini uses
//  without needing @MainActor or singleton dependencies.
//

import Foundation
import Testing

@testable import Edutok

/// The decode type mirroring what TopicManager uses internally.
private struct FlashcardData: Codable {
    let type: String
    let question: String
    let answer: String
}

@Suite(.serialized)
struct TopicManagerIntegrationTests {

    // MARK: - Helpers

    private func makeClient() -> GeminiClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return GeminiClient(session: URLSession(configuration: config), apiKey: "test-key")
    }

    /// Wraps `body` in the Gemini response envelope that GeminiClient expects.
    private func geminiEnvelope(_ body: String) -> String {
        """
        {"candidates":[{"content":{"parts":[{"text":\(jsonEscaped(body))}]}}]}
        """
    }

    /// JSON-escapes a string value (wraps in quotes, escapes inner quotes/newlines).
    private func jsonEscaped(_ s: String) -> String {
        // swiftlint:disable:next force_try
        let data = try! JSONSerialization.data(withJSONObject: s)
        return String(data: data, encoding: .utf8) ?? "\"\(s)\""
    }

    private func respond(status: Int, body: String) {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
    }

    // MARK: - Pipeline tests (GeminiClient -> LLMJSON -> JSONDecoder)

    /// Valid JSON response decodes into flashcards correctly through the full pipeline.
    @Test func validJSONResponseProducesFlashcards() async throws {
        let flashcardsJSON = """
        [{"type":"definition","question":"What is photosynthesis?",\
        "answer":"The process by which plants convert light to energy."},\
        {"type":"question","question":"Where does photosynthesis occur?",\
        "answer":"In the chloroplasts of plant cells."}]
        """
        respond(status: 200, body: geminiEnvelope(flashcardsJSON))

        let client = makeClient()
        let rawText = try await client.generateText(prompt: "test", maxOutputTokens: 3000)
        let jsonText = LLMJSON.extractJSONArray(from: rawText)
        let data = jsonText.data(using: .utf8)!
        let cards = try JSONDecoder().decode([FlashcardData].self, from: data)

        #expect(cards.count == 2)
        #expect(cards[0].type == "definition")
        #expect(cards[0].question == "What is photosynthesis?")
        #expect(cards[1].type == "question")
        #expect(cards[1].answer == "In the chloroplasts of plant cells.")
    }

    /// Response wrapped in ```json fences is stripped and decoded successfully.
    @Test func markdownWrappedResponseIsStripped() async throws {
        let wrappedJSON = """
        ```json
        [{"type":"definition","question":"What is gravity?","answer":"A fundamental force of attraction."}]
        ```
        """
        respond(status: 200, body: geminiEnvelope(wrappedJSON))

        let client = makeClient()
        let rawText = try await client.generateText(prompt: "test", maxOutputTokens: 3000)
        let jsonText = LLMJSON.extractJSONArray(from: rawText)
        let data = jsonText.data(using: .utf8)!
        let cards = try JSONDecoder().decode([FlashcardData].self, from: data)

        #expect(cards.count == 1)
        #expect(cards[0].question == "What is gravity?")
        #expect(cards[0].answer == "A fundamental force of attraction.")
    }

    /// Smart quotes in response are normalized to ASCII and decoded.
    @Test func smartQuotesAreNormalized() async throws {
        let smartQuoteJSON = "[{\u{201C}type\u{201D}:\u{201C}definition\u{201D},"
            + "\u{201C}question\u{201D}:\u{201C}What is DNA?\u{201D},"
            + "\u{201C}answer\u{201D}:\u{201C}Deoxyribonucleic acid.\u{201D}}]"
        respond(status: 200, body: geminiEnvelope(smartQuoteJSON))

        let client = makeClient()
        let rawText = try await client.generateText(prompt: "test", maxOutputTokens: 3000)
        let jsonText = LLMJSON.extractJSONArray(from: rawText)
        let data = jsonText.data(using: .utf8)!
        let cards = try JSONDecoder().decode([FlashcardData].self, from: data)

        #expect(cards.count == 1)
        #expect(cards[0].type == "definition")
        #expect(cards[0].question == "What is DNA?")
        #expect(cards[0].answer == "Deoxyribonucleic acid.")
    }

    // MARK: - Error-path tests

    /// HTTP error causes GeminiClient to throw a typed error the caller can catch and fall back.
    @Test func httpErrorThrowsTypedError() async {
        respond(status: 429, body: #"{"error":"rate limited"}"#)
        let client = makeClient()

        await #expect(throws: APIError.httpStatus(429)) {
            try await client.generateText(prompt: "test", maxOutputTokens: 3000)
        }
    }

    /// Malformed/unparseable response causes a decoding error at the GeminiClient level.
    @Test func malformedJSONThrowsDecodingError() async {
        respond(status: 200, body: "this is not json at all")
        let client = makeClient()

        do {
            _ = try await client.generateText(prompt: "test", maxOutputTokens: 3000)
            Issue.record("expected a decoding error")
        } catch let error as APIError {
            if case .decoding = error { /* expected */ } else {
                Issue.record("expected .decoding, got \(error)")
            }
        } catch {
            Issue.record("expected APIError, got \(error)")
        }
    }

    /// Empty candidates array causes an emptyResponse error.
    @Test func emptyCandidatesThrowsEmptyResponse() async {
        respond(status: 200, body: #"{"candidates":[]}"#)
        let client = makeClient()

        await #expect(throws: APIError.emptyResponse) {
            try await client.generateText(prompt: "test", maxOutputTokens: 3000)
        }
    }
}
