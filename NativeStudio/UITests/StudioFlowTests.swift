import XCTest

final class StudioFlowTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchEnvironment["STUDIO_UI_TESTING"] = "1"
        app.launchEnvironment["STUDIO_UI_TEST_RESET"] = "1"
        app.launch()
    }

    func testFreeCollectionSearchFavoritesAndDismissedUnlock() {
        XCTAssertTrue(app.staticTexts["catalog-count"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["catalog-count"].label, "67 stickers")
        let search = app.textFields["studio.search"]
        search.tap(); search.typeText("67")
        XCTAssertEqual(app.staticTexts["catalog-count"].label, "5 stickers")
        finishSearch()
        let favorite = app.buttons["favorite-tiny_six_seven_neon"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 5))
        favorite.tap()
        app.buttons["favorites-filter"].tap()
        XCTAssertEqual(app.staticTexts["catalog-count"].label, "1 sticker")
        app.terminate()
        app.launchEnvironment["STUDIO_UI_TEST_RESET"] = "0"
        app.launch()
        app.buttons["favorites-filter"].tap()
        XCTAssertEqual(app.staticTexts["catalog-count"].label, "1 sticker")
        app.buttons["studio.tab.studio"].tap()
        app.buttons["studio.newDrawing"].tap()
        XCTAssertTrue(app.buttons["studio.unlock"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["studio.unlock"].label.contains("$1.00"))
        saveScreenshot("01-local-unlock")
        app.buttons["Not now"].tap()
        app.buttons["studio.tab.collection"].tap()
        XCTAssertTrue(app.staticTexts["catalog-count"].exists)
    }

    func testUnlockRemixAutosaveInsertAndReopen() {
        let search = app.textFields["studio.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap(); search.typeText("Henlo")
        finishSearch()
        app.buttons["preview-tiny_frog"].tap()
        app.buttons["remix-sticker"].tap()
        XCTAssertTrue(app.buttons["studio.unlock"].waitForExistence(timeout: 5))
        app.buttons["studio.unlock"].tap()
        let name = app.textFields["studio.drawingName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "Unlock should continue directly into the requested remix")
        name.tap()
        let existing = name.value as? String ?? ""
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        name.typeText("Pixel pal\n")
        let canvas = app.descendants(matching: .any)["studio.canvas"].firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        XCTAssertTrue(app.buttons["studio.undo"].isEnabled)
        app.buttons["studio.undo"].tap()
        XCTAssertTrue(app.buttons["studio.redo"].isEnabled)
        saveScreenshot("02-native-editor")
        app.buttons["studio.insert"].tap()
        XCTAssertTrue(app.alerts["Sticker ready"].waitForExistence(timeout: 5))
        app.alerts["Sticker ready"].buttons["OK"].tap()
        app.buttons["studio.backToDrafts"].tap()
        XCTAssertTrue(app.buttons["Open drawing Pixel pal"].waitForExistence(timeout: 3))
        saveScreenshot("03-saved-drafts")
        app.terminate()
        app.launchEnvironment["STUDIO_UI_TEST_RESET"] = "0"
        app.launch()
        app.buttons["studio.tab.studio"].tap()
        XCTAssertTrue(app.buttons["Open drawing Pixel pal"].waitForExistence(timeout: 5))
        app.buttons["Open drawing Pixel pal"].tap()
        XCTAssertEqual(app.textFields["studio.drawingName"].value as? String, "Pixel pal")
        XCTAssertTrue(app.buttons["studio.insert"].isEnabled)
    }

    private func finishSearch() {
        if app.keyboards.buttons["Search"].exists { app.keyboards.buttons["Search"].tap() }
        else if app.keyboards.buttons["Return"].exists { app.keyboards.buttons["Return"].tap() }
    }
    private func saveScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
