import XCTest
#if canImport(StudioLocal)
@testable import StudioLocal
#endif

@MainActor
final class DraftStoreTests: XCTestCase {
    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("StudioTests-\(UUID().uuidString)", isDirectory: true)
    }

    func testMultipleDraftsAndFavoritesSurviveNewStore() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DraftStore(directory: directory)
        var first = PixelDocument(title: "First", createdAt: Date(timeIntervalSinceReferenceDate: 100))
        first.pixels[12] = 3
        let second = PixelDocument(title: "Second", createdAt: Date(timeIntervalSinceReferenceDate: 200))
        try store.save(first)
        try store.save(second)
        store.toggleFavorite("tiny_frog")
        let restored = DraftStore(directory: directory)
        XCTAssertEqual(restored.drafts.map(\.id), [second.id, first.id])
        XCTAssertEqual(restored.document(id: first.id), first)
        XCTAssertEqual(restored.favorites, ["tiny_frog"])
        XCTAssertNil(restored.errorMessage)
    }

    func testDuplicateCreatesIndependentDocumentAndDeletePersists() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DraftStore(directory: directory)
        var original = PixelDocument(title: "Tiny star")
        original.pixels[0] = 3
        try store.save(original)
        var copy = try store.duplicate(original)
        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.pixels, original.pixels)
        copy.pixels[0] = 6
        try store.save(copy)
        XCTAssertEqual(store.document(id: original.id)?.pixels[0], 3)
        try store.delete(id: copy.id)
        XCTAssertEqual(DraftStore(directory: directory).drafts.map(\.id), [original.id])
    }

    func testCorruptDraftIsPreservedAndOtherDraftStillLoads() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DraftStore(directory: directory)
        let valid = PixelDocument(title: "Keep me")
        try store.save(valid)
        let brokenData = Data("not valid JSON".utf8)
        let brokenURL = directory.appendingPathComponent("Drafts/\(UUID().uuidString).json")
        try brokenData.write(to: brokenURL)
        let restored = DraftStore(directory: directory)
        XCTAssertEqual(restored.drafts.map(\.id), [valid.id])
        XCTAssertNotNil(restored.errorMessage)
        XCTAssertFalse(FileManager.default.fileExists(atPath: brokenURL.path))
        let recoveryFiles = try FileManager.default.contentsOfDirectory(at: restored.recoveryDirectory, includingPropertiesForKeys: nil)
        XCTAssertEqual(recoveryFiles.count, 1)
        XCTAssertEqual(try Data(contentsOf: recoveryFiles[0]), brokenData)
    }

    func testInvalidSaveDoesNotReplacePreviouslySavedDrawing() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DraftStore(directory: directory)
        var document = PixelDocument(title: "Safe")
        try store.save(document)
        document.pixels = [999]
        XCTAssertThrowsError(try store.save(document))
        XCTAssertEqual(store.document(id: document.id)?.pixels.count, 256)
        XCTAssertEqual(DraftStore(directory: directory).document(id: document.id)?.pixels.count, 256)
        XCTAssertNotNil(store.errorMessage)
    }

    func testStorageFailureDoesNotClaimSuccessfulSave() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let blocker = directory.appendingPathComponent("blocked")
        try Data("file, not a folder".utf8).write(to: blocker)
        let store = DraftStore(directory: blocker)
        XCTAssertThrowsError(try store.save(PixelDocument()))
        XCTAssertTrue(store.drafts.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    func testFavoritesFailureKeepsPriorSelection() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = DraftStore(directory: directory)
        store.toggleFavorite("tiny_frog")
        let favoritesFile = directory.appendingPathComponent("favorites.json")
        try FileManager.default.removeItem(at: favoritesFile)
        try FileManager.default.createDirectory(at: favoritesFile, withIntermediateDirectories: true)
        store.toggleFavorite("tiny_cat")
        XCTAssertEqual(store.favorites, ["tiny_frog"])
        XCTAssertNotNil(store.errorMessage)
    }
}
