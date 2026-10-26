import UIKit
import SwiftUI
import Messages

@MainActor final class MessagesViewController: MSMessagesAppViewController {
    private let catalog = CatalogStore()
    private let drafts = DraftStore()
    private let purchases = StudioPurchaseStore(localTesting: true)
    private var host: UIHostingController<StudioRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        if presentationContext == .media {
            let browser = IncludedStickerBrowser(stickerSize: .small)
            browser.stickers = catalog.items.compactMap {
                try? MSSticker(contentsOfFileURL: $0.resourceURL, localizedDescription: String($0.title.prefix(150)))
            }
            addChild(browser)
            browser.view.frame = view.bounds
            browser.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(browser.view)
            browser.didMove(toParent: self)
            return
        }
        updateRoot()
        Task { await purchases.start() }
    }

    override func willBecomeActive(with conversation: MSConversation) {
        Task { await purchases.refreshEntitlements() }
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) { updateRoot() }

    private func updateRoot() {
        guard presentationContext != .media else { return }
        let root = StudioRootView(catalog: catalog, drafts: drafts, purchases: purchases,
            isExpanded: presentationStyle == .expanded,
            onExpand: { [weak self] in self?.requestPresentationStyle(.expanded) },
            onInsert: { [weak self] url, title in self?.insert(url: url, title: title) })
        if let host = host { host.rootView = root; return }
        let host = UIHostingController(rootView: root)
        self.host = host
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        host.didMove(toParent: self)
    }

    private func insert(url: URL, title: String) {
        guard let conversation = activeConversation else {
            showError("Open a conversation to insert your sticker."); return
        }
        do {
            let sticker = try MSSticker(contentsOfFileURL: url, localizedDescription: String(title.prefix(150)))
            conversation.insert(sticker) { [weak self] error in
                Task { @MainActor in
                    if let error = error { self?.showError(error.localizedDescription) }
                    else { self?.requestPresentationStyle(.compact) }
                }
            }
        } catch { showError("This sticker could not be inserted. Your drawing is still saved.") }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Couldn’t insert sticker", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

/// Other system sticker surfaces receive a native browsing-only fallback.
private final class IncludedStickerBrowser: MSStickerBrowserViewController {
    var stickers: [MSSticker] = []
    override func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int { stickers.count }
    override func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
        stickers[index]
    }
}
