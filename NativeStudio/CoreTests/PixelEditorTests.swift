import XCTest
#if canImport(StudioLocal)
@testable import StudioLocal
#endif

@MainActor
final class PixelEditorTests: XCTestCase {
    func testFastStrokeInterpolatesAndIsOneUndoOperation() {
        let editor = PixelEditor(document: PixelDocument())
        editor.selectedColor = 6
        editor.beginStroke()
        editor.paint(x: 0, y: 0)
        editor.paint(x: 15, y: 15)
        editor.endStroke()
        XCTAssertFalse(editor.isDrawingStroke)
        for coordinate in 0..<16 { XCTAssertEqual(editor.document.pixels[coordinate * 16 + coordinate], 6) }
        XCTAssertEqual(editor.document.pixels.filter { $0 != 0 }.count, 16)
        editor.undo()
        XCTAssertTrue(editor.document.isEmpty)
        XCTAssertFalse(editor.canUndo)
        XCTAssertTrue(editor.canRedo)
        editor.redo()
        XCTAssertEqual(editor.document.pixels.filter { $0 != 0 }.count, 16)
    }

    func testFillUsesFourNeighborsAndNoOpDoesNotAddHistory() {
        var document = PixelDocument()
        document.pixels = Array(repeating: 1, count: 256)
        document.pixels[0] = 0
        document.pixels[17] = 0 // Diagonal only: it must not be reached by the fill.
        let editor = PixelEditor(document: document)
        editor.tool = .fill
        editor.selectedColor = 3
        editor.beginStroke()
        editor.paint(x: 0, y: 0)
        editor.endStroke()
        XCTAssertEqual(editor.document.pixels[0], 3)
        XCTAssertEqual(editor.document.pixels[17], 0)
        editor.beginStroke()
        editor.paint(x: 0, y: 0)
        editor.endStroke()
        editor.undo()
        XCTAssertEqual(editor.document.pixels, document.pixels)
        XCTAssertFalse(editor.canUndo)
    }

    func testFillEntireCanvasEraserAndOutOfBoundsCoordinates() {
        let editor = PixelEditor(document: PixelDocument())
        editor.selectedColor = 4
        editor.tool = .fill
        editor.paint(x: 8, y: 8)
        editor.endStroke()
        XCTAssertEqual(Set(editor.document.pixels), [4])
        editor.tool = .eraser
        editor.beginStroke()
        editor.paint(x: 2, y: 2)
        editor.paint(x: 5, y: 2)
        editor.paint(x: -1, y: 30)
        editor.endStroke()
        XCTAssertEqual(editor.document.pixels.filter { $0 == 0 }.count, 4)
        editor.undo()
        XCTAssertEqual(Set(editor.document.pixels), [4])
    }

    func testNewEditClearsRedoAndEmptyClearIsNoOp() {
        let editor = PixelEditor(document: PixelDocument())
        editor.clear()
        XCTAssertFalse(editor.canUndo)
        editor.paint(x: 0, y: 0)
        editor.endStroke()
        editor.undo()
        XCTAssertTrue(editor.canRedo)
        editor.paint(x: 1, y: 0)
        editor.endStroke()
        XCTAssertFalse(editor.canRedo)
        editor.clear()
        XCTAssertTrue(editor.document.isEmpty)
        editor.undo()
        XCTAssertEqual(editor.document.pixels[1], 1)
    }

    func testHistoryIsLimitedToFiftyCompletedStrokes() {
        let editor = PixelEditor(document: PixelDocument())
        for index in 0..<60 {
            editor.selectedColor = index.isMultiple(of: 2) ? 1 : 2
            editor.paint(x: 0, y: 0)
            editor.endStroke()
        }
        var count = 0
        while editor.canUndo {
            editor.undo()
            count += 1
        }
        XCTAssertEqual(count, 50)
        XCTAssertEqual(editor.document.pixels[0], 2)
    }

    func testRenameNormalizesAndCanBeUndoneWithoutChangingPixels() {
        let editor = PixelEditor(document: PixelDocument())
        editor.rename("   Hello pixels   ")
        XCTAssertEqual(editor.document.title, "Hello pixels")
        editor.undo()
        XCTAssertEqual(editor.document.title, "Untitled sticker")
        editor.rename(String(repeating: "x", count: 90))
        XCTAssertEqual(editor.document.title.count, 60)
        XCTAssertTrue(editor.document.isEmpty)
    }
}
