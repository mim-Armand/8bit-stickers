import SwiftUI

@MainActor
struct StudioLockedView: View {
    @ObservedObject var purchases: StudioPurchaseStore
    let onUnlock: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PixelHeartMark().padding(20).background(StudioTheme.lavender).clipShape(RoundedRectangle(cornerRadius: 22))
                VStack(spacing: 8) {
                    Text("A little more you.").font(.system(.title, design: .rounded).weight(.bold))
                    Text("Make your own tiny stickers, right inside Messages.")
                        .font(.body).foregroundColor(StudioTheme.secondary).multilineTextAlignment(.center)
                }
                StudioFeatures()
                Button(action: onUnlock) { Label("Try Studio", systemImage: "pencil.tip.crop.circle") }
                    .buttonStyle(StudioPrimaryButton()).accessibilityIdentifier("studio.newDrawing")
                Text("One-time unlock\(purchases.price.map { " · \($0)" } ?? ""). No subscription.\nAll included stickers stay free.")
                    .font(.footnote).foregroundColor(StudioTheme.secondary).multilineTextAlignment(.center)
                Button("Restore Purchases") { Task { await purchases.restore() } }
                    .font(.subheadline.weight(.semibold)).foregroundColor(StudioTheme.purple)
                    .disabled(purchases.isLoading || purchases.isPurchasing)
                    .accessibilityIdentifier("studio.restore")
                if let message = purchases.message { StudioNotice(text: message) }
            }.padding(24).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
    }
}

private struct StudioFeatures: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            feature("square.grid.3x3", "Draw in 16 × 16", "Tiny canvas. Plenty of personality.")
            feature("square.stack", "Keep your ideas", "Save, name, and reopen your drawings.")
            feature("arrow.up.message", "Send your own stickers", "Create once. Use them again and again.")
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 18))
    }
    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: symbol).font(.title3).foregroundColor(StudioTheme.purple).frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(detail).font(.footnote).foregroundColor(StudioTheme.secondary)
            }
        }.accessibilityElement(children: .combine)
    }
}

@MainActor
struct StudioUnlockView: View {
    @ObservedObject var purchases: StudioPurchaseStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PixelHeartMark().padding(.top, 12)
                    VStack(spacing: 7) {
                        Text("Your ideas. Your stickers.").font(.system(.title2, design: .rounded).weight(.bold))
                        Text("Unlock the editor and saved drafts forever.")
                            .font(.subheadline).foregroundColor(StudioTheme.secondary).multilineTextAlignment(.center)
                    }
                    StudioFeatures()
                    if let note = purchases.localTestingNote {
                        StudioNotice(text: note, symbol: "testtube.2")
                            .accessibilityIdentifier("studio.localTestingNotice")
                    }
                    Button { Task { await purchases.purchase() } } label: {
                        HStack(spacing: 10) {
                            if purchases.isPurchasing { ProgressView().tint(.white) }
                            Text(buyTitle)
                        }
                    }
                    .buttonStyle(StudioPrimaryButton())
                    .disabled(!purchases.canPurchase || purchases.isPurchasing || purchases.isPending)
                    .accessibilityIdentifier("studio.unlock")
                    Text("One-time purchase. No subscription.\nNo charge per drawing or sticker sent.")
                        .font(.footnote).foregroundColor(StudioTheme.secondary).multilineTextAlignment(.center)
                    if purchases.isPending {
                        StudioNotice(text: "Your purchase is awaiting approval. You can keep using the free stickers.", symbol: "clock")
                    } else if let message = purchases.message {
                        StudioNotice(text: message)
                    }
                    if !purchases.isLoading && purchases.price == nil {
                        Button("Try loading the price again") { Task { await purchases.start() } }
                            .font(.subheadline).foregroundColor(StudioTheme.purple)
                    }
                    Button("Restore Purchases") { Task { await purchases.restore() } }
                        .font(.subheadline.weight(.semibold)).foregroundColor(StudioTheme.purple)
                        .disabled(purchases.isLoading || purchases.isPurchasing)
                        .accessibilityIdentifier("studio.restore")
                    Button("Keep using free stickers") { dismiss() }
                        .font(.subheadline).foregroundColor(StudioTheme.secondary)
                }.padding(24).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }
            .background(StudioTheme.cream)
            .navigationTitle("Studio Unlock").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Not now") { dismiss() } } }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: purchases.isUnlocked) { unlocked in if unlocked { dismiss() } }
    }

    private var buyTitle: String {
        if purchases.isPurchasing { return "Unlocking Studio…" }
        if purchases.isPending { return "Awaiting approval" }
        if purchases.isLoading { return "Loading price…" }
        if let price = purchases.price { return "Unlock Studio · \(price) once" }
        return "Price unavailable"
    }
}

@MainActor
struct StudioHelpView: View {
    @ObservedObject var purchases: StudioPurchaseStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Using 8 bit art")) {
                    helpRow("Tap. Hold. Make someone's day.", "Tap an included sticker to add it to Messages. Touch and hold to place it on a message or photo.")
                    helpRow("Make a sticker", "Open Studio, start a drawing or remix a tiny sticker, then tap Insert sticker. Messages puts it in the composer; you tap Send.")
                    helpRow("A one-time unlock", "Included stickers, search, and favorites are free. Studio adds the editor and saved drafts. There is no subscription or charge per drawing.")
                }
                Section(header: Text("Your drawings")) {
                    helpRow("Saved on this device", "Drawings save as you edit. Deleting the app can remove them. Export drawings you want to keep.")
                    helpRow("Restore tools, not deleted art", "Restore Purchases brings back your Studio unlock under the same App Store account. Drawings don't automatically move between devices.")
                }
                Section(header: Text("Studio access")) {
                    Label(purchases.isUnlocked ? "Studio is unlocked" : "Studio is not unlocked", systemImage: purchases.isUnlocked ? "checkmark.circle.fill" : "lock")
                        .foregroundColor(StudioTheme.purple)
                    Button("Restore Purchases") { Task { await purchases.restore() } }
                        .disabled(purchases.isLoading || purchases.isPurchasing)
                        .accessibilityIdentifier("studio.restore")
                    if let message = purchases.message { Text(message).font(.footnote).foregroundColor(StudioTheme.secondary) }
                }
                Section(header: Text("Need a hand?")) {
                    Link("Email support", destination: URL(string: "mailto:seltzer.wisdom7h@icloud.com")!)
                    Link("Support instructions", destination: URL(string: "https://mim-armand.github.io/8bit-stickers/support/")!)
                    Link("Privacy policy", destination: URL(string: "https://mim-armand.github.io/8bit-stickers/privacy/")!)
                }
                #if DEBUG && STUDIO_LOCAL_TESTING
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
        }.navigationViewStyle(StackNavigationViewStyle()).accentColor(StudioTheme.purple)
    }

    private func helpRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(.subheadline, design: .rounded).weight(.semibold))
            Text(detail).font(.footnote).foregroundColor(StudioTheme.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 5).accessibilityElement(children: .combine)
    }
}
