import XCTest
import StoreKitTest

/// Captures the actual custom Messages extension using public offer/UI copy.
/// Its separately compiled Screenshots configuration can use only verified Xcode
/// StoreKit transactions, and is excluded from the App Store archive.
final class StudioReleaseScreenshotTests: XCTestCase {
    private let messages = XCUIApplication(bundleIdentifier: "com.apple.MobileSMS")

    @available(iOS 17.0, *)
    @MainActor
    func testCapturePublicStudioFlow() async throws {
        continueAfterFailure = false
        // TEST_TARGET_NAME must be StudioMessagesHost so the test transaction
        // belongs to this app instead of an unrelated unhosted runner.
        let store = try SKTestSession(configurationFileNamed: "Studio")
        store.resetToDefaultState()
        store.clearTransactions()
        store.disableDialogs = true
        store.askToBuyEnabled = false
        store.storefront = "USA"
        store.locale = Locale(identifier: "en_US")
        defer { store.clearTransactions() }

        openStudioInFixture()
        messages.buttons["studio.tab.studio"].tap()
        XCTAssertFalse(messages.staticTexts["Your tiny ideas"].waitForExistence(timeout: 1),
                       "Use a fresh dedicated capture simulator; existing drawings will not be deleted")
        XCTAssertTrue(messages.buttons["studio.tab.collection"].waitForExistence(timeout: 5), messages.debugDescription)
        messages.buttons["studio.tab.collection"].tap()
        XCTAssertEqual(messages.staticTexts["catalog-count"].label, "67 stickers")
        XCTAssertFalse(messages.staticTexts["studio.localTestingNotice"].exists)
        capture("01-free-stickers")

        search("67")
        XCTAssertEqual(messages.staticTexts["catalog-count"].label, "5 stickers")
        capture("02-six-seven-reactions")

        search("Henlo")
        messages.buttons["preview-tiny_frog"].tap()
        XCTAssertTrue(messages.buttons["remix-sticker"].waitForExistence(timeout: 5))
        messages.buttons["remix-sticker"].tap()
        let unlock = messages.buttons["studio.unlock"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 10), messages.debugDescription)
        let priceReady = NSPredicate(format: "label CONTAINS %@ AND enabled == true", "$1.00")
        let loaded = expectation(for: priceReady, evaluatedWith: unlock)
        await fulfillment(of: [loaded], timeout: 25)
        XCTAssertFalse(messages.staticTexts["studio.localTestingNotice"].exists)
        capture("review-studio-unlock")
        unlock.tap()
        XCTAssertTrue(canvas.waitForExistence(timeout: 20), messages.debugDescription)
        print("CAPTURE_CHECKOUT_UI_COMPLETED")
        rename("Pixel pal")
        capture("03-pixel-studio")
        messages.buttons["studio.backToDrafts"].tap()

        makeRemix(id: "tiny_cat", query: "Tiny hug", name: "Pocket hug")
        makeRemix(id: "tiny_duck", query: "Just a lil guy", name: "Just vibing")
        XCTAssertTrue(messages.buttons["Open drawing Pixel pal"].waitForExistence(timeout: 5))
        capture("04-saved-drafts")
        XCTAssertFalse(store.allTransactions().isEmpty, "Captures must follow a real Xcode StoreKit transaction")
        // No insertion or Messages Send action is performed by this capture flow.
    }

    private var canvas: XCUIElement { messages.descendants(matching: .any)["studio.canvas"].firstMatch }

    private func openStudioInFixture() {
        messages.terminate()
        messages.launch()
        XCTAssertTrue(messages.wait(for: .runningForeground, timeout: 15))
        if messages.buttons["OK"].waitForExistence(timeout: 1) { messages.buttons["OK"].tap() }
        if messages.buttons["Continue"].exists { messages.buttons["Continue"].tap() }
        if messages.collectionViews["ConversationList"].exists {
            let fixture = messages.collectionViews["ConversationList"].cells.matching(NSPredicate(format: "label CONTAINS %@", "+1 (888) 555-1212")).firstMatch
            XCTAssertTrue(fixture.exists, "Use Apple's default simulator fixture, never a personal conversation")
            fixture.tap()
        }
        if messages.buttons["studio.tab.studio"].exists { return }
        if messages.buttons["add"].exists { messages.buttons["add"].tap() }
        else if messages.buttons["Apps"].exists { messages.buttons["Apps"].tap() }
        if messages.cells["8 bit art"].exists { messages.cells["8 bit art"].tap() }
        else if messages.buttons["8 bit art"].exists { messages.buttons["8 bit art"].tap() }
        else {
            if messages.cells["More"].exists { messages.cells["More"].tap() }
            else if messages.buttons["More"].exists { messages.buttons["More"].tap() }
            let entry = messages.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "8 bit art")).firstMatch
            XCTAssertTrue(entry.waitForExistence(timeout: 5), messages.debugDescription)
            entry.tap()
        }
        XCTAssertTrue(messages.buttons["studio.tab.studio"].waitForExistence(timeout: 10), messages.debugDescription)
    }

    private func search(_ query: String) {
        if messages.buttons["studio.tab.collection"].exists { messages.buttons["studio.tab.collection"].tap() }
        let field = messages.textFields["studio.search"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), messages.debugDescription)
        if messages.buttons["Clear search"].exists { messages.buttons["Clear search"].tap() }
        field.tap()
        field.typeText(query)
        finishKeyboard()
    }

    private func rename(_ title: String) {
        let field = messages.textFields["studio.drawingName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let text = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count))
        field.typeText(title + "\n")
        XCTAssertEqual(field.value as? String, title)
    }

    private func makeRemix(id: String, query: String, name: String) {
        search(query)
        messages.buttons["preview-\(id)"].tap()
        XCTAssertTrue(messages.buttons["remix-sticker"].waitForExistence(timeout: 5))
        messages.buttons["remix-sticker"].tap()
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        rename(name)
        messages.buttons["studio.backToDrafts"].tap()
    }

    private func finishKeyboard() {
        if messages.keyboards.buttons["Search"].exists { messages.keyboards.buttons["Search"].tap() }
        else if messages.keyboards.buttons["Return"].exists { messages.keyboards.buttons["Return"].tap() }
        else if messages.keyboards.buttons["Done"].exists { messages.keyboards.buttons["Done"].tap() }
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        // XCUIScreen can round physical width by one pixel. The host-side
        // test bridge asks simctl for the exact native screen at this same state.
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8793/capture")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("native-simctl", forHTTPHeaderField: "X-Studio-Capture")
        request.httpBody = try! JSONSerialization.data(withJSONObject: ["name": name])
        request.timeoutInterval = 25
        let finished = DispatchSemaphore(value: 0)
        var status = 0
        URLSession.shared.dataTask(with: request) { _, response, _ in
            status = (response as? HTTPURLResponse)?.statusCode ?? 0
            finished.signal()
        }.resume()
        XCTAssertEqual(finished.wait(timeout: .now() + 30), .success)
        XCTAssertEqual(status, 200, "Run captures through scripts/capture-studio-release.sh")
    }
}
