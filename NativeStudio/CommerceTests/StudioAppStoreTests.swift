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

    #if STUDIO_PURCHASE_DIAGNOSTICS
    private func initialReport(_ store: StudioPurchaseStore) throws -> [String: Any] {
        let text = try XCTUnwrap(store.initialPriceAvailabilityReport)
        let data = try XCTUnwrap(text.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testInitialPriceReportRecordsUnownedLookupAndPersistsForThisBuild() async throws {
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        defer { session.resetToDefaultState(); session.clearTransactions() }
        preferences.set(true, forKey: "studio.localSimulation.purchased")
        preferences.set(true, forKey: "studio.betaPreview.enabled")
        preferences.set("Keep this drawing", forKey: "drawingSentinel")
        let store = makeStore()
        XCTAssertNil(store.initialPriceAvailabilityReport)

        await store.start()

        let first = try initialReport(store)
        XCTAssertEqual(first["reportKind"] as? String, "initial-price-lookup")
        XCTAssertEqual(first["rawProductCount"] as? Int, 1)
        XCTAssertEqual(first["studioUnlockedBeforeRequest"] as? Bool, false,
                       "Mock/beta preferences cannot turn an unowned first lookup into an owned one")
        XCTAssertTrue(first["error"] is NSNull)
        XCTAssertNotNil(first["requestStartedAtUTC"] as? String)
        XCTAssertNotNil(first["requestCompletedAtUTC"] as? String)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(first["queryDurationSeconds"] as? Double), 0)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertNotNil(store.price, "Normal checkout still receives the real product metadata")
        XCTAssertTrue(store.canPurchase)
        XCTAssertFalse(store.isLoading)
        XCTAssertTrue(session.allTransactions().isEmpty)
        XCTAssertEqual(preferences.string(forKey: "drawingSentinel"), "Keep this drawing")

        let savedKeys = preferences.dictionaryRepresentation().keys.filter { $0.hasPrefix("studio.purchaseDiagnostics.initialPriceReport.") }
        XCTAssertEqual(savedKeys.count, 1)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        XCTAssertTrue(try XCTUnwrap(savedKeys.first).hasSuffix(".\(version).\(build)"))
        let recreated = makeStore()
        let restored = try initialReport(recreated)
        XCTAssertEqual(restored["requestStartedAtUTC"] as? String, first["requestStartedAtUTC"] as? String)
        XCTAssertEqual(restored["rawProductCount"] as? Int, 1)
        XCTAssertEqual(restored["studioUnlockedBeforeRequest"] as? Bool, false)
        XCTAssertNil(recreated.price, "Restoring diagnostic evidence does not restore a checkout product or ownership")
        XCTAssertFalse(recreated.isUnlocked)
    }

    func testInitialEmptyLookupSurvivesRetryManualProbeAndServiceRecreation() async throws {
        let fixtureURL = try XCTUnwrap(Bundle.main.url(forResource: "Studio", withExtension: "storekit"))
        var fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: fixtureURL)) as? [String: Any])
        fixture["products"] = []
        let emptyURL = FileManager.default.temporaryDirectory.appendingPathComponent("InitialEmptyStudio-\(UUID().uuidString).storekit")
        try JSONSerialization.data(withJSONObject: fixture).write(to: emptyURL)
        defer { try? FileManager.default.removeItem(at: emptyURL) }
        let emptySession = try SKTestSession(contentsOf: emptyURL)
        emptySession.resetToDefaultState()
        emptySession.clearTransactions()
        let store = makeStore()

        await store.start()
        let first = try initialReport(store)
        XCTAssertEqual(first["rawProductCount"] as? Int, 0)
        XCTAssertEqual(first["studioUnlockedBeforeRequest"] as? Bool, false)
        XCTAssertTrue(first["error"] is NSNull)
        XCTAssertNil(store.price)
        XCTAssertFalse(store.canPurchase)

        let availableSession = try SKTestSession(configurationFileNamed: "Studio")
        availableSession.resetToDefaultState()
        availableSession.clearTransactions()
        defer { availableSession.resetToDefaultState(); availableSession.clearTransactions() }
        await store.start()
        XCTAssertNotNil(store.price)
        XCTAssertTrue(store.canPurchase)
        await store.checkPurchaseAvailability()
        let manualText = try XCTUnwrap(store.purchaseAvailabilityReport)
        let manualData = try XCTUnwrap(manualText.data(using: .utf8))
        let manual = try XCTUnwrap(JSONSerialization.jsonObject(with: manualData) as? [String: Any])
        XCTAssertEqual(manual["rawProductCount"] as? Int, 1)
        XCTAssertEqual(try initialReport(store)["rawProductCount"] as? Int, 0,
                       "A later successful manual query must not replace the initial empty result")

        let recreated = makeStore()
        await recreated.start()
        let restored = try initialReport(recreated)
        XCTAssertEqual(restored["rawProductCount"] as? Int, 0)
        XCTAssertEqual(restored["requestStartedAtUTC"] as? String, first["requestStartedAtUTC"] as? String)
        XCTAssertEqual(restored["studioUnlockedBeforeRequest"] as? Bool, false)
        XCTAssertNotNil(recreated.price)
        XCTAssertFalse(recreated.isUnlocked)
        XCTAssertTrue(availableSession.allTransactions().isEmpty)
    }

    func testInitialLookupErrorSurvivesSuccessfulRetryAndRecreationWithoutPrivateDetails() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("StoreKit error simulation requires iOS 17") }
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        defer { session.resetToDefaultState(); session.clearTransactions() }
        let privateDetail = "PRIVATE_INITIAL_ERROR_DETAIL_MUST_NOT_APPEAR"
        let error = URLError(.notConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: privateDetail])
        try await session.setSimulatedError(.generic(.networkError(error)), forAPI: .loadProducts)
        let store = makeStore()

        await store.start()
        let first = try initialReport(store)
        let initialError = try XCTUnwrap(first["error"] as? [String: Any])
        XCTAssertEqual(Set(initialError.keys), Set(["domain", "code"]))
        XCTAssertFalse(try XCTUnwrap(store.initialPriceAvailabilityReport).contains(privateDetail))
        XCTAssertEqual(first["rawProductCount"] as? Int, 0)
        XCTAssertEqual(first["studioUnlockedBeforeRequest"] as? Bool, false)
        XCTAssertNil(store.price)

        try await session.setSimulatedError(nil, forAPI: .loadProducts)
        await store.start()
        XCTAssertNotNil(store.price)
        XCTAssertTrue(store.canPurchase)
        let recreated = makeStore()
        await recreated.start()
        let restored = try initialReport(recreated)
        let restoredError = try XCTUnwrap(restored["error"] as? [String: Any])
        XCTAssertEqual(restoredError["domain"] as? String, initialError["domain"] as? String)
        XCTAssertEqual(restoredError["code"] as? Int, initialError["code"] as? Int)
        XCTAssertEqual(restored["requestStartedAtUTC"] as? String, first["requestStartedAtUTC"] as? String)
        XCTAssertEqual(restored["rawProductCount"] as? Int, 0)
        XCTAssertFalse(try XCTUnwrap(recreated.initialPriceAvailabilityReport).contains(privateDetail))
        XCTAssertFalse(recreated.isUnlocked)
        XCTAssertNotNil(recreated.price)
        XCTAssertTrue(session.allTransactions().isEmpty)
    }

    func testDiagnosticReadReportsRawCatalogWithoutChangingCheckoutOrOwnership() async throws {
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        defer { session.resetToDefaultState(); session.clearTransactions() }
        let store = makeStore()
        store.message = "Preserve the existing notice"
        preferences.set("Keep this drawing", forKey: "drawingSentinel")

        await store.checkPurchaseAvailability()

        let text = try XCTUnwrap(store.purchaseAvailabilityReport)
        let data = try XCTUnwrap(text.data(using: .utf8))
        let report = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(report["rawProductCount"] as? Int, 1)
        let rawProducts = try XCTUnwrap(report["rawProducts"] as? [[String: String]])
        XCTAssertEqual(rawProducts.first?["id"], StudioPurchaseStore.productID)
        XCTAssertEqual(rawProducts.first?["type"], Product.ProductType.nonConsumable.rawValue)
        XCTAssertFalse(try XCTUnwrap(rawProducts.first?["localizedPrice"]).isEmpty)
        XCTAssertTrue(report["error"] is NSNull)
        XCTAssertNotNil(report["canMakePayments"] as? Bool)
        XCTAssertEqual(report["studioUnlocked"] as? Bool, false)
        XCTAssertTrue(store.purchaseAvailabilityStatus?.contains("Apple returned Studio Unlock") == true)
        XCTAssertFalse(store.isCheckingPurchaseAvailability)
        XCTAssertFalse(store.isUnlocked, "A catalog response cannot grant ownership")
        XCTAssertNil(store.price, "The diagnostic must not populate the checkout's cached product/price")
        XCTAssertFalse(store.canPurchase)
        XCTAssertFalse(store.isLoading)
        XCTAssertFalse(store.isPurchasing)
        XCTAssertEqual(store.message, "Preserve the existing notice")
        XCTAssertEqual(preferences.string(forKey: "drawingSentinel"), "Keep this drawing")
        XCTAssertTrue(session.allTransactions().isEmpty, "The diagnostic must not initiate checkout")
        XCTAssertEqual(Set(report.keys), Set(["reportVersion", "timestampUTC", "bundleID", "containingBundleID",
            "version", "build", "osVersion", "requestedProductID", "rawProductCount", "rawProducts",
            "canMakePayments", "studioUnlocked", "storefront", "error"]),
            "The copyable report must stay limited to approved non-personal diagnostic fields")
    }

    func testDiagnosticFailureIncludesOnlyErrorDomainAndCodeAndPreservesCheckoutState() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("StoreKit error simulation requires iOS 17") }
        let session = try SKTestSession(configurationFileNamed: "Studio")
        session.resetToDefaultState()
        session.clearTransactions()
        defer { session.resetToDefaultState(); session.clearTransactions() }
        let privateDetail = "PRIVATE_DESCRIPTION_MUST_NOT_APPEAR"
        let error = URLError(.notConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: privateDetail])
        try await session.setSimulatedError(.generic(.networkError(error)), forAPI: .loadProducts)
        let store = makeStore()
        store.message = "Preserve the existing notice"

        await store.checkPurchaseAvailability()

        let text = try XCTUnwrap(store.purchaseAvailabilityReport)
        let data = try XCTUnwrap(text.data(using: .utf8))
        let report = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let failure = try XCTUnwrap(report["error"] as? [String: Any])
        XCTAssertEqual(Set(failure.keys), Set(["domain", "code"]))
        XCTAssertNotNil(failure["domain"] as? String)
        XCTAssertNotNil(failure["code"] as? Int)
        XCTAssertFalse(text.contains(privateDetail), "Error descriptions/userInfo must not enter a copied report")
        XCTAssertEqual(report["rawProductCount"] as? Int, 0)
        XCTAssertTrue(store.purchaseAvailabilityStatus?.contains("lookup failed") == true)
        XCTAssertFalse(store.isCheckingPurchaseAvailability)
        XCTAssertFalse(store.isUnlocked)
        XCTAssertNil(store.price)
        XCTAssertFalse(store.canPurchase)
        XCTAssertEqual(store.message, "Preserve the existing notice")
        XCTAssertTrue(session.allTransactions().isEmpty)
    }
    #endif
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
