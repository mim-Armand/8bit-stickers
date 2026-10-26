import Combine
import Foundation
import StoreKit

/// This iteration is deliberately local-only. A normal build cannot initiate a purchase.
/// DEBUG + STUDIO_LOCAL_TESTING enables either the deterministic simulator or, when
/// explicitly requested by the Xcode scheme, the local StoreKit configuration.
@MainActor
final class StudioPurchaseStore: ObservableObject {
    static let productID = "eu.armand.--bit-art.studio.unlock"

    @Published private(set) var isUnlocked = false
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isPending = false
    @Published var message: String?
    @Published private(set) var price: String?

    private enum Mode { case disabled, simulated, storeKit }
    private let mode: Mode
    private let defaults: UserDefaults
    private var product: Product?
    private var updatesTask: Task<Void, Never>?
    private var entitlementRevision: UInt64 = 0
    private var hasStarted = false
    private static let localPurchaseKey = "studio.localSimulation.purchased"
    private static let localPendingKey = "studio.localSimulation.pending"

    var isLocalTesting: Bool { mode != .disabled }
    var isUsingStoreKitTesting: Bool { mode == .storeKit }
    var canPurchase: Bool {
        isLocalTesting && price != nil && !isLoading && !isPurchasing && !isPending && !isUnlocked
    }
    var localTestingNote: String? {
        guard isLocalTesting else { return nil }
        return isUsingStoreKitTesting ? "Local StoreKit test — no charge" : "Local test — no charge"
    }

    init(localTesting: Bool = false, defaults: UserDefaults = .standard,
         useStoreKitTesting: Bool? = nil) {
        self.defaults = defaults
        #if DEBUG && STUDIO_LOCAL_TESTING
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
        // A failed first price request must remain retryable from the offer sheet.
        if hasStarted && (mode != .storeKit || product != nil) {
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
            product = try await Product.products(for: [Self.productID]).first
            price = product?.displayPrice
            if product == nil {
                message = "The local test product is unavailable. Open the Local StoreKit scheme in Xcode and try again."
            }
        } catch {
            // Product metadata availability is separate from verified tool access.
            message = "The local test price could not load. Your saved work and existing access are unchanged."
        }
    }

    func refreshEntitlements() async {
        switch mode {
        case .disabled:
            return
        case .simulated:
            isUnlocked = defaults.bool(forKey: Self.localPurchaseKey)
            isPending = defaults.bool(forKey: Self.localPendingKey)
        case .storeKit:
            let revision = entitlementRevision
            var found = false
            var unresolved = false
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction) where transaction.productID == Self.productID:
                    guard isLocalTransaction(transaction) else {
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
            guard revision == entitlementRevision else { return }
            if unresolved {
                // A verification failure cannot newly grant access or revoke a known owner.
                message = "The test purchase could not be verified. Try Restore Purchases; your drawings are safe."
            } else {
                // StoreKit supplies locally cached verified entitlements offline as well.
                // An authoritative empty snapshot reflects account/revocation changes.
                isUnlocked = found
                if found { isPending = false }
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
        #if DEBUG && STUDIO_LOCAL_TESTING
        if mode == .simulated {
            await simulate(.success)
            return
        }
        #endif
        guard let product else {
            message = "The local test product is unavailable. Try loading it again."
            return
        }
        isPurchasing = true
        message = nil
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await receive(result)
            case .userCancelled:
                message = nil
            case .pending:
                isPending = true
                message = "Purchase approval is pending. You can keep using all included stickers."
            @unknown default:
                message = "The test purchase is not complete. You can try again."
            }
        } catch {
            message = "The local test purchase could not complete. Try again."
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
        if mode == .simulated {
            await refreshEntitlements()
            message = isUnlocked ? "Local purchase restored. Studio is unlocked."
                : "No local Studio purchase found. No payment was taken."
            return
        }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = isUnlocked ? "Studio purchase restored."
                : "No Studio purchase found for this test account."
        } catch {
            message = "Restore could not complete. Try again; your existing work is safe."
        }
    }

    private func startTransactionListener() {
        guard mode == .storeKit, updatesTask == nil else { return }
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
            guard isLocalTransaction(transaction) else {
                message = "A nonlocal transaction was blocked. This build only supports local tests."
                return
            }
            entitlementRevision &+= 1
            isPending = false
            isUnlocked = transaction.revocationDate == nil
            message = isUnlocked ? "Local test complete. Studio is unlocked."
                : "Test purchase revoked. Your saved drawings remain available to view and export."
            // Access is delivered first. Repeated deliveries and refund updates are idempotent.
            await transaction.finish()
        case .unverified(let transaction, _):
            guard transaction.productID == Self.productID else { return }
            message = "The test purchase could not be verified. No new access was granted."
        }
    }

    private func isLocalTransaction(_ transaction: Transaction) -> Bool {
        guard mode == .storeKit else { return false }
        if #available(iOS 16.0, *) {
            return transaction.environment == .xcode
        }
        return transaction.environmentStringRepresentation.lowercased() == "xcode"
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
