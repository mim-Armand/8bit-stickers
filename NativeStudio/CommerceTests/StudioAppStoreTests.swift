import StoreKit
import StoreKitTest
import XCTest
@testable import StudioLocal

#if STUDIO_APP_STORE
/// Local checks of the shipping adapter. These do not create a production purchase
/// or claim a successful transaction against Apple's remote sandbox.
@MainActor
final class StudioAppStoreTests: XCTestCase {
    private var suite: String!
    private var preferences: UserDefaults!

    override func setUp() {
        super.setUp()
        suite = "StudioAppStoreTests.\(UUID().uuidString)"
        preferences = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        preferences.removePersistentDomain(forName: suite)
        preferences = nil
        suite = nil
        super.tearDown()
    }

    private func makeStore() -> StudioPurchaseStore {
        // Even an explicit Xcode-local mode request cannot override this build.
        StudioPurchaseStore(localTesting: true, defaults: preferences,
                            useStoreKitTesting: true)
    }

    func testPublicAdapterIgnoresEveryMockAndBetaOwnershipFlag() {
        preferences.set(true, forKey: "studio.localSimulation.purchased")
        preferences.set(true, forKey: "studio.localSimulation.pending")
        preferences.set(true, forKey: "studio.betaPreview.enabled")
        let store = makeStore()
        XCTAssertTrue(store.isAppStoreRelease)
        XCTAssertFalse(store.isLocalTesting)
        XCTAssertFalse(store.isBetaTesting)
        XCTAssertFalse(store.isSandboxTesting)
        XCTAssertFalse(store.isUsingStoreKitTesting)
        XCTAssertNil(store.localTestingNote)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertFalse(store.isPending)
        XCTAssertNil(store.price)
        XCTAssertFalse(store.canPurchase, "Wait for Apple's localized non-consumable product")
    }

    func testPublicEnvironmentPolicySupportsAppleReviewAndSaleButRejectsXcode() {
        let store = makeStore()
        for environment in ["Production", "production", "Sandbox", "sandbox"] {
            XCTAssertTrue(store.acceptsTransactionEnvironment(environment), environment)
        }
        for environment in ["Xcode", "", "unknown", " Production ", " sandbox "] {
            XCTAssertFalse(store.acceptsTransactionEnvironment(environment), environment)
        }
    }

    func testPublicIdentityPolicyRequiresThePublishedAppAndExactNonConsumable() {
        let store = makeStore()
        XCTAssertTrue(store.acceptsAppStoreIdentity(
            appBundleID: "eu.armand.--bit-art", productID: StudioPurchaseStore.productID,
            productType: .nonConsumable))
        XCTAssertFalse(store.acceptsAppStoreIdentity(
            appBundleID: "eu.armand.pixelstudio.local", productID: StudioPurchaseStore.productID,
            productType: .nonConsumable))
        XCTAssertFalse(store.acceptsAppStoreIdentity(
            appBundleID: StudioPurchaseStore.appBundleID, productID: "another.product",
            productType: .nonConsumable))
        XCTAssertFalse(store.acceptsAppStoreIdentity(
            appBundleID: StudioPurchaseStore.appBundleID, productID: StudioPurchaseStore.productID,
            productType: .consumable))
        XCTAssertFalse(store.acceptsAppStoreIdentity(
            appBundleID: StudioPurchaseStore.appBundleID, productID: StudioPurchaseStore.productID,
            productType: .autoRenewable))
    }

    func testPublicAdapterRejectsRealVerifiedXcodePurchaseWithoutChangingWork() async throws {
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        preferences.set("Keep this drawing", forKey: "drawingSentinel")
        defer { session.clearTransactions() }

        let store = makeStore()
        await store.start()
        XCTAssertNotNil(store.price, "The fixture supplies metadata, never public ownership")
        XCTAssertTrue(store.canPurchase, "Public checkout must not depend on a testing banner")
        await store.purchase()
        XCTAssertFalse(store.isUnlocked, "The shipping adapter must reject local Xcode ownership")
        XCTAssertTrue(store.message?.contains("could not be verified") == true)
        XCTAssertNil(preferences.object(forKey: "studio.localSimulation.purchased"))
        XCTAssertNil(preferences.object(forKey: "studio.betaPreview.enabled"))
        XCTAssertEqual(preferences.string(forKey: "drawingSentinel"), "Keep this drawing")
        let reconciled = await store.refreshEntitlements()
        XCTAssertFalse(reconciled, "A transaction from the wrong context is unresolved, not an authoritative empty history")
        XCTAssertFalse(store.isUnlocked)
        await store.restore()
        XCTAssertFalse(store.isUnlocked)
        XCTAssertTrue(store.message?.contains("could not be verified") == true,
                      "Restore must retain the verification error instead of claiming a successful restore or missing purchase")
    }

