import XCTest
import UIKit
#if canImport(StudioLocal)
@testable import StudioLocal
#endif

final class PixelRendererTests: XCTestCase {
    func testNativePixelsUseIntegerEnlargementAndTransparentPadding() throws {
        var document = PixelDocument()
        document.pixels[0] = 6
        document.pixels[255] = 8
        let image = try XCTUnwrap(PixelRenderer.image(for: document).cgImage)
        XCTAssertEqual(image.width, 300)
        XCTAssertEqual(image.height, 300)
        XCTAssertFalse(image.shouldInterpolate)
        let data = try XCTUnwrap(image.dataProvider?.data) as Data
        func rgba(_ x: Int, _ y: Int) -> [UInt8] {
            let offset = y * image.bytesPerRow + x * 4
            return Array(data[offset..<(offset + 4)])
        }
        XCTAssertEqual(rgba(0, 0), [0, 0, 0, 0])
        XCTAssertEqual(rgba(5, 6), [0, 0, 0, 0])
        XCTAssertEqual(rgba(6, 6), [245, 77, 102, 255])
        XCTAssertEqual(rgba(23, 23), [245, 77, 102, 255])
        XCTAssertEqual(rgba(24, 6), [0, 0, 0, 0])
        XCTAssertEqual(rgba(293, 293), [69, 138, 255, 255])
        XCTAssertEqual(rgba(294, 293), [0, 0, 0, 0])
        XCTAssertEqual(rgba(299, 299), [0, 0, 0, 0])
    }

    func testPNGDimensionsAndLimit() throws {
        var document = PixelDocument()
        document.pixels[34] = 3
        let rawData = try PixelRenderer.pngData(for: document, raw: true)
        let nativeData = try PixelRenderer.pngData(for: document)
        XCTAssertEqual(UIImage(data: rawData)?.cgImage?.width, 16)
        XCTAssertEqual(UIImage(data: rawData)?.cgImage?.height, 16)
        XCTAssertEqual(UIImage(data: nativeData)?.cgImage?.width, 300)
        XCTAssertEqual(UIImage(data: nativeData)?.cgImage?.height, 300)
        XCTAssertLessThan(nativeData.count, 500_000)
    }

    func testBlankInsertionExportIsRejected() throws {
        XCTAssertThrowsError(try PixelRenderer.exportURL(for: PixelDocument())) { error in
            XCTAssertEqual((error as? PixelRendererError)?.errorDescription, PixelRendererError.emptyDrawing.errorDescription)
        }
    }

    func testExportFileIsStableAndOldRenderSurvivesChanges() throws {
        var document = PixelDocument()
        document.pixels[0] = 3
        let firstURL = try PixelRenderer.exportURL(for: document)
        defer { try? FileManager.default.removeItem(at: firstURL) }
        XCTAssertEqual(try PixelRenderer.exportURL(for: document), firstURL)
        document.pixels[1] = 6
        let nextURL = try PixelRenderer.exportURL(for: document)
        defer { try? FileManager.default.removeItem(at: nextURL) }
        XCTAssertNotEqual(nextURL, firstURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: nextURL.path))
    }
}
