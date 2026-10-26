import SwiftUI

@main struct StudioLocalApp: App {
    @StateObject private var catalog: CatalogStore
    @StateObject private var drafts: DraftStore
    @StateObject private var purchases: StudioPurchaseStore
    @State private var insertedTitle: String?

    init() {
        let environment = ProcessInfo.processInfo.environment
        let isUITest = environment["STUDIO_UI_TESTING"] == "1"
        let directory = isUITest ? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StudioUITestData", isDirectory: true) : nil
        let preferences = isUITest ? UserDefaults(suiteName: "StudioLocalUITest")! : .standard
        if isUITest && environment["STUDIO_UI_TEST_RESET"] == "1" {
            if let directory { try? FileManager.default.removeItem(at: directory) }
            preferences.removePersistentDomain(forName: "StudioLocalUITest")
        }
        _catalog = StateObject(wrappedValue: CatalogStore())
        _drafts = StateObject(wrappedValue: DraftStore(directory: directory))
        _purchases = StateObject(wrappedValue: StudioPurchaseStore(localTesting: true, defaults: preferences))
    }

    var body: some Scene {
        WindowGroup {
            StudioRootView(catalog: catalog, drafts: drafts, purchases: purchases, isExpanded: true,
                onExpand: {}, onInsert: { _, title in insertedTitle = title })
                .task { await purchases.start() }
                .alert("Sticker ready", isPresented: Binding(get: { insertedTitle != nil }, set: { if !$0 { insertedTitle = nil } })) {
                    Button("OK") { insertedTitle = nil }
                } message: { Text("In Messages, this sticker appears in the composer. Tap Send there to share it.") }
        }
    }
}
