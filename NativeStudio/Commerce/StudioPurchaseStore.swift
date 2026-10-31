import Combine
import Foundation
import StoreKit
import UIKit

/// Only the explicit App Store configuration enables public StoreKit checkout.
/// It uses Apple's verified transaction/entitlement context and never reads mock or
/// free-beta ownership. Separate beta configurations remain isolated.
/// DEBUG + STUDIO_LOCAL_TESTING enables either the deterministic simulator or, when
/// explicitly requested by the Xcode scheme, the local StoreKit configuration.
@MainActor
final class StudioPurchaseStore: ObservableObject {
    static let productID = "eu.armand.bitart.studio.unlock"
    static let appBundleID = "eu.armand.--bit-art"

    @Published private(set) var isUnlocked = false
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isPending = false
    @Published var message: String?
    @Published private(set) var price: String?

    private enum Mode {
        case disabled, simulated, storeKit, sandboxStoreKit, appStore
        #if STUDIO_BETA_TESTING
        case betaPreview
        #endif
    }
    private let mode: Mode
    private let defaults: UserDefaults
    private var product: Product?
    private var updatesTask: Task<Void, Never>?
    private var entitlementRevision: UInt64 = 0
    private var hasStarted = false
    // Metadata retries may dismiss their own warning, never an ownership or
    // checkout result delivered while the request was in flight.
    private var productAvailabilityMessage: String?
    // A view supplied by the visible unlock sheet, rather than UIApplication's
    // windows, so the purchase sheet is anchored to this Messages extension.
    weak var purchasePresentationController: UIViewController?
    private static let localPurchaseKey = "studio.localSimulation.purchased"
    private static let localPendingKey = "studio.localSimulation.pending"
    private static let betaAccessKey = "studio.betaPreview.enabled"

    var isLocalTesting: Bool {
        #if STUDIO_SCREENSHOT_TESTING
        return false
        #else
        return mode != .disabled && mode != .appStore
        #endif
    }
    var isAppStoreRelease: Bool { mode == .appStore }
    private var isStoreKitMode: Bool {
        mode == .storeKit || mode == .sandboxStoreKit || mode == .appStore
    }
    private var usesPublicPurchaseCopy: Bool {
        #if STUDIO_SCREENSHOT_TESTING
        return true
        #else
        return isAppStoreRelease
        #endif
    }
    var isBetaTesting: Bool {
        #if STUDIO_BETA_TESTING
        return mode == .betaPreview
        #else
        return false
        #endif
    }
    var isSandboxTesting: Bool { mode == .sandboxStoreKit }
    var isUsingStoreKitTesting: Bool { mode == .storeKit }
    var canPurchase: Bool {
        mode != .disabled && (isBetaTesting || price != nil) && !isLoading && !isPurchasing && !isPending && !isUnlocked
    }
    var localTestingNote: String? {
        guard isLocalTesting else { return nil }
        if isBetaTesting { return "TestFlight preview — no payment or Apple purchase" }
        if isSandboxTesting { return "Apple sandbox test — no real charge. Test ownership does not unlock the public release." }
        return isUsingStoreKitTesting ? "Local StoreKit test — no charge" : "Local test — no charge"
    }

