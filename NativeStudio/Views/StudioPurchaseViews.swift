import SwiftUI
import UIKit

/// Both the paid Studio and the free preview use the catalog's exact-grid art.
struct StudioStartingPoints: View {
    let templates: [StickerItem]
    var selectedID: String?
    let onPick: (StickerItem) -> Void
    let onBlank: () -> Void
    @State private var showAll = false
    @State private var pickedInBrowser: StickerItem?

    private var starters: [StickerItem] {
        ["tiny_frog", "tiny_cat", "tiny_duck"].compactMap { id in
            templates.first { $0.id == id }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Choose a starting point")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 8) {
                ForEach(starters) { item in
                    templateButton(item, selected: item.id == selectedID) { onPick(item) }
                }
            }
            HStack {
                if !templates.isEmpty {
                    Button("Browse all \(templates.count) templates") { showAll = true }
                        .accessibilityIdentifier("studio.allTemplates")
                }
                Spacer()
                Button("Start blank", action: onBlank)
                    .accessibilityIdentifier("studio.newDrawing")
            }
            .font(.subheadline.weight(.semibold)).foregroundColor(StudioTheme.purple)
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showAll, onDismiss: {
            if let item = pickedInBrowser {
                pickedInBrowser = nil
                onPick(item)
            }
        }) {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 103), spacing: 9)], spacing: 9) {
                        ForEach(templates) { item in
                            templateButton(item, selected: item.id == selectedID) {
                                pickedInBrowser = item
                                showAll = false
                            }
                        }
                    }.padding(16)
                }
                .background(StudioTheme.cream)
                .navigationTitle("Remix templates").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showAll = false }
                    }
                }
            }.navigationViewStyle(StackNavigationViewStyle()).studioAppearance()
        }
    }

    private func templateButton(_ item: StickerItem, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                StickerThumbnail(item: item).frame(width: 52, height: 52)
                Text(item.title).font(.caption.weight(.semibold)).multilineTextAlignment(.center)
            }
            .padding(6).frame(maxWidth: .infinity, minHeight: 82)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? StudioTheme.purple : StudioTheme.border, lineWidth: selected ? 2 : 1))
        }.buttonStyle(.plain)
            .accessibilityLabel("Remix \(item.title)")
            .accessibilityAddTraits(selected ? [.isSelected] : [])
            .accessibilityIdentifier("studio.template.\(item.id)")
    }
}

private struct StickerThumbnail: View {
    let item: StickerItem
    var body: some View {
        if let image = UIImage(contentsOfFile: item.resourceURL.path) {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit().accessibilityHidden(true)
        }
    }
}

private struct RemixPreview: View {
    let item: StickerItem
    var body: some View {
        HStack(spacing: 12) {
            StickerThumbnail(item: item).frame(width: 48, height: 48)
            Image(systemName: "arrow.right").foregroundColor(StudioTheme.secondary)
            StickerThumbnail(item: item).hueRotation(.degrees(105)).frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title).font(.headline)
                Text("Example recolor").font(.caption).foregroundColor(StudioTheme.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10).background(StudioTheme.lavender).clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore).accessibilityLabel("\(item.title), example color change")
        .accessibilityIdentifier("studio.recolorPreview")
    }
}

@MainActor
struct StudioLockedView: View {
    @ObservedObject var purchases: StudioPurchaseStore
    let templates: [StickerItem]
    let onPurchase: (StickerItem?) -> Void
    let onFree: () -> Void
    @State private var selectedID: String? = "tiny_frog"

    private var selected: StickerItem? { templates.first { $0.id == selectedID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                StudioStartingPoints(templates: templates, selectedID: selectedID, onPick: { selectedID = $0.id }, onBlank: { selectedID = nil })
                    .disabled(purchases.isPurchasing || purchases.isPending)
                if let selected {
                    RemixPreview(item: selected)
                } else {
                    Label("Blank 16 × 16 drawing", systemImage: "square.grid.3x3")
                        .font(.headline).accessibilityIdentifier("studio.blankPreview")
                }
                StudioCheckoutActions(purchases: purchases, onPurchase: { onPurchase(selected) }, onFree: onFree)
            }.padding(18).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
    }
}

