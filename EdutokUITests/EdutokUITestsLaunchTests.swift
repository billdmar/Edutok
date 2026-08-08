//
//  EdutokUITestsLaunchTests.swift
//  EdutokUITests
//
//  Created by Bill Mar on 8/5/25.
//

import XCTest

final class EdutokUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the app reaches the foreground on launch.
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