    init(localTesting: Bool = false, defaults: UserDefaults = .standard,
         useStoreKitTesting: Bool? = nil) {
        self.defaults = defaults
        #if STUDIO_SCREENSHOT_TESTING
        // Capture-only configuration: real verified Xcode StoreKit transactions,
        // with the same product UI as the public build. Never in a shipping archive.
        mode = localTesting ? .storeKit : .disabled
        #elseif STUDIO_APP_STORE
        // The legacy parameter gates composition, not the purchase environment.
        // StoreKit scopes its verified history to this installed app/store context.
        mode = localTesting ? .appStore : .disabled
        #elseif STUDIO_SANDBOX_TESTING
        // Never read local mock/free-beta ownership or attach Xcode's local store.
        mode = localTesting ? .sandboxStoreKit : .disabled
        #elseif STUDIO_BETA_TESTING
        mode = localTesting ? .betaPreview : .disabled
        if localTesting {
            isUnlocked = defaults.bool(forKey: Self.betaAccessKey)
        }
        #elseif DEBUG && STUDIO_LOCAL_TESTING
        if localTesting {
            let requested = useStoreKitTesting
                ?? (ProcessInfo.processInfo.environment["STUDIO_STOREKIT_TESTING"] == "1")
            mode = requested ? .storeKit : .simulated
            if mode == .simulated {
                // This preference is a mock purchase history, never a real entitlement.
                isUnlocked = defaults.bool(forKey: Self.localPurchaseKey)
                isPending = defaults.bool(forKey: Self.localPendingKey)
                price = "$1.00"
            }
        } else {
            mode = .disabled
        }
        #else
        mode = .disabled
        #endif
    }

    deinit { updatesTask?.cancel() }

    func start() async {
        guard mode != .disabled else {
            message = "Purchases are disabled in this build. Use the local testing app."
            return
        }
        // The startup task and an offer-sheet retry can reach this service at
        // once. Keep one metadata/restore operation in flight and one loading
        // indicator, rather than letting an older response replace a newer one.
        guard !isLoading, !isPurchasing else { return }
        if isBetaTesting {
            await refreshEntitlements()
            return
        }
        // A failed first price request must remain retryable from the offer sheet.
        if hasStarted && (!isStoreKitMode || product != nil) {
            await refreshEntitlements()
            return
        }
        hasStarted = true
        isLoading = true
        defer { isLoading = false }
        if mode == .simulated {
            await refreshEntitlements()
            return
        }
        startTransactionListener()
        await refreshEntitlements()
        do {
            product = try await Product.products(for: [Self.productID]).first {
                $0.id == Self.productID && $0.type == .nonConsumable
            }
            price = product?.displayPrice
            if product == nil {
                showProductAvailabilityMessage((isSandboxTesting || usesPublicPurchaseCopy)
                    ? "Studio Unlock is not available from Apple right now. Try again shortly; your drawings are safe."
                    : "The local test product is unavailable. Open the Local StoreKit scheme in Xcode and try again.")
            } else {
                if let productAvailabilityMessage, message == productAvailabilityMessage {
                    message = nil
                }
                productAvailabilityMessage = nil
            }
        } catch {
            // Product metadata availability is separate from verified tool access.
            showProductAvailabilityMessage((isSandboxTesting || usesPublicPurchaseCopy)
                ? "The price could not load. Check your connection and try again. Your saved work and existing access are unchanged."
                : "The local test price could not load. Your saved work and existing access are unchanged.")
        }
    }

    private func showProductAvailabilityMessage(_ text: String) {
        guard message == nil || message == productAvailabilityMessage else { return }
        message = text
        productAvailabilityMessage = text
    }

