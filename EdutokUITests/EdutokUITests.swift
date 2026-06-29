//
//  EdutokUITests.swift
//  EdutokUITests
//
//  Offline smoke suite. The app shows a deterministic mock flashcard deck even with the
//  CI stub API keys (Gemini fails → createEnhancedMockFlashcards; images → gradient
//  placeholder), so these tests need no real network or auth. They assert the core
//  navigation and the topic → flashcard happy path via stable accessibility identifiers
//  and the card's accessibility label.
//

import XCTest

final class EdutokUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    func testAppLaunchesToForeground() throws {
        let app = launchedApp()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    @MainActor
    func testMainScreenShowsTopicFieldAndStartButton() throws {
        let app = launchedApp()
        XCTAssertTrue(app.textFields["topicField"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["startLearningButton"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testStartLearningShowsAFlashcard() throws {
        let app = launchedApp()

        let topicField = app.textFields["topicField"]
        XCTAssertTrue(topicField.waitForExistence(timeout: 5))
        topicField.tap()
        topicField.typeText("Biology")

        app.buttons["startLearningButton"].tap()

        // The card view exposes an accessibility label "<Type> flashcard. Question: …"
        // (added with the VoiceOver work). A mock deck always appears, even offline.
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "flashcard"))
            .firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10),
                      "A flashcard should appear after Start Learning (mock deck offline).")
    }

    @MainActor
    func testTappingFlashcardRevealsAnswer() throws {
        let app = launchedApp()

        let topicField = app.textFields["topicField"]
        XCTAssertTrue(topicField.waitForExistence(timeout: 5))
        topicField.tap()
        topicField.typeText("Biology")
        app.buttons["startLearningButton"].tap()

        // The current card is a combined, tappable .isButton whose accessibility label
        // shows the Question side first.
        let questionSide = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Question:"))
            .firstMatch
        XCTAssertTrue(questionSide.waitForExistence(timeout: 10),
                      "The card should start on its question side.")

        questionSide.tap()

        // After the flip, the card announces the Answer side. The first mock card's answer
        // contains this stable substring (TopicManager.createEnhancedMockFlashcards).
        let answerSide = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "core mechanism involves"))
            .firstMatch
        XCTAssertTrue(answerSide.waitForExistence(timeout: 5),
                      "Tapping the card should flip it to reveal the answer.")
    }

    @MainActor
    func testMenuOpensSidebar() throws {
        let app = launchedApp()
        let menu = app.buttons["menuButton"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        // The "Close menu" button only exists inside the open sidebar, so it's a reliable
        // proxy for "the sidebar is showing" (container identifiers don't always surface
        // as queryable otherElements).
        XCTAssertTrue(app.buttons["Close menu"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testNavBarSwitchesSections() throws {
        let app = launchedApp()
        // Nav buttons carry accessibility labels (Leaderboard / Learn / Calendar). Use
        // .firstMatch because a section's content may also surface a matching label.
        let leaderboard = app.buttons["Leaderboard"].firstMatch
        XCTAssertTrue(leaderboard.waitForExistence(timeout: 5))

        leaderboard.tap()
        app.buttons["Calendar"].firstMatch.tap()
        app.buttons["Learn"].firstMatch.tap()

        // Back on the Learn screen, the topic field is present again.
        XCTAssertTrue(app.textFields["topicField"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
