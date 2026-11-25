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
        #if STUDIO_BETA_TESTING
        XCTAssertEqual(app.buttons["studio.unlock"].label, "Enable Studio for this beta")
        #else
        XCTAssertTrue(app.buttons["studio.unlock"].label.contains("$1.00"))
        #endif
        saveScreenshot("01-local-unlock")
        app.buttons["studio.freeStickers"].tap()
        XCTAssertTrue(app.staticTexts["catalog-count"].waitForExistence(timeout: 5))
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
        app.buttons["Insert Pixel pal"].tap()
        XCTAssertTrue(app.alerts["Sticker ready"].waitForExistence(timeout: 5))
        app.alerts["Sticker ready"].buttons["OK"].tap()
        XCTAssertTrue(app.buttons["Open drawing Pixel pal"].exists)
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

    func testStudioTemplateBrowserContinuesWithSelectedRemix() {
        app.buttons["studio.tab.studio"].tap()
        let browse = app.buttons["studio.allTemplates"]
        XCTAssertTrue(browse.waitForExistence(timeout: 5))
        XCTAssertEqual(browse.label, "Browse all 45 templates")
        browse.tap()
        app.buttons["studio.template.tiny_bunny"].tap()
        let preview = app.descendants(matching: .any)["studio.recolorPreview"].firstMatch
        let chosenPreview = expectation(for: NSPredicate(format: "label CONTAINS %@", "A little shy"), evaluatedWith: preview)
        wait(for: [chosenPreview], timeout: 5)
        app.buttons["studio.unlock"].tap()
        let name = app.textFields["studio.drawingName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "A little shy remix")
        app.buttons["studio.backToDrafts"].tap()
        app.buttons["studio.template.tiny_duck"].tap()
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        XCTAssertEqual(name.value as? String, "Just a lil guy remix")
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

extension StudioFlowTests {
    func testCompactOptionsFiltersAndSearchSurviveMessagesExpansion() {
        app.terminate()
        app.launchEnvironment["STUDIO_UI_TEST_COMPACT"] = "1"
        app.launch()
        let options = app.buttons["options-exclamation_point_01"]
        XCTAssertTrue(options.waitForExistence(timeout: 5))

        options.tap()
        app.buttons["Details"].tap()
        XCTAssertTrue(app.buttons["insert-included-sticker"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        options.tap()
        app.buttons["Favorite"].tap()

        app.buttons["studio.filters"].tap()
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Favorites only")).firstMatch.tap()
        let count = app.staticTexts["catalog-count"]
        XCTAssertEqual(count.label, "1 sticker")

        let search = app.textFields["studio.search"]
        search.tap()
        search.typeText("surp")
        finishSearch()
        XCTAssertEqual(count.label, "1 sticker")
        app.buttons["testHost.finishExpansion"].tap()
        XCTAssertTrue(app.buttons["preview-exclamation_point_01"].waitForExistence(timeout: 5))
        XCTAssertEqual(search.value as? String, "surp")
        XCTAssertEqual(app.buttons["favorites-filter"].value as? String, "Favorites only")
        XCTAssertEqual(count.label, "1 sticker")
    }
}
