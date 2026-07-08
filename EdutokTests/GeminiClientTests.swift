//
//  GeminiClientTests.swift
//  EdutokTests
//
//  Networking tests for GeminiClient with a stubbed URLProtocol.
//

import Foundation
import Testing

@testable import Edutok

/// A `URLProtocol` that returns a canned response, so `GeminiClient` can be exercised
/// without a real network. Each test sets `StubURLProtocol.handler` before constructing
/// its session; `.serialized` on the suite avoids cross-test handler races.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@Suite(.serialized)
struct GeminiClientTests {
    private func makeClient() -> GeminiClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return GeminiClient(session: URLSession(configuration: config), apiKey: "test-key")
    }

    private func respond(status: Int, body: String) {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
    }

    @Test func returnsTrimmedTextOnValidResponse() async throws {
        respond(status: 200, body: """
        {"candidates":[{"content":{"parts":[{"text":"  hello world  "}]}}]}
        """)
        let client = makeClient()
        let text = try await client.generateText(prompt: "p", maxOutputTokens: 10)
        #expect(text == "hello world")
    }

    @Test func throwsHttpStatusOnNon200() async {
        respond(status: 503, body: "{}")
        let client = makeClient()
        await #expect(throws: APIError.httpStatus(503)) {
            try await client.generateText(prompt: "p", maxOutputTokens: 10)
        }
    }

    @Test func throwsEmptyResponseWhenNoCandidates() async {
        respond(status: 200, body: #"{"candidates":[]}"#)
        let client = makeClient()
        await #expect(throws: APIError.emptyResponse) {
            try await client.generateText(prompt: "p", maxOutputTokens: 10)
        }
    }

    @Test func throwsDecodingOnMalformedJSON() async {
        respond(status: 200, body: "not json at all")
        let client = makeClient()
        // .decoding carries a message string, so match the case rather than equality.
        do {
            _ = try await client.generateText(prompt: "p", maxOutputTokens: 10)
            Issue.record("expected a decoding error")
        } catch let error as APIError {
            if case .decoding = error { } else {
                Issue.record("expected .decoding, got \(error)")
            }
        } catch {
            Issue.record("expected APIError, got \(error)")
        }
    }
}
