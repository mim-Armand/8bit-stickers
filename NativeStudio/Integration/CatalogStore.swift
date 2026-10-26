import Foundation
import Combine

struct StickerTemplate: Codable {
    let palette: [PixelColor]
    let pixels: [Int]
}

struct StickerItem: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let tags: [String]
    let animated: Bool
    let filename: String
    let logicalSize: [Int]?
    let template: StickerTemplate?
    var resourceURL: URL { Bundle.main.resourceURL!.appendingPathComponent(filename) }

    func templateDocument() -> PixelDocument? {
        guard let template = template, template.pixels.count == 256 else { return nil }
        var document = PixelDocument(title: title + " remix")
        document.palette = template.palette
        for color in PixelColor.palette where !document.palette.contains(color) {
            document.palette.append(color)
        }
        document.pixels = template.pixels
        document.templateID = id
        return document
    }
}

@MainActor final class CatalogStore: ObservableObject {
    @Published var items: [StickerItem] = []
    @Published var errorMessage: String?

    init(bundle: Bundle = .main) {
        do {
            guard let url = bundle.url(forResource: "NativeCatalog", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            items = try JSONDecoder().decode([StickerItem].self, from: Data(contentsOf: url))
        } catch { errorMessage = "The sticker collection could not be loaded. Please reopen Studio." }
    }
}
