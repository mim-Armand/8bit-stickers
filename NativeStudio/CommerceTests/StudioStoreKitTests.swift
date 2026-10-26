import StoreKit
import StoreKitTest
import XCTest
@testable import StudioLocal

/// Runs only against the bundled, local Studio.storekit configuration.
/// SKTestSession activates Xcode's store; no App Store Connect product is needed.
@MainActor
final class StudioStoreKitTests: XCTestCase {
    #if DEBUG && STUDIO_LOCAL_TESTING
    func testLocalStoreKitPurchaseRestoreAndRefund() async throws {
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.storefront = "USA"
        session.locale = Locale(identifier: "en_US")
        let suite = "StudioStoreKitTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        preferences.set("Keep my drawing", forKey: "drawingSentinel")
        defer {
            session.clearTransactions()
            preferences.removePersistentDomain(forName: suite)
        }

        let products = try await Product.products(for: [StudioPurchaseStore.productID])
        let product = try XCTUnwrap(products.first, "The bundled Studio.storekit product must load")
        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertEqual(product.price, Decimal(1), "The local test price is $1.00; this does not verify a production price point")

        let store = StudioPurchaseStore(localTesting: true, defaults: preferences,
                                        useStoreKitTesting: true)
        await store.start()
        XCTAssertTrue(store.isUsingStoreKitTesting)
        XCTAssertEqual(store.price, product.displayPrice)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertTrue(store.canPurchase)
        await store.purchase()
        for _ in 0..<50 where !store.isUnlocked {
            try await Task.sleep(nanoseconds: 100_000_000)
            await store.refreshEntitlements()
        }
        XCTAssertTrue(store.isUnlocked, store.message ?? "The verified local purchase should grant Studio")
        XCTAssertFalse(store.isPurchasing)
        XCTAssertFalse(store.canPurchase)

        var verifiedTransaction: Transaction?
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == StudioPurchaseStore.productID {
                verifiedTransaction = transaction
            }
        }
        let entitlement = try XCTUnwrap(verifiedTransaction)
        if #available(iOS 16.0, *) {
            XCTAssertEqual(entitlement.environment, .xcode)
        }
        XCTAssertNil(entitlement.revocationDate)
        XCTAssertNil(preferences.object(forKey: "studio.localSimulation.purchased"),
                     "Real StoreKit testing must not grant ownership through a mock preference")

        let reopenedStore = StudioPurchaseStore(localTesting: true, defaults: preferences,
                                                useStoreKitTesting: true)
        await reopenedStore.start()
        XCTAssertTrue(reopenedStore.isUnlocked, "A new service instance reads StoreKit ownership")
        await reopenedStore.restore()
        XCTAssertTrue(reopenedStore.isUnlocked)
        XCTAssertEqual(reopenedStore.message, "Studio purchase restored.")

        let transaction = try XCTUnwrap(session.allTransactions().first {
            $0.productIdentifier == StudioPurchaseStore.productID
        })
        try session.refundTransaction(identifier: transaction.identifier)
        for _ in 0..<50 {
            await reopenedStore.refreshEntitlements()
            if !reopenedStore.isUnlocked { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertFalse(reopenedStore.isUnlocked, "Refund must remove the verified StoreKit entitlement")
        XCTAssertEqual(preferences.string(forKey: "drawingSentinel"), "Keep my drawing",
                       "Refund processing must not remove unrelated saved work")
    }
    #endif
}