    func testPriceRecoversAfterAppleCatalogInitiallyHasNoProduct() async throws {
        // Change only the test catalog. This reproduces Apple's successful but
        // empty lookup without a shipping product override or ownership bypass.
        let fixtureURL = try XCTUnwrap(Bundle.main.url(forResource: "Studio", withExtension: "storekit"))
        var fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: fixtureURL)) as? [String: Any])
        fixture["products"] = []
        let emptyURL = FileManager.default.temporaryDirectory.appendingPathComponent("EmptyStudio-\(UUID().uuidString).storekit")
        try JSONSerialization.data(withJSONObject: fixture).write(to: emptyURL)
        defer { try? FileManager.default.removeItem(at: emptyURL) }
        let emptySession = try SKTestSession(contentsOf: emptyURL)
        emptySession.resetToDefaultState()
        emptySession.clearTransactions()

        let store = makeStore()
        preferences.set("Keep this drawing", forKey: "drawingSentinel")
        await store.start()
        XCTAssertNil(store.price)
        XCTAssertFalse(store.canPurchase)
        XCTAssertTrue(store.message?.contains("not available from Apple") == true)

        let availableSession = try SKTestSession(configurationFileNamed: "Studio")
        availableSession.resetToDefaultState()
        availableSession.clearTransactions()
        defer { availableSession.clearTransactions() }
        await store.start()
        XCTAssertNotNil(store.price, "A retry must request Apple's catalog again after an empty result")
        XCTAssertTrue(store.canPurchase)
        XCTAssertNil(store.message, "A recovered price must dismiss its stale unavailability warning")
        XCTAssertFalse(store.isUnlocked, "Product metadata alone never establishes purchase ownership")
        XCTAssertEqual(preferences.string(forKey: "drawingSentinel"), "Keep this drawing")
    }

    func testPriceRecoversAfterStoreKitNetworkFailure() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("StoreKit error simulation requires iOS 17") }
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        defer { session.resetToDefaultState(); session.clearTransactions() }
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)

        let store = makeStore()
        await store.start()
        XCTAssertNil(store.price)
        XCTAssertFalse(store.canPurchase)
        XCTAssertTrue(store.message?.contains("price could not load") == true)
        XCTAssertFalse(store.isLoading)

        try await session.setSimulatedError(nil, forAPI: .loadProducts)
        await store.start()
        XCTAssertNotNil(store.price)
        XCTAssertTrue(store.canPurchase)
        XCTAssertNil(store.message)
        XCTAssertFalse(store.isUnlocked)
    }

    func testPriceFailureAndRecoveryKeepUnresolvedPurchaseVisible() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("StoreKit error simulation requires iOS 17") }
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        defer { session.resetToDefaultState(); session.clearTransactions() }
        // The production adapter intentionally rejects Xcode ownership. Its
        // verification notice must survive both failure and recovery of pricing.
        _ = try await session.buyProduct(identifier: StudioPurchaseStore.productID)
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        let store = makeStore()
        await store.start()
        XCTAssertNil(store.price)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertTrue(store.message?.contains("could not be verified") == true)

        try await session.setSimulatedError(nil, forAPI: .loadProducts)
        await store.start()
        XCTAssertNotNil(store.price)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertTrue(store.message?.contains("could not be verified") == true,
                      "Loading metadata cannot resolve or hide an ownership verification failure")
    }
}
#endif

#if STUDIO_SCREENSHOT_TESTING
/// Only the nonshipping capture configuration accepts this verified Xcode purchase.
@MainActor
final class StudioScreenshotPurchaseTests: XCTestCase {
    func testCaptureUsesPublicUIWithVerifiedXcodeOwnership() async throws {
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        let suite = "StudioScreenshotPurchaseTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer {
            session.clearTransactions()
            preferences.removePersistentDomain(forName: suite)
        }
        let store = StudioPurchaseStore(localTesting: true, defaults: preferences)
        XCTAssertFalse(store.isAppStoreRelease)
        XCTAssertFalse(store.isLocalTesting, "Capture shows the public interface without a testing banner")
        XCTAssertTrue(store.isUsingStoreKitTesting)
        XCTAssertNil(store.localTestingNote)
        XCTAssertFalse(store.isUnlocked)
        await store.start()
        XCTAssertTrue(store.canPurchase)
        await store.purchase()
        XCTAssertTrue(store.isUnlocked, store.message ?? "A signature-verified Xcode transaction should unlock only the capture build")
        XCTAssertEqual(store.message, "Studio is unlocked. Have fun creating!")
        XCTAssertNil(preferences.object(forKey: "studio.localSimulation.purchased"))
        XCTAssertNil(preferences.object(forKey: "studio.betaPreview.enabled"))
    }
}
#endif

#if !DEBUG && !STUDIO_APP_STORE && !STUDIO_BETA_TESTING && !STUDIO_SANDBOX_TESTING && !STUDIO_SCREENSHOT_TESTING
@MainActor
final class StudioUnconfiguredReleaseTests: XCTestCase {
    func testOrdinaryReleaseCannotEnableCheckoutThroughLegacyTestingArgument() async throws {
        let suite = "StudioUnconfiguredReleaseTests.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        preferences.set(true, forKey: "studio.localSimulation.purchased")
        preferences.set(true, forKey: "studio.betaPreview.enabled")
        defer { preferences.removePersistentDomain(forName: suite) }
        let store = StudioPurchaseStore(localTesting: true, defaults: preferences,
                                        useStoreKitTesting: true)
        await store.start()
        await store.purchase()
        await store.restore()
        XCTAssertFalse(store.isAppStoreRelease)
        XCTAssertFalse(store.isUsingStoreKitTesting)
        XCTAssertFalse(store.isLocalTesting)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertFalse(store.canPurchase)
        XCTAssertNil(store.price)
    }
}
#endif
