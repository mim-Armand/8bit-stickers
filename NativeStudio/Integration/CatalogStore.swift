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
    @Published private(set) var items: [StickerItem] = []
    @Published var errorMessage: String?
    private var indexedWords: [String] = []
    private static let searchAliases = [
        "thank you": "thanks", "thank u": "thanks", "ty": "thanks", "thx": "thanks", "🙏": "thanks",
        "haha": "lol", "hahaha": "lol", "😂": "lol", "🤣": "lol",
        "❤": "love", "💕": "love", "😍": "love",
        "six seven": "67", "6 7": "67"
    ]

    init(bundle: Bundle = .main) {
        do {
            guard let url = bundle.url(forResource: "NativeCatalog", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            items = try JSONDecoder().decode([StickerItem].self, from: Data(contentsOf: url))
            indexedWords = items.map { item in
                let fields = ([item.title, item.category] + item.tags).joined(separator: " ")
                return " " + Self.searchWords(in: fields) + " "
            }
        } catch { errorMessage = "The sticker collection could not be loaded. Please reopen Studio." }
    }

    func stickers(matching query: String) -> [StickerItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }

        let phrase = Self.searchWords(in: trimmed)
        let aliasKey = phrase.isEmpty ? String(trimmed.unicodeScalars.filter { !$0.properties.isEmojiModifier && $0.value != 0xFE0F }) : phrase
        let needles = [phrase, Self.searchAliases[aliasKey]].compactMap { phrase -> String? in
            // Anchor each word at the start. Short terms like "hi" and "yes" must match a full word.
            guard let phrase, let lastWord = phrase.split(separator: " ").last else { return nil }
            return " " + phrase + (lastWord.count <= 3 ? " " : "")
        }
        if needles.isEmpty {
            return items.filter { ([$0.title, $0.category] + $0.tags).joined(separator: " ").localizedStandardContains(trimmed) }
        }
        return zip(items, indexedWords).compactMap { item, words in
            needles.contains(where: words.contains) ? item : nil
        }
    }

    private static func searchWords(in text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
    }
}
