import XCTest
@testable import StudioLocal

@MainActor
final class StudioPurchaseStoreTests: XCTestCase {
    private var suite: String!
    private var preferences: UserDefaults!

    override func setUp() {
        super.setUp()
        suite = "StudioPurchaseTests.\(UUID().uuidString)"
        preferences = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        preferences.removePersistentDomain(forName: suite)
        preferences = nil
        suite = nil
        super.tearDown()
    }

    private func makeStore() -> StudioPurchaseStore {
        StudioPurchaseStore(localTesting: true, defaults: preferences, useStoreKitTesting: false)
    }

    #if DEBUG && STUDIO_LOCAL_TESTING
    func testOneTimeLocalPurchaseAndRelaunchRestore() async {
        let store = makeStore()
        await store.start()
        XCTAssertFalse(store.isUnlocked)
        XCTAssertTrue(store.canPurchase)
        XCTAssertEqual(store.price, "$1.00")
        await store.purchase()
        XCTAssertTrue(store.isUnlocked)
        XCTAssertFalse(store.canPurchase)
        XCTAssertFalse(store.isPurchasing)
        let relaunched = makeStore()
        await relaunched.restore()
        XCTAssertTrue(relaunched.isUnlocked)
        XCTAssertTrue(relaunched.message?.contains("restored") == true)
    }

    func testCancellationAndFailureDoNotGrantAccess() async {
        let store = makeStore()
        await store.simulate(.cancelled)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertNil(store.message)
        XCTAssertFalse(store.isPurchasing)
        await store.simulate(.failure)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertTrue(store.message?.contains("failed") == true)
        XCTAssertTrue(store.canPurchase)
    }

    func testPendingSurvivesRelaunchUntilApproval() async {
        let store = makeStore()
        await store.simulate(.pending)
        XCTAssertTrue(store.isPending)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertFalse(store.canPurchase)
        let relaunched = makeStore()
        await relaunched.start()
        XCTAssertTrue(relaunched.isPending)
        relaunched.approveLocalPending()
        XCTAssertTrue(relaunched.isUnlocked)
        XCTAssertFalse(relaunched.isPending)
    }

    func testRevocationAndResetOnlyChangeLocalPurchaseState() async {
        let store = makeStore()
        preferences.set("draft content", forKey: "unrelatedDraft")
        await store.purchase()
        store.revokeLocalPurchase()
        XCTAssertFalse(store.isUnlocked)
        XCTAssertEqual(preferences.string(forKey: "unrelatedDraft"), "draft content")
        await store.restore()
        XCTAssertFalse(store.isUnlocked)
        XCTAssertTrue(store.message?.contains("No local") == true)
        await store.purchase()
        store.resetLocalPurchase()
        XCTAssertFalse(store.isUnlocked)
        XCTAssertFalse(store.isPending)
        XCTAssertEqual(preferences.string(forKey: "unrelatedDraft"), "draft content")
    }

    func testCancellationCannotRevokeExistingOwnership() async {
        let store = makeStore()
        await store.purchase()
        await store.simulate(.cancelled)
        XCTAssertTrue(store.isUnlocked)
    }
    #endif

    func testNormalConfigurationFailsClosedWithoutCheckout() async {
        let store = StudioPurchaseStore(localTesting: false, defaults: preferences)
        await store.start()
        await store.purchase()
        await store.restore()
        XCTAssertFalse(store.isLocalTesting)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertNil(store.price)
        XCTAssertFalse(store.canPurchase)
        XCTAssertNotNil(store.message)
    }
}
