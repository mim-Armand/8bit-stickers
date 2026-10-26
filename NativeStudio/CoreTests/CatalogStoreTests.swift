import XCTest
import UIKit
#if canImport(StudioLocal)
@testable import StudioLocal
#endif

@MainActor
final class CatalogStoreTests: XCTestCase {
    func testBundledCatalogueIncludesAll67WithoutWine() throws {
        let catalog = CatalogStore()
        XCTAssertNil(catalog.errorMessage)
        XCTAssertEqual(catalog.items.count, 67)
        XCTAssertEqual(Set(catalog.items.map(\.id)).count, 67)
        XCTAssertEqual(catalog.items.filter { $0.category == "Originals" }.count, 10)
        XCTAssertEqual(catalog.items.filter { $0.category == "Cute" }.count, 12)
        XCTAssertEqual(catalog.items.filter { $0.category == "Memes" }.count, 33)
        XCTAssertFalse(catalog.items.contains { $0.id.contains("wine") })
        for item in catalog.items {
            XCTAssertTrue(FileManager.default.fileExists(atPath: item.resourceURL.path), "Missing resource for \(item.id)")
            XCTAssertLessThan(try Data(contentsOf: item.resourceURL).count, 500_000)
        }
    }

    func testAll45RemixTemplatesRetainExactNativePixels() throws {
        let catalog = CatalogStore()
        let templates = catalog.items.filter { $0.template != nil }
        XCTAssertEqual(templates.count, 45)
        for item in templates {
            let document = try XCTUnwrap(item.templateDocument(), item.id)
            XCTAssertNoThrow(try document.validate(), item.id)
            XCTAssertEqual(document.pixels.count, 256)
            XCTAssertEqual(document.templateID, item.id)
            let original = try XCTUnwrap(UIImage(contentsOfFile: item.resourceURL.path)?.cgImage, item.id)
            let rendered = try XCTUnwrap(PixelRenderer.image(for: document).cgImage, item.id)
            XCTAssertEqual(try rgbaPixels(original), try rgbaPixels(rendered), "Remixing changed pixels for \(item.id)")
        }
        for item in catalog.items where item.logicalSize != [16, 16] {
            XCTAssertNil(item.templateDocument(), "Legacy or animated art must not be silently downsampled: \(item.id)")
        }
    }

    func testNumberMemesAreDiscoverableByAllThreeSpellings() {
        let catalog = CatalogStore()
        for query in ["67", "6 7", "six seven"] {
            let matching = catalog.items.filter {
                ([$0.title, $0.category] + $0.tags).joined(separator: " ").localizedStandardContains(query)
            }
            XCTAssertEqual(matching.count, 5, query)
        }
    }

    func testIncludedAnimationsRetainAPNGFrameCounts() throws {
        let catalog = CatalogStore()
        let animations = catalog.items.filter(\.animated)
        XCTAssertEqual(animations.count, 2)
        for item in animations {
            XCTAssertNil(item.templateDocument())
            let expected = item.id == "heart" ? 4 : 3
            XCTAssertEqual(try apngFrameCount(Data(contentsOf: item.resourceURL)), expected, item.id)
        }
    }

    private func rgbaPixels(_ image: CGImage) throws -> Data {
        let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try XCTUnwrap(CGContext(data: nil, width: image.width, height: image.height,
                                              bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                              space: colorSpace,
                                              bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        return Data(bytes: try XCTUnwrap(context.data), count: image.width * image.height * 4)
    }

    private func apngFrameCount(_ data: Data) throws -> Int? {
        let bytes = [UInt8](data)
        var offset = 8
        while offset + 12 <= bytes.count {
            let length = integer(bytes, at: offset)
            guard length >= 0, offset + length + 12 <= bytes.count else {
                XCTFail("Invalid PNG chunk")
                return nil
            }
            if String(bytes: bytes[(offset + 4)..<(offset + 8)], encoding: .ascii) == "acTL", length >= 8 {
                return integer(bytes, at: offset + 8)
            }
            offset += length + 12
        }
        return nil
    }

    private func integer(_ bytes: [UInt8], at offset: Int) -> Int {
        bytes[offset..<(offset + 4)].reduce(0) { ($0 << 8) | Int($1) }
    }
}
