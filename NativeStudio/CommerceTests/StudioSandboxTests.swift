import StoreKit
import StoreKitTest
import XCTest
@testable import StudioLocal

#if STUDIO_SANDBOX_TESTING
/// These verify the sandbox policy and isolation. They do not claim a transaction
/// against Apple's live sandbox service; that requires TestFlight on a device.
@MainActor
final class StudioSandboxTests: XCTestCase {
    private var suite: String!
    private var preferences: UserDefaults!

    override func setUp() {
        super.setUp()
        suite = "StudioSandboxTests.\(UUID().uuidString)"
        preferences = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        preferences.removePersistentDomain(forName: suite)
        preferences = nil
        suite = nil
        super.tearDown()
    }

    func testSandboxConfigurationRequiresStoreKitMetadataAndVerifiedOwnership() {
        preferences.set(true, forKey: "studio.localSimulation.purchased")
        preferences.set(true, forKey: "studio.localSimulation.pending")
        preferences.set(true, forKey: "studio.betaPreview.enabled")
        let store = StudioPurchaseStore(localTesting: true, defaults: preferences,
                                        useStoreKitTesting: true)
        XCTAssertTrue(store.isSandboxTesting)
        XCTAssertFalse(store.isBetaTesting)
        XCTAssertFalse(store.isUsingStoreKitTesting, "Sandbox must never select the Xcode-local mode")
        XCTAssertFalse(store.isUnlocked, "Mock and free-beta records cannot grant sandbox ownership")
        XCTAssertFalse(store.isPending)
        XCTAssertNil(store.price, "Never hard-code a test price instead of Apple's localized metadata")
        XCTAssertFalse(store.canPurchase, "Wait for Apple product metadata before offering checkout")
    }

    func testSandboxEnvironmentPolicyRejectsProductionXcodeAndMissingEnvironment() {
        let store = StudioPurchaseStore(localTesting: true, defaults: preferences)
        XCTAssertTrue(store.acceptsTransactionEnvironment("Sandbox"))
        XCTAssertTrue(store.acceptsTransactionEnvironment("sandbox"))
        for environment in ["Production", "production", "Xcode", "", "unknown", " Sandbox "] {
            XCTAssertFalse(store.acceptsTransactionEnvironment(environment), environment)
        }
    }

    func testDisabledConfigurationCannotGrantSandboxAccess() async {
        preferences.set("Keep this drawing", forKey: "drawingSentinel")
        let store = StudioPurchaseStore(localTesting: false, defaults: preferences)
        await store.start()
        await store.purchase()
        await store.restore()
        XCTAssertFalse(store.isSandboxTesting)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertFalse(store.canPurchase)
        XCTAssertFalse(store.acceptsTransactionEnvironment("Sandbox"))
        XCTAssertEqual(preferences.string(forKey: "drawingSentinel"), "Keep this drawing")
    }

    func testVerifiedXcodeTransactionCannotUnlockSandboxBuild() async throws {
        // Exercise the real signature-verified receive path with a transaction
        // from the wrong test environment. No Apple sandbox transaction is made.
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        preferences.set("Keep this drawing", forKey: "drawingSentinel")
        defer { session.clearTransactions() }

        let store = StudioPurchaseStore(localTesting: true, defaults: preferences)
        await store.start()
        XCTAssertNotNil(store.price, "The Xcode-local configuration supplies metadata for this test only")
        XCTAssertTrue(store.canPurchase)
        await store.purchase()
        XCTAssertFalse(store.isUnlocked, "A verified Xcode transaction is still not a sandbox transaction")
        XCTAssertTrue(store.message?.contains("not from Apple's sandbox") == true)
        XCTAssertNil(preferences.object(forKey: "studio.betaPreview.enabled"))
        XCTAssertNil(preferences.object(forKey: "studio.localSimulation.purchased"))
        XCTAssertEqual(preferences.string(forKey: "drawingSentinel"), "Keep this drawing")
    }
}
#endif