@MainActor
struct StudioUnlockView: View {
    @ObservedObject var purchases: StudioPurchaseStore
    let template: StickerItem?
    let onFree: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let template { RemixPreview(item: template) }
                    StudioCheckoutActions(purchases: purchases, onPurchase: { Task { await purchases.purchase() } }, onFree: onFree)
                }.padding(20).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }
            .background(StudioTheme.cream)
            .navigationTitle(purchases.isBetaTesting ? "Studio preview" : "Studio Unlock").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Not now") { dismiss() } } }
        }
        .navigationViewStyle(StackNavigationViewStyle()).studioAppearance()
        .onChange(of: purchases.isUnlocked) { unlocked in if unlocked { dismiss() } }
    }
}

@MainActor
private struct StudioCheckoutActions: View {
    @ObservedObject var purchases: StudioPurchaseStore
    let onPurchase: () -> Void
    let onFree: (() -> Void)?
    @StateObject private var presenter = StudioCheckoutPresenter()

    var body: some View {
        VStack(spacing: 12) {
            Text("Draw, save, and insert your own 16 × 16 stickers.")
                .font(.subheadline).multilineTextAlignment(.center)
            if let note = purchases.localTestingNote {
                StudioNotice(text: note, symbol: "testtube.2")
                    .accessibilityIdentifier("studio.localTestingNotice")
            }
            Button {
                // The inline Studio and a sheet can coexist during a Messages
                // transition. Confirm in the view whose Buy button was tapped.
                purchases.purchasePresentationController = presenter.controller
                onPurchase()
            } label: {
                HStack(spacing: 10) {
                    if purchases.isPurchasing { ProgressView().tint(.white) }
                    Text(buyTitle)
                }
            }
            .buttonStyle(StudioPrimaryButton())
            .disabled(!purchases.canPurchase || purchases.isPurchasing || purchases.isPending)
            .accessibilityIdentifier("studio.unlock")
            Text(purchases.isSandboxTesting
                 ? "Apple's sandbox purchase sheet uses a test price.\nYou will not be charged. Test purchases do not carry into the public release."
                 : (purchases.isBetaTesting
                    ? "No payment is collected in this beta.\nThe App Store version has a separate one-time Studio Unlock."
                    : "One-time purchase. No subscription.\nNo charge per drawing or sticker sent."))
                .font(.footnote).foregroundColor(StudioTheme.secondary).multilineTextAlignment(.center)
            if purchases.isPending {
                StudioNotice(text: "Your purchase is awaiting approval. You can keep using the free stickers.", symbol: "clock")
            } else if let message = purchases.message {
                StudioNotice(text: message)
            }
            if !purchases.isBetaTesting && !purchases.isLoading && purchases.price == nil {
                Button("Try loading the price again") { Task { await purchases.start() } }
                    .font(.subheadline).foregroundColor(StudioTheme.purple)
            }
            Button(purchases.isBetaTesting ? "Restore beta access" : "Restore Purchases") { Task { await purchases.restore() } }
                .font(.subheadline.weight(.semibold)).foregroundColor(StudioTheme.purple)
                .disabled(purchases.isLoading || purchases.isPurchasing)
                .accessibilityIdentifier("studio.restore")
            if let onFree {
                Button("Keep using free stickers", action: onFree)
                    .font(.subheadline).foregroundColor(StudioTheme.secondary)
                    .accessibilityIdentifier("studio.freeStickers")
            }
        }
        .frame(maxWidth: .infinity)
        .background(StudioPurchasePresentationAnchor(presenter: presenter)
            .frame(width: 0, height: 0).allowsHitTesting(false))
    }

