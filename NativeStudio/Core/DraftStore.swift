import Foundation
import Combine

enum DraftStoreError: LocalizedError {
    case fileTooLarge
    case mismatchedIdentifier

    var errorDescription: String? {
        switch self {
        case .fileTooLarge: return "This drawing is larger than the supported document size."
        case .mismatchedIdentifier: return "This drawing's identifier does not match its file."
        }
    }
}

@MainActor
final class DraftStore: ObservableObject {
    @Published private(set) var drafts: [PixelDocument] = []
    @Published private(set) var favorites: Set<String> = []
    @Published var errorMessage: String?

    let directory: URL
    private let manager = FileManager.default
    private let maximumFileSize = 128_000

    private var draftsDirectory: URL { directory.appendingPathComponent("Drafts", isDirectory: true) }
    private var favoritesURL: URL { directory.appendingPathComponent("favorites.json") }
    var recoveryDirectory: URL { directory.appendingPathComponent("Recovery", isDirectory: true) }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("8BitStudio", isDirectory: true)
        load()
    }

    func load() {
        do {
            try prepareDirectories()
            let urls = try manager.contentsOfDirectory(at: draftsDirectory,
                                                       includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles])
            var loaded: [PixelDocument] = []
            var hadRecovery = false
            for url in urls where url.pathExtension == "json" {
                do {
                    let data = try readLimitedData(at: url)
                    let document = try JSONDecoder().decode(PixelDocument.self, from: data)
                    try document.validate()
                    guard url.deletingPathExtension().lastPathComponent.lowercased() == document.id.uuidString.lowercased() else {
                        throw DraftStoreError.mismatchedIdentifier
                    }
                    loaded.append(document)
                } catch {
                    hadRecovery = true
                    preserveForRecovery(url)
                }
            }
            drafts = sorted(loaded)
            if manager.fileExists(atPath: favoritesURL.path) {
                do {
                    let decoded = try JSONDecoder().decode([String].self, from: readLimitedData(at: favoritesURL))
                    favorites = Set(decoded.filter { !$0.isEmpty && $0.count <= 128 })
                } catch {
                    hadRecovery = true
                    preserveForRecovery(favoritesURL)
                }
            }
            errorMessage = hadRecovery
                ? "Some saved files could not be opened. Their originals have been kept for recovery; your other drawings are ready."
                : nil
        } catch {
            // Retain the last loaded state if the directory becomes unavailable.
            errorMessage = "Your drawings could not be loaded. Try again; no drawings have been deleted."
        }
    }

    func save(_ document: PixelDocument) throws {
        do {
            try document.validate()
            try prepareDirectories()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(document)
            guard data.count <= maximumFileSize else { throw DraftStoreError.fileTooLarge }
            try data.write(to: fileURL(id: document.id), options: .atomic)
            var updated = drafts.filter { $0.id != document.id }
            updated.append(document)
            drafts = sorted(updated)
            errorMessage = nil
        } catch {
            errorMessage = "Your drawing could not be saved. Keep it open and try again, or export a copy."
            throw error
        }
    }

    func delete(id: UUID) throws {
        do {
            let url = fileURL(id: id)
            if manager.fileExists(atPath: url.path) { try manager.removeItem(at: url) }
            drafts.removeAll { $0.id == id }
            errorMessage = nil
        } catch {
            errorMessage = "This drawing could not be deleted. It is still in your drafts."
            throw error
        }
    }

    @discardableResult
    func duplicate(_ document: PixelDocument) throws -> PixelDocument {
        try document.validate()
        var copy = document
        copy.id = UUID()
        copy.title = String("Copy of \(document.title)".prefix(PixelDocument.maximumTitleLength))
        copy.createdAt = Date()
        copy.updatedAt = copy.createdAt
        try save(copy)
        return copy
    }

    func toggleFavorite(_ id: String) {
        guard !id.isEmpty, id.count <= 128 else { return }
        var updated = favorites
        if updated.contains(id) { updated.remove(id) } else { updated.insert(id) }
        do {
            try prepareDirectories()
            let data = try JSONEncoder().encode(updated.sorted())
            try data.write(to: favoritesURL, options: .atomic)
            favorites = updated
            errorMessage = nil
        } catch {
            errorMessage = "Your favorites could not be saved. Try again."
        }
    }

    func document(id: UUID) -> PixelDocument? {
        drafts.first { $0.id == id }
    }

    private func fileURL(id: UUID) -> URL {
        draftsDirectory.appendingPathComponent(id.uuidString).appendingPathExtension("json")
    }

    private func prepareDirectories() throws {
        try manager.createDirectory(at: draftsDirectory, withIntermediateDirectories: true)
    }

    private func readLimitedData(at url: URL) throws -> Data {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard (values.fileSize ?? maximumFileSize + 1) <= maximumFileSize else { throw DraftStoreError.fileTooLarge }
        return try Data(contentsOf: url)
    }

    private func preserveForRecovery(_ url: URL) {
        do {
            try manager.createDirectory(at: recoveryDirectory, withIntermediateDirectories: true)
            let recovered = recoveryDirectory.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
            try manager.moveItem(at: url, to: recovered)
        } catch {
            // If moving fails, the original remains in place. Never overwrite it.
        }
    }

    private func sorted(_ documents: [PixelDocument]) -> [PixelDocument] {
        documents.sorted {
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