    /// False means verification is unresolved; callers must not describe that as
    /// an authoritative missing purchase or a successful restore.
    @discardableResult
    func refreshEntitlements() async -> Bool {
        switch mode {
        case .disabled:
            return false
        #if STUDIO_BETA_TESTING
        case .betaPreview:
            isUnlocked = defaults.bool(forKey: Self.betaAccessKey)
            isPending = false
            return true
        #endif
        case .simulated:
            isUnlocked = defaults.bool(forKey: Self.localPurchaseKey)
            isPending = defaults.bool(forKey: Self.localPendingKey)
            return true
        case .storeKit, .sandboxStoreKit, .appStore:
            let revision = entitlementRevision
            var found = false
            var unresolved = false
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction) where transaction.productID == Self.productID:
                    guard acceptsTransaction(transaction) else {
                        unresolved = true
                        continue
                    }
                    if transaction.revocationDate == nil { found = true }
                case .unverified(let transaction, _) where transaction.productID == Self.productID:
                    unresolved = true
                default:
                    continue
                }
            }
            guard revision == entitlementRevision else { return true }
            if unresolved {
                // A verification failure cannot newly grant access or revoke a known owner.
                message = "The purchase could not be verified. Try Restore Purchases; your drawings are safe."
                return false
            } else {
                // StoreKit supplies locally cached verified entitlements offline as well.
                // An authoritative empty snapshot reflects account/revocation changes.
                isUnlocked = found
                if found { isPending = false }
                return true
            }
        }
    }

    func purchase() async {
        guard mode != .disabled else {
            message = "Checkout is disabled. No purchase was attempted."
            return
        }
        guard !isPurchasing, !isLoading, !isPending else { return }
        guard !isUnlocked else {
            message = "Studio is already unlocked."
            return
        }
        if isBetaTesting {
            isPurchasing = true
            defaults.set(true, forKey: Self.betaAccessKey)
            isUnlocked = true
            isPending = false
            message = "Studio is enabled for this TestFlight beta. No payment was taken."
            isPurchasing = false
            return
        }
        #if DEBUG && STUDIO_LOCAL_TESTING
        if mode == .simulated {
            await simulate(.success)
            return
        }
        #endif
        guard let product else {
            message = (isSandboxTesting || usesPublicPurchaseCopy)
                ? "Studio Unlock is unavailable from Apple. Try loading the price again."
                : "The local test product is unavailable. Try loading it again."
            return
        }
        isPurchasing = true
        message = nil
        defer { isPurchasing = false }
        do {
            let result: Product.PurchaseResult
            if #available(iOS 18.2, *), let presenter = purchasePresentationController,
               presenter.viewIfLoaded?.window != nil {
                result = try await product.purchase(confirmIn: presenter)
            } else if #available(iOS 17.0, *),
                      let scene = purchasePresentationController?.viewIfLoaded?.window?.windowScene {
                result = try await product.purchase(confirmIn: scene)
            } else {
                // Earlier supported systems only expose the original overload;
                // headless StoreKit unit sessions also take this path.
                result = try await product.purchase()
            }
            switch result {
            case .success(let result):
                await receive(result)
            case .userCancelled:
                message = nil
            case .pending:
                isPending = true
                message = "Purchase approval is pending. You can keep using all included stickers."
            @unknown default:
                message = "The purchase is not complete. You can try again."
            }
        } catch {
            message = usesPublicPurchaseCopy
                ? "The purchase could not complete. Please try again. Your drawings are safe."
                : (isSandboxTesting
                   ? "The sandbox purchase could not complete. Try again; no real payment is made in TestFlight."
                   : "The local test purchase could not complete. Try again.")
        }
    }

    /// Invoke only from the user's Restore Purchases action; sync may display authentication.
    func restore() async {
        guard mode != .disabled else {
            message = "Restore is disabled outside the local testing app."
            return
        }
        guard !isPurchasing, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        if isBetaTesting {
            await refreshEntitlements()
            message = isUnlocked ? "Beta access restored on this device."
                : "No beta access is saved on this device. You can enable Studio free for this beta."
            return
        }
        if mode == .simulated {
            await refreshEntitlements()
            message = isUnlocked ? "Local purchase restored. Studio is unlocked."
                : "No local Studio purchase found. No payment was taken."
            return
        }
        do {
            try await AppStore.sync()
            guard await refreshEntitlements() else { return }
            message = isUnlocked ? "Studio purchase restored."
                : (usesPublicPurchaseCopy ? "No Studio purchase was found for this Apple Account."
                   : "No Studio purchase found for this test account.")
        } catch {
            message = "Restore could not complete. Try again; your existing work is safe."
        }
    }

    private func startTransactionListener() {
        guard isStoreKitMode, updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled, let self else { return }
                await self.receive(result)
            }
        }
    }

    private func receive(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard transaction.productID == Self.productID else { return }
            guard acceptsTransaction(transaction) else {
                message = usesPublicPurchaseCopy
                    ? "This purchase could not be verified for Studio. No new access was granted."
                    : (isSandboxTesting
                       ? "This transaction is not from Apple's sandbox. No access was granted."
                       : "A nonlocal transaction was blocked. This build only supports local tests.")
                return
            }
            entitlementRevision &+= 1
            isPending = false
            isUnlocked = transaction.revocationDate == nil
            message = isUnlocked
                ? (usesPublicPurchaseCopy ? "Studio is unlocked. Have fun creating!"
                   : (isSandboxTesting ? "Sandbox purchase complete. Studio is unlocked for testing." : "Local test complete. Studio is unlocked."))
                : "Studio access was revoked. Your saved drawings remain available to view and export."
            // Access is delivered first. Repeated deliveries and refund updates are idempotent.
            await transaction.finish()
        case .unverified(let transaction, _):
            guard transaction.productID == Self.productID else { return }
            message = "The purchase could not be verified. No new access was granted."
        }
    }

    private func acceptsTransaction(_ transaction: Transaction) -> Bool {
        // This function is reached only after StoreKit signature verification.
        if mode == .appStore && !acceptsAppStoreIdentity(
            appBundleID: transaction.appBundleID, productID: transaction.productID,
            productType: transaction.productType) { return false }
        if #available(iOS 16.0, *) {
            return acceptsTransactionEnvironment(transaction.environment.rawValue)
        }
        // iOS 15 exposes the same signed environment field as a string; missing
        // or unknown values fail closed instead of granting test ownership.
        return acceptsTransactionEnvironment(transaction.environmentStringRepresentation)
    }

    func acceptsTransactionEnvironment(_ environment: String) -> Bool {
        switch mode {
        case .storeKit: return environment.lowercased() == "xcode"
        case .sandboxStoreKit: return environment.lowercased() == "sandbox"
        case .appStore:
            // Apple uses sandbox for App Review/TestFlight and production for sale.
            // Access always comes from the current install's verified StoreKit
            // history; no persistent beta flag can migrate test access into sale.
            return ["production", "sandbox"].contains(environment.lowercased())
        default: return false
        }
    }

    func acceptsAppStoreIdentity(appBundleID: String, productID: String,
                                 productType: Product.ProductType) -> Bool {
        mode == .appStore && appBundleID == Self.appBundleID
            && productID == Self.productID && productType == .nonConsumable
    }

    #if DEBUG && STUDIO_LOCAL_TESTING
    enum LocalScenario: String, CaseIterable, Identifiable {
        case success, cancelled, pending, failure
        var id: String { rawValue }
    }

    /// Deterministic local checkout for testing without Xcode's StoreKit launch session.
    /// It cannot run in the StoreKit mode or in a normal/release build.
    func simulate(_ scenario: LocalScenario) async {
        guard mode == .simulated, !isPurchasing else { return }
        isPurchasing = true
        message = nil
        defer { isPurchasing = false }
        do { try await Task.sleep(nanoseconds: 150_000_000) }
        catch { return }
        switch scenario {
        case .success:
            setLocalOwnership(true)
            message = "Local test complete. Studio is unlocked. No charge."
        case .cancelled:
            // Cancel preserves any prior purchase and does not surface an error.
            message = nil
        case .pending:
            isPending = true
            defaults.set(true, forKey: Self.localPendingKey)
            message = "Test approval is pending. All included stickers still work."
        case .failure:
            message = "Test purchase failed. No charge. You can try again."
        }
    }

    func resetLocalPurchase() {
        guard mode == .simulated else { return }
        setLocalOwnership(false)
        message = "Local purchase reset. Your drafts and favorites were kept."
    }

    func approveLocalPending() {
        guard mode == .simulated, isPending else { return }
        setLocalOwnership(true)
        message = "Test purchase approved. Studio is unlocked."
    }

    func revokeLocalPurchase() {
        guard mode == .simulated else { return }
        setLocalOwnership(false)
        message = "Test purchase revoked. Your drawings remain available to view and export."
    }

    private func setLocalOwnership(_ value: Bool) {
        isUnlocked = value
        isPending = false
        defaults.set(value, forKey: Self.localPurchaseKey)
        defaults.set(false, forKey: Self.localPendingKey)
    }
    #endif
}
