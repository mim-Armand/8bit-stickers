# App Review response — 1.4.1 (11)

**Draft only — not sent.** Prepared November 2, 2026. The response below requests help investigating the sandbox product lookup; it does not claim the issue is fixed or request approval of the app without its purchase.

## Reviewer-ready response

Hello App Review,

Thank you for reporting that Studio Unlock shows “Price unavailable” on iPad Air 11-inch (M3), iPadOS 27.2, under Guideline 2.1(b). We are investigating the product lookup and understand that In-App Purchases do not need prior approval to function in your sandbox review environment.

The submission contains both of these items:

- App: **8 bit art**, Apple ID **1366485724**, version **1.4.1 (11)**, build ID **63c7404d-e3b0-4136-8ae2-6a6bb90d652e**.
- Purchase: **Studio Unlock**, product ID **eu.armand.bitart.studio.unlock**, Apple ID **6827336076**, metadata version **45b42e0b-bc8a-4835-8bc8-4d766e48bda1**.
- Combined submission ID: **4ab04eda-8610-4e9d-8552-8617b6a3f7e2**.

Studio Unlock is one permanent **non-consumable** purchase for the 16×16 editor and saved drafts. It is not a subscription. The USA price is **US$1.00**, with localized prices in the app’s existing 175 territories. Included stickers, search and favorites remain available without it.

On November 2, we rechecked the registered product and its app association, product ID, non-consumable type, localization, price and availability. We also verified that the Paid Apps Agreement, bank account and tax forms are Active. The signed host and extension use the registered explicit bundle IDs **eu.armand.--bit-art** and **eu.armand.--bit-art.StickerPackExtension**, with valid provisioning and In-App Purchase capability enabled. The submitted archive has no local StoreKit configuration or purchase simulation.

To reach the offer: open **Messages → a conversation → + / More → 8 bit art → Studio → Try Studio**. If saved drafts are already present, use **Unlock Studio** instead. The offer requests Apple’s product details before enabling checkout. **Try loading the price again** repeats that request; **Restore Purchases** is also available. No app-specific login is required.

We now have an owner-provided runtime report from internal TestFlight 1.4.1 (12), OS 27.2, USA storefront 143441, timestamp 2026-11-02T10:53:51Z. A direct `Product.products(for:)` invocation returned exactly one product: **eu.armand.bitart.studio.unlock**, type **Non-Consumable**, localized price **$1.00**, with no error and payments permitted. The extension and containing-app bundle identifiers match those above. Build 12 adds a read-only diagnostic action around the same product query used by build 11; it does not change the purchase implementation or contain a local StoreKit fixture.

This result is limited to an existing TestFlight owner. The query may use SDK caching; it does not prove the initial paywall request in build 11, a clean/unowned-account purchase, checkout/restore, the reviewer’s iPad/storefront, or production availability. The owner had already completed a TestFlight purchase before the original production failure, so we are not treating a successful existing-owner query as proof that the rejected issue is fixed. We are validating the first-time-buyer path before any further resubmission.

Could you please confirm the review storefront and whether **Try loading the price again** still returns the same result in your review environment? If the existing product is not being served for this app there, please advise whether the catalog association needs further investigation and which diagnostics would help. We are not requesting a bug-fix exception or asserting that the issue is resolved; we want the app and purchase to be testable and reviewed together.

Thank you.

## Internal notes — do not include when sending

- This is an unsent draft. Do not post it, resubmit either item or change the review until authorized by the owner/root task.
- Root verified configuration and Business statuses on November 2. Preserve sanitized evidence; do not include bank details, personal contact information, credentials or account identifiers in a reply.
- The owner supplied the build-12 report. A sanitized evidence summary is in `release/studio-1.4.1/owner-lookup-evidence.json`; the complete report stays ignored under `build/rejection-2026-11-02/owner-lookup-report.json`. No account, transaction, receipt or private device identifiers should be added to this response.
- The earlier TestFlight purchase had already worked before the original App Store failure. This new report strengthens product-discovery evidence for that existing-owner context but does not validate the failing new-buyer flow. Verify a clean/unowned-account initial lookup and purchase before claiming a fix or proposing another unchanged resubmission.
- Current root cause remains unresolved. Do not assert that approval alone fixes sandbox lookup, that Apple’s catalog is defective, or that a StoreKit 1 fallback is proven necessary.
- Before sending, confirm the exact rejection wording and submission/product states against the current readback. The app version resource is **6cd58d90-1728-495e-a02d-2b5fc571a519**.
- Relevant Apple references: [configure In-App Purchases for sandbox review](https://developer.apple.com/help/app-review/before-submitting-for-review/configure-in-app-purchases/), [TN3186](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox), and [standalone iMessage app support for IAP](https://developer.apple.com/imessage/).
