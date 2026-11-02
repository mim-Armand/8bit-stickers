# Studio sandbox investigation — November 2, 2026

**Current next step:** the owner has deferred additional TestFlight testing and requested focus on the released App Store failure. [The production investigation](studio-production-availability.md) verifies that the IAP is still unapproved and prepares a factual reply for the existing App Review conversation. That reply is unsent pending the explicit owner request required by project instructions. Build 13 and its private distribution remain intact; no account or ownership reset was performed. Neither sandbox nor production purchase success is newly claimed.

Apple rejected **1.4.1 (11)** under **Guideline 2.1(b)**. The reviewer’s **iPad Air 11-inch (M3), iPadOS 27.2** had an active internet connection but the Studio Unlock screen displayed **Price unavailable**. The attached screenshot shows the exact message emitted when StoreKit returns no matching non-consumable product.

Submission **4ab04eda-8610-4e9d-8552-8617b6a3f7e2** is now **UNRESOLVED_ISSUES**. The app item is **REJECTED**; the existing Studio Unlock metadata item remains **READY_FOR_REVIEW** in the same submission. Its parent IAP reports **READY_TO_SUBMIT**. Neither item has been removed, resubmitted or cancelled. Automatic release remains **AFTER_APPROVAL** for a future accepted submission.

The earlier diagnosis correctly identified that the purchase was omitted from the released 1.4 review, but was incomplete for the later sandbox failure. [Apple explicitly says sandbox review does not require prior IAP approval](https://developer.apple.com/help/app-review/before-submitting-for-review/configure-in-app-purchases/). Approval alone cannot establish that this reviewer lookup works. A successful local Xcode StoreKit session also cannot establish remote sandbox behavior.

## Verified configuration

Fresh checks on November 2 confirm:

- The product **eu.armand.bitart.studio.unlock / 6827336076** belongs to app **1366485724** and is **NON_CONSUMABLE**.
- English name/description are present and the IAP review image is COMPLETE.
- The current ongoing USA price is exactly **US$1.00**, with 174 localized automatic prices and the approved exact 175 territories. Family Sharing and automatic new territories are off.
- Paid Apps Agreement, bank account and tax forms are **Active**, without pending action.
- Registered host **eu.armand.--bit-art** and extension **eu.armand.--bit-art.StickerPackExtension** both enable In-App Purchase.
- The submitted archive’s signed identities match those explicit App IDs. Both profiles are valid until October 2027, and no local StoreKit fixture ships.

These checks follow [TN3186](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox). They rule out several common configuration mistakes but do not prove the reviewer’s catalog request succeeds or establish an Apple backend defect.

The owner reports a completed earlier TestFlight purchase and confirms that Studio remains unlocked and the editor works in the current TestFlight build. That purchase had already worked before someone else's App Store installation could not purchase. It must not be presented as newly proving that the original issue is fixed. Existing ownership and artwork must be preserved while checking availability.

At **2026-11-02T10:53:51Z**, the owner supplied the diagnostic build-12 report: OS **27.2**, USA storefront **143441**, correct extension/containing-app identifiers, payments permitted, **one matching Non-Consumable product at $1.00**, and **no error**. See `release/studio-1.4.1/owner-lookup-evidence.json`. This verifies the reported API result in an existing-owner TestFlight context. A new invocation can still use SDK caching; it does not prove an uncached request, build-11 first-launch paywall, a clean/unowned-account purchase, the review iPad/storefront or production availability.

## Internal diagnostic beta — 1.4.1 (12)

The separate **TestFlightDiagnostics** configuration uses the same real StoreKit adapter plus **STUDIO_PURCHASE_DIAGNOSTICS**. It has no local purchase simulation or ownership override. Its export is **internal TestFlight only** and must not replace selected App Review build 11. The public AppStore configuration remains 1.4.1 (11).

The diagnostic Help section permits an explicit read-only Apple product lookup even when Studio is already unlocked. It reports returned product count/IDs/types/localized prices, storefront, app identity and error domain/code. It does not purchase, restore, reset ownership or edit drawings. Technical reports exclude account details, transaction identifiers, receipts, tokens, messages and artwork, and are copied only on the user’s action.

Use **Messages → 8 bit art → ? → Purchase availability check → Check purchase availability** in internal beta build 12. Record whether Apple returns the configured product and localized price. Copy the technical report for diagnosis. Existing sandbox ownership can remain intact; a new purchase is not needed for this lookup.

Source configuration is in `Config/StudioDiagnosticsMetadata.json`; local archive/export helper is `scripts/archive-studio-diagnostics.sh`. Signed output and private evidence stay under ignored `build/studio-diagnostics/` and `build/rejection-2026-11-02/`. Sanitized release evidence is recorded in `release/studio-diagnostics-status.json` once upload completes.

Build **f14819f3-23c1-4507-9ad3-ad339980c1a9** is now **VALID / INTERNAL_ONLY / IN_BETA_TESTING** and present in the existing internal group. TestFlight notes contain the diagnostic steps. No external distribution is applicable. Exact source is **4b487f4826f18f2f42fd392d6b291f68d888c7f1**, tagged **v1.4.1-build12-diagnostics**. All **34 core/model tests** pass; clean archive/export and Apple validation/upload succeed with zero errors. Final readback verifies that rejected review build 11, its two review items and UNRESOLVED_ISSUES submission remain intact. The existing-owner lookup report is now received; the failing first-time-buyer path remains unverified and unresolved.

## Next decision

The existing-owner lookup returned the product. The owner has now deferred the proposed clean-account TestFlight test. The next proposed action is to obtain **reviewer diagnostics that explain the differing result** through the prepared inquiry. A later owner-triggered lookup cannot establish that first launch works. A transient failure, storefront/account difference or first-request client behavior remains possible; no sandbox cause is confirmed. The separate missing-production-approval blocker is verified. Do not repeat an unchanged submission based solely on this report, invent a fallback price, grant access without verified ownership, or reset the owner's purchases. A StoreKit 1 migration or a new IAP identifier is not justified by current evidence.

An unsent technical response is prepared in `docs/app-review-response-1.4.1.md`. Sending that message requires the owner’s instruction. The current submission stays unresolved while gathering evidence; do not cancel or resubmit it, request an app-only bug-fix exception, change the $1.00 price, or reset purchases to conceal the failure.
