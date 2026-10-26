import XCTest
@testable import StudioLocal

#if STUDIO_BETA_TESTING
@MainActor
final class StudioBetaAccessTests: XCTestCase {
    private var suite: String!
    private var preferences: UserDefaults!

    override func setUp() {
        super.setUp()
        suite = "StudioBetaAccessTests.\(UUID().uuidString)"
        preferences = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        preferences.removePersistentDomain(forName: suite)
        preferences = nil
        suite = nil
        super.tearDown()
    }

    private func makeBetaStore() -> StudioPurchaseStore {
        // Even an explicit StoreKit request cannot select StoreKit in the beta build.
        StudioPurchaseStore(localTesting: true, defaults: preferences, useStoreKitTesting: true)
    }

    func testFreshBetaHasFreeActivationWithoutProductMetadata() async {
        let store = makeBetaStore()
        await store.start()
        XCTAssertTrue(store.isBetaTesting)
        XCTAssertTrue(store.isLocalTesting)
        XCTAssertFalse(store.isUsingStoreKitTesting)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertNil(store.price)
        XCTAssertTrue(store.canPurchase, "Free beta activation must not wait for an App Store product")
        XCTAssertFalse(store.isLoading)
        XCTAssertFalse(store.isPending)
        await store.restore()
        XCTAssertFalse(store.isUnlocked, "Restore cannot invent a previous beta activation")
        XCTAssertTrue(store.message?.contains("enable Studio free") == true)
        XCTAssertTrue(store.canPurchase)
    }

    func testBetaActivationPersistsAndRestoresOnThisDevice() async {
        let store = makeBetaStore()
        await store.start()
        await store.purchase()
        XCTAssertTrue(store.isUnlocked)
        XCTAssertFalse(store.canPurchase)
        XCTAssertFalse(store.isPurchasing)
        XCTAssertNil(store.price)
        XCTAssertTrue(preferences.bool(forKey: "studio.betaPreview.enabled"))
        XCTAssertNil(preferences.object(forKey: "studio.localSimulation.purchased"))

        let reopened = makeBetaStore()
        await reopened.start()
        await reopened.restore()
        XCTAssertTrue(reopened.isUnlocked)
        XCTAssertEqual(reopened.message, "Beta access restored on this device.")
        XCTAssertFalse(reopened.isUsingStoreKitTesting)
    }

    func testDisabledInitializationCannotReadOrGrantBetaAccess() async {
        preferences.set(true, forKey: "studio.betaPreview.enabled")
        let store = StudioPurchaseStore(localTesting: false, defaults: preferences)
        await store.start()
        await store.purchase()
        await store.restore()
        XCTAssertFalse(store.isBetaTesting)
        XCTAssertFalse(store.isLocalTesting)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertFalse(store.canPurchase)
        XCTAssertNil(store.price)
        XCTAssertTrue(preferences.bool(forKey: "studio.betaPreview.enabled"), "Disabled access must not erase the beta record")
    }

    func testBetaOwnershipIsSeparateAndPreservesSavedWork() async {
        preferences.set(true, forKey: "studio.localSimulation.purchased")
        preferences.set(true, forKey: "studio.localSimulation.pending")
        preferences.set("Keep this drawing", forKey: "drawingSentinel")
        let store = makeBetaStore()
        await store.start()
        XCTAssertFalse(store.isUnlocked, "Local mock ownership is not a beta entitlement")
        XCTAssertFalse(store.isPending)
        await store.purchase()
        await store.purchase()
        XCTAssertTrue(store.isUnlocked, "Repeated activation must be harmless")
        preferences.set(false, forKey: "studio.betaPreview.enabled")
        await store.restore()
        XCTAssertFalse(store.isUnlocked)
        XCTAssertEqual(preferences.string(forKey: "drawingSentinel"), "Keep this drawing")
        XCTAssertTrue(preferences.bool(forKey: "studio.localSimulation.purchased"))
    }
}
#endif
