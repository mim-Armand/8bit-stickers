import XCTest
#if canImport(StudioLocal)
@testable import StudioLocal
#endif

final class PixelDocumentTests: XCTestCase {
    func testNewDocumentHasExactly256TransparentCells() throws {
        let document = PixelDocument()
        XCTAssertEqual(document.width, 16)
        XCTAssertEqual(document.height, 16)
        XCTAssertEqual(document.pixels.count, 256)
        XCTAssertEqual(document.palette.first, .clear)
        XCTAssertTrue(document.isEmpty)
        XCTAssertNoThrow(try document.validate())
    }

    func testValidationRejectsUnsupportedOrCorruptedDocuments() throws {
        var document = PixelDocument()
        document.schemaVersion = 2
        XCTAssertThrowsError(try document.validate()) { XCTAssertEqual($0 as? PixelDocumentError, .unsupportedVersion) }
        document.schemaVersion = 1
        document.width = 32
        XCTAssertThrowsError(try document.validate()) { XCTAssertEqual($0 as? PixelDocumentError, .invalidDimensions) }
        document.width = 16
        document.pixels[0] = document.palette.count
        XCTAssertThrowsError(try document.validate()) { XCTAssertEqual($0 as? PixelDocumentError, .invalidPixels) }
        document.pixels[0] = 0
        document.palette[0] = PixelColor(r: 255, g: 255, b: 255)
        XCTAssertThrowsError(try document.validate()) { XCTAssertEqual($0 as? PixelDocumentError, .invalidPalette) }
    }

    func testValidationRejectsIncorrectCellCountAndTitle() {
        var document = PixelDocument()
        document.pixels.removeLast()
        XCTAssertThrowsError(try document.validate())
        document.pixels.append(0)
        document.title = "   "
        XCTAssertThrowsError(try document.validate()) { XCTAssertEqual($0 as? PixelDocumentError, .invalidTitle) }
        document.title = String(repeating: "a", count: 61)
        XCTAssertThrowsError(try document.validate())
    }

    func testCodableRoundTripPreservesPaletteCellsAndIdentity() throws {
        var document = PixelDocument(title: "My tiny frog", createdAt: Date(timeIntervalSinceReferenceDate: 12345.125))
        document.templateID = "tiny_frog"
        document.palette.append(PixelColor(r: 4, g: 70, b: 234, a: 128))
        document.pixels[255] = document.palette.count - 1
        let restored = try JSONDecoder().decode(PixelDocument.self, from: JSONEncoder().encode(document))
        XCTAssertEqual(restored, document)
        XCTAssertFalse(restored.isEmpty)
    }
}