    private var buyTitle: String {
        if purchases.isBetaTesting { return "Enable Studio for this beta" }
        if purchases.isPurchasing { return "Unlocking Studio…" }
        if purchases.isPending { return "Awaiting approval" }
        if purchases.isLoading { return "Loading price…" }
        if let price = purchases.price {
            return purchases.isSandboxTesting ? "Test unlock · \(price)" : "Unlock Studio · \(price) once"
        }
        return "Price unavailable"
    }
}

@MainActor
struct StudioHelpView: View {
    @ObservedObject var purchases: StudioPurchaseStore
    @Environment(\.dismiss) private var dismiss
    #if STUDIO_PURCHASE_DIAGNOSTICS
    @State private var copiedPurchaseReport = false
    @State private var copiedInitialPriceReport = false
    #endif

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Using 8 bit art")) {
                    helpRow("Tap. Hold. Make someone's day.", "Tap an included sticker to add it to Messages. Touch and hold to place it on a message or photo.")
                    helpRow("Make a sticker", "Open Studio and choose a template or Start blank. Use Insert sticker in the editor, or Insert beside a saved drawing. You tap Send in Messages.")
                    if purchases.isSandboxTesting {
                        helpRow("Apple sandbox testing", "Included stickers, search and favorites stay free. Studio Unlock opens Apple's test purchase sheet. No real payment is collected in TestFlight, and sandbox ownership does not unlock the later public release.")
                    } else if purchases.isBetaTesting {
                        helpRow("Free during this beta", "Enable Studio to try the editor and saved drafts without payment. The App Store version has a separate one-time Studio Unlock. Apple's purchase flow is not tested in this beta.")
                    } else {
                        helpRow("A one-time unlock", "Included stickers, search, and favorites are free. Studio adds the editor and saved drafts. There is no subscription or charge per drawing.")
                    }
                }
                Section(header: Text("Your drawings")) {
                    helpRow("Saved on this device", "Drawings save as you edit. Deleting the app can remove them. Export drawings you want to keep.")
                    helpRow("Restore tools, not deleted art", purchases.isSandboxTesting
                            ? "Restore Purchases checks verified test ownership under the same sandbox purchase account. Drawings stay on this device and do not automatically move between devices."
                            : (purchases.isBetaTesting
                               ? "Restore beta access checks whether Studio was enabled on this device. You can enable it free on another beta device, but drawings don't automatically move between devices."
                               : "Restore Purchases brings back your Studio unlock under the same App Store account. Drawings don't automatically move between devices."))
                }
                Section(header: Text("Studio access")) {
                    Label(purchases.isBetaTesting
                          ? (purchases.isUnlocked ? "Studio is enabled for this beta" : "Studio is not enabled yet")
                          : (purchases.isUnlocked ? "Studio is unlocked" : "Studio is not unlocked"),
                          systemImage: purchases.isUnlocked ? "checkmark.circle.fill" : "lock")
                        .foregroundColor(StudioTheme.purple)
                    Button(purchases.isBetaTesting ? "Restore beta access" : "Restore Purchases") { Task { await purchases.restore() } }
                        .disabled(purchases.isLoading || purchases.isPurchasing)
                        .accessibilityIdentifier("studio.restore")
                    if let message = purchases.message { Text(message).font(.footnote).foregroundColor(StudioTheme.secondary) }
                }
                #if STUDIO_PURCHASE_DIAGNOSTICS
                Section(header: Text("First price lookup")) {
                    Text("Saved once for this build. Later price checks keep this first result so we can investigate a fresh install.")
                        .font(.footnote).foregroundColor(StudioTheme.secondary)
                    Text(purchases.initialPriceAvailabilityStatus ?? "The first price lookup has not completed yet.")
                        .font(.footnote).foregroundColor(StudioTheme.secondary)
                        .accessibilityIdentifier("studio.purchaseDiagnostics.initialStatus")
                    Button(copiedInitialPriceReport ? "Initial price report copied" : "Copy initial price report") {
                        guard let report = purchases.initialPriceAvailabilityReport else { return }
                        UIPasteboard.general.string = report
                        copiedInitialPriceReport = true
                    }
                    .disabled(purchases.initialPriceAvailabilityReport == nil)
                    .accessibilityIdentifier("studio.purchaseDiagnostics.copyInitial")
                }
                Section(header: Text("Purchase availability check")) {
                    Text("Check Apple's current product listing without changing Studio access or making a purchase.")
                        .font(.footnote).foregroundColor(StudioTheme.secondary)
                    Button(purchases.isCheckingPurchaseAvailability ? "Checking availability…" : "Check purchase availability") {
                        copiedPurchaseReport = false
                        Task { await purchases.checkPurchaseAvailability() }
                    }
                    .disabled(purchases.isCheckingPurchaseAvailability)
                    .accessibilityIdentifier("studio.purchaseDiagnostics.check")
                    if let status = purchases.purchaseAvailabilityStatus {
                        Text(status).font(.footnote).foregroundColor(StudioTheme.secondary)
                            .accessibilityIdentifier("studio.purchaseDiagnostics.status")
                    }
                    Button(copiedPurchaseReport ? "Technical report copied" : "Copy technical report") {
                        guard let report = purchases.purchaseAvailabilityReport else { return }
                        UIPasteboard.general.string = report
                        copiedPurchaseReport = true
                    }
                    .disabled(purchases.isCheckingPurchaseAvailability || purchases.purchaseAvailabilityReport == nil)
                    .accessibilityIdentifier("studio.purchaseDiagnostics.copy")
                }
                #endif
                Section(header: Text("Need a hand?")) {
                    Link("Email support", destination: URL(string: "mailto:seltzer.wisdom7h@icloud.com")!)
                    Link("Support instructions", destination: URL(string: "https://mim-armand.github.io/8bit-stickers/support/")!)
                    Link("Privacy policy", destination: URL(string: "https://mim-armand.github.io/8bit-stickers/privacy/")!)
                }
                #if DEBUG && STUDIO_LOCAL_TESTING && !STUDIO_BETA_TESTING && !STUDIO_SANDBOX_TESTING && !STUDIO_APP_STORE && !STUDIO_SCREENSHOT_TESTING
                if purchases.isLocalTesting {
                    Section(header: Text("Local testing")) {
                        Text(purchases.localTestingNote ?? "Local test — no charge").font(.footnote)
                        if purchases.isUsingStoreKitTesting {
                            Text("Use Xcode's StoreKit transaction manager to test cancellation, approval, and refunds. This build does not configure a live App Store product.").font(.footnote)
                        } else {
                            DisclosureGroup("Purchase test controls") {
                                Button("Test cancelled purchase") { Task { await purchases.simulate(.cancelled) } }
                                Button("Test approval pending") { Task { await purchases.simulate(.pending) } }
                                Button("Approve pending purchase") { purchases.approveLocalPending() }
                                Button("Test purchase failure") { Task { await purchases.simulate(.failure) } }
                                Button("Test refund / revoke unlock") { purchases.revokeLocalPurchase() }
                                Button("Reset local purchase") { purchases.resetLocalPurchase() }
                            }
                        }
                    }
                }
                #endif
            }
            .navigationTitle("A little help").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.navigationViewStyle(StackNavigationViewStyle()).studioAppearance()
    }

    private func helpRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(.subheadline, design: .rounded).weight(.semibold))
            Text(detail).font(.footnote).foregroundColor(StudioTheme.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 5).accessibilityElement(children: .combine)
    }
}

@MainActor
private final class StudioCheckoutPresenter: ObservableObject {
    weak var controller: UIViewController?
}

/// Keep the presenter local to its checkout without looking up app windows.
@MainActor
private struct StudioPurchasePresentationAnchor: UIViewControllerRepresentable {
    let presenter: StudioCheckoutPresenter

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        presenter.controller = controller
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        presenter.controller = controller
    }
}
