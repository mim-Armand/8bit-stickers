import XCTest

final class MessagesStudioTests: XCTestCase {
    func testStudioOpensInsideMessages() {
        continueAfterFailure = false
        let messages = XCUIApplication(bundleIdentifier: "com.apple.MobileSMS")
        messages.launch()
        if messages.buttons["OK"].waitForExistence(timeout: 1) { messages.buttons["OK"].tap() }
        if messages.buttons["Continue"].exists { messages.buttons["Continue"].tap() }
        if messages.collectionViews["ConversationList"].exists {
            let fixture = messages.collectionViews["ConversationList"].cells.matching(NSPredicate(format: "label CONTAINS %@", "+1 (888) 555-1212")).firstMatch
            XCTAssertTrue(fixture.exists, "Use the default simulator fixture, not a personal conversation")
            fixture.tap()
        }
        if messages.buttons["studio.tab.studio"].exists {
            // Already open from a previous local test.
        } else {
            if messages.buttons["add"].exists { messages.buttons["add"].tap() }
            else if messages.buttons["Apps"].exists { messages.buttons["Apps"].tap() }
            print("STUDIO_MENU\n\(messages.debugDescription)")
            if messages.cells["8 bit art"].exists { messages.cells["8 bit art"].tap() }
            else if messages.buttons["8 bit art"].exists { messages.buttons["8 bit art"].tap() }
            else {
                if messages.cells["More"].exists { messages.cells["More"].tap() }
                else if messages.buttons["More"].exists { messages.buttons["More"].tap() }
                let appEntry = messages.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "8 bit art")).firstMatch
                XCTAssertTrue(appEntry.waitForExistence(timeout: 5), messages.debugDescription)
                appEntry.tap()
            }
        }
        XCTAssertTrue(messages.buttons["studio.tab.studio"].waitForExistence(timeout: 10), messages.debugDescription)
        messages.buttons["studio.tab.studio"].tap()
        if messages.buttons["studio.newDrawing"].waitForExistence(timeout: 3) {
            messages.buttons["studio.newDrawing"].tap()
        }
        if messages.buttons["studio.unlock"].waitForExistence(timeout: 3) { messages.buttons["studio.unlock"].tap() }
        XCTAssertTrue(messages.descendants(matching: .any)["studio.canvas"].firstMatch.waitForExistence(timeout: 8), messages.debugDescription)
        let capture = XCTAttachment(screenshot: messages.screenshot())
        capture.name = "04-studio-inside-messages"; capture.lifetime = .keepAlways; add(capture)
        let canvas = messages.descendants(matching: .any)["studio.canvas"].firstMatch
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let insert = messages.buttons["studio.insert"]
        XCTAssertTrue(insert.isEnabled)
        insert.tap()
        let send = messages.buttons["Send"]
        XCTAssertTrue(send.waitForExistence(timeout: 5), messages.debugDescription)
        XCTAssertTrue(send.isEnabled, "The created sticker must be present in the composer")
        // This test never taps Messages' Send button.
    }
}
