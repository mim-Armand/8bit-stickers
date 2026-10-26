import Foundation
import UIKit

struct PixelColor: Codable, Hashable {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(hex: String) {
        let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(r: UInt8((value >> 16) & 255), g: UInt8((value >> 8) & 255), b: UInt8(value & 255))
    }

    var uiColor: UIColor {
        UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255,
                blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    static let clear = PixelColor(r: 0, g: 0, b: 0, a: 0)
    static let palette: [PixelColor] = [
        .clear,
        PixelColor(hex: "17151C"), PixelColor(hex: "FFFDF3"),
        PixelColor(hex: "FFD52A"), PixelColor(hex: "EBA427"),
        PixelColor(hex: "FF7A23"), PixelColor(hex: "F54D66"),
        PixelColor(hex: "FF9BB9"), PixelColor(hex: "458AFF"),
        PixelColor(hex: "7ADFFF"), PixelColor(hex: "3DCA6B"),
        PixelColor(hex: "228E42"), PixelColor(hex: "8DE6A7"),
        PixelColor(hex: "EBAA70"), PixelColor(hex: "A76640"),
        PixelColor(hex: "9B6BDB"), PixelColor(hex: "9EA5B6")
    ]
}

enum PixelDocumentError: LocalizedError, Equatable {
    case unsupportedVersion
    case invalidDimensions
    case invalidTitle
    case invalidPalette
    case invalidPixels

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: return "This drawing uses an unsupported format. Its original file has been kept."
        case .invalidDimensions: return "Studio drawings must use a 16 × 16 canvas."
        case .invalidTitle: return "Give this drawing a name of 1 to 60 characters."
        case .invalidPalette: return "This drawing has an invalid color palette."
        case .invalidPixels: return "This drawing contains invalid pixel data."
        }
    }
}

struct PixelDocument: Codable, Identifiable, Equatable {
    static let side = 16
    static let cellCount = side * side
    static let maximumTitleLength = 60

    var schemaVersion: Int
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var width: Int
    var height: Int
    var palette: [PixelColor]
    var pixels: [Int]
    var templateID: String?

    init(id: UUID = UUID(), title: String = "Untitled sticker", createdAt: Date = Date(),
         updatedAt: Date? = nil, palette: [PixelColor] = PixelColor.palette,
         pixels: [Int] = Array(repeating: 0, count: PixelDocument.cellCount), templateID: String? = nil) {
        self.schemaVersion = 1
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.width = Self.side
        self.height = Self.side
        self.palette = palette
        self.pixels = pixels
        self.templateID = templateID
    }

    var isEmpty: Bool {
        pixels.allSatisfy { palette.indices.contains($0) && palette[$0].a == 0 }
    }

    func validate() throws {
        guard schemaVersion == 1 else { throw PixelDocumentError.unsupportedVersion }
        guard width == Self.side, height == Self.side else { throw PixelDocumentError.invalidDimensions }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, title.count <= Self.maximumTitleLength else {
            throw PixelDocumentError.invalidTitle
        }
        guard !palette.isEmpty, palette.count <= 256, palette[0] == .clear else {
            throw PixelDocumentError.invalidPalette
        }
        guard pixels.count == Self.cellCount, pixels.allSatisfy({ palette.indices.contains($0) }) else {
            throw PixelDocumentError.invalidPixels
        }
    }
}
