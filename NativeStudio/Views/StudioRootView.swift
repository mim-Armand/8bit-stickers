import SwiftUI

@MainActor
struct StudioRootView: View {
    @ObservedObject var catalog: CatalogStore
    @ObservedObject var drafts: DraftStore
    @ObservedObject var purchases: StudioPurchaseStore
    let isExpanded: Bool
    let onExpand: () -> Void
    let onInsert: (URL, String) -> Void
    @State private var tab = StudioTab.collection
    @State private var session: PixelDocument?
    @State private var pendingCreation: PixelDocument?
    @State private var unlockNeedsExpansion = false
    @State private var showUnlock = false
    @State private var showHelp = false
    @State private var errorMessage: String?
    @State private var showError = false

    private enum StudioTab: String, CaseIterable { case collection = "Stickers", studio = "Studio" }

    var body: some View {
        VStack(spacing: 0) {
            header
            if let recoveryMessage = drafts.errorMessage {
                StudioNotice(text: recoveryMessage, symbol: "exclamationmark.circle", isError: true)
                    .padding(.horizontal, 16).padding(.bottom, 8)
                    .accessibilityIdentifier("studio.storageNotice")
            }
            if let document = session {
                StudioEditorView(document: document, drafts: drafts, isUnlocked: purchases.isUnlocked, isExpanded: isExpanded, onExpand: onExpand, onBack: { session = nil; tab = .studio }, onInsert: onInsert, onUnlock: { presentUnlock() })
                    .id(document.id)
            } else {
                tabBar
                if tab == .collection {
                    StudioCollectionView(catalog: catalog, drafts: drafts, onInsert: onInsert, onRemix: remix)
                        .padding(.top, 12)
                } else if purchases.isUnlocked || !drafts.drafts.isEmpty {
                    StudioDraftsView(drafts: drafts, isUnlocked: purchases.isUnlocked, onNew: { start(PixelDocument()) }, onOpen: open, onUnlock: { presentUnlock() })
                } else {
                    StudioLockedView(purchases: purchases, onUnlock: { start(PixelDocument()) })
                }
            }
        }
        .background(StudioTheme.cream.ignoresSafeArea())
        .studioAppearance()
        .sheet(isPresented: $showUnlock, onDismiss: finishUnlock) { StudioUnlockView(purchases: purchases) }
        .sheet(isPresented: $showHelp) { StudioHelpView(purchases: purchases) }
        .alert("Couldn't open the drawing", isPresented: $showError) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "Please try again.") }
        .onChange(of: isExpanded) { expanded in
            if expanded && unlockNeedsExpansion {
                unlockNeedsExpansion = false
                showUnlock = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("8 bit art").font(.system(.title3, design: .rounded).weight(.heavy))
                if purchases.isLocalTesting {
                    Text(purchases.isSandboxTesting ? "TESTFLIGHT SANDBOX · NO REAL CHARGES"
                         : (purchases.isBetaTesting ? "TESTFLIGHT PREVIEW · NO CHARGES" : "LOCAL TEST · NO REAL CHARGES"))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(StudioTheme.purple).accessibilityIdentifier("studio.localTestingNotice")
                } else {
                    Text("Little pixels. Big feelings.").font(.caption).foregroundColor(StudioTheme.secondary)
                }
            }
            Spacer()
            if purchases.isUnlocked && session == nil {
                Image(systemName: "checkmark.seal.fill").foregroundColor(StudioTheme.purple).accessibilityLabel("Studio unlocked")
            }
            Button { showHelp = true } label: { Image(systemName: "questionmark.circle").font(.title3).frame(width: 44, height: 44) }
                .accessibilityLabel("Help and purchase settings").accessibilityIdentifier("studio.help")
        }.padding(.horizontal, 16).padding(.top, 7).padding(.bottom, 5)
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(StudioTab.allCases, id: \.self) { value in
                Button {
                    tab = value
                    if value == .studio && !isExpanded { onExpand() }
                } label: {
                    Label(value.rawValue, systemImage: value == .collection ? "square.grid.2x2" : "pencil.tip.crop.circle")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundColor(tab == value ? StudioTheme.purple : StudioTheme.secondary)
                        .background(tab == value ? Color.white : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityAddTraits(tab == value ? [.isSelected] : [])
                .accessibilityIdentifier(value == .collection ? "studio.tab.collection" : "studio.tab.studio")
            }
        }.padding(4).background(StudioTheme.lavender).clipShape(RoundedRectangle(cornerRadius: 13)).padding(.horizontal, 16)
    }

    private func start(_ document: PixelDocument) {
        if purchases.isUnlocked { open(document) }
        else { presentUnlock(for: document) }
    }
    private func presentUnlock(for document: PixelDocument? = nil) {
        pendingCreation = document
        if isExpanded {
            showUnlock = true
        } else {
            // Present checkout after the Messages expansion, not inside its compact tray.
            unlockNeedsExpansion = true
            onExpand()
        }
    }
    private func open(_ document: PixelDocument) { tab = .studio; session = document; if !isExpanded { onExpand() } }
    private func remix(_ item: StickerItem) {
        guard let document = item.templateDocument() else {
            errorMessage = "This sticker isn't a 16 × 16 template. Try a tiny sticker or start a blank drawing."
            showError = true; return
        }
        start(document)
    }
    private func finishUnlock() {
        unlockNeedsExpansion = false
        if purchases.isUnlocked, let document = pendingCreation { open(document) }
        pendingCreation = nil
    }
}
