import Foundation
import UIKit
import CryptoKit

enum PixelRendererError: LocalizedError {
    case emptyDrawing
    case imageCreationFailed
    case oversizedImage

    var errorDescription: String? {
        switch self {
        case .emptyDrawing: return "Draw a few pixels before inserting or exporting your sticker."
        case .imageCreationFailed: return "Your sticker image could not be created. Your drawing is still saved."
        case .oversizedImage: return "This sticker image is too large for Messages. Your drawing is still saved."
        }
    }
}

enum PixelRenderer {
    static func pngData(for document: PixelDocument, raw: Bool = false) throws -> Data {
        let image = try makeImage(for: document, raw: raw)
        guard let data = UIImage(cgImage: image).pngData() else { throw PixelRendererError.imageCreationFailed }
        guard data.count < 500_000 else { throw PixelRendererError.oversizedImage }
        return data
    }

    static func image(for document: PixelDocument) -> UIImage {
        guard let image = try? makeImage(for: document, raw: false) else { return UIImage() }
        return UIImage(cgImage: image)
    }

    static func exportURL(for document: PixelDocument) throws -> URL {
        try document.validate()
        guard !document.isEmpty else { throw PixelRendererError.emptyDrawing }
        let data = try pngData(for: document)
        let digest = SHA256.hash(data: data).prefix(8).map { String(format: "%02x", $0) }.joined()
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("8BitStudioExports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(document.id.uuidString)-\(digest).png")
        if !FileManager.default.fileExists(atPath: url.path) { try data.write(to: url, options: .atomic) }
        // Cached files remain available after insertion starts; Messages reads them asynchronously.
        return url
    }

    private static func makeImage(for document: PixelDocument, raw: Bool) throws -> CGImage {
        try document.validate()
        let side = raw ? 16 : 300
        let scale = raw ? 1 : 18
        let padding = raw ? 0 : 6
        var bytes = [UInt8](repeating: 0, count: side * side * 4)
        for y in 0..<16 {
            for x in 0..<16 {
                let color = document.palette[document.pixels[y * 16 + x]]
                for dy in 0..<scale {
                    for dx in 0..<scale {
                        let outputX = padding + x * scale + dx
                        let outputY = padding + y * scale + dy
                        let index = (outputY * side + outputX) * 4
                        bytes[index] = color.r
                        bytes[index + 1] = color.g
                        bytes[index + 2] = color.b
                        bytes[index + 3] = color.a
                    }
                }
            }
        }
        let data = Data(bytes)
        guard let provider = CGDataProvider(data: data as CFData),
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: side * 4, space: colorSpace,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false,
                                  intent: .defaultIntent) else {
            throw PixelRendererError.imageCreationFailed
        }
        return image
    }
}
