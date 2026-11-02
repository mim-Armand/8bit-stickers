# App Review response — 1.4.1 (11)

**Draft only — not sent.** Updated November 2, 2026 after the owner deferred further TestFlight testing and requested focus on the App Store failure. The response requests help resolving the existing combined review; it does not claim the sandbox rejection is fixed or request app-only approval. The reviewer-ready text is below Apple's 4,000-character reply limit.

## Reviewer-ready response

Hello App Review,

We need help resolving Studio Unlock's product availability in the existing combined submission. Thank you for reporting “Price unavailable” on iPad Air 11-inch (M3), iPadOS 27.2, under Guideline 2.1(b).

Combined submission 4ab04eda-8610-4e9d-8552-8617b6a3f7e2, submitted October 31, contains:

- App: 8 bit art, Apple ID 1366485724, version 1.4.1 (11), build 63c7404d-e3b0-4136-8ae2-6a6bb90d652e.
- First IAP: Studio Unlock, product eu.armand.bitart.studio.unlock, Apple ID 6827336076, metadata version 45b42e0b-bc8a-4835-8bc8-4d766e48bda1.

The public version 1.4 (10) was approved without its first IAP. That explains why it could work in TestFlight yet be unavailable to App Store customers, as described in TN3188. Our corrective submission therefore includes both items. Today's readback still shows the app item REJECTED, IAP item READY_FOR_REVIEW, and parent IAP READY_TO_SUBMIT; the purchase has never become APPROVED.

We understand that prior approval is NOT required in your sandbox review environment, so lack of production approval alone does not explain your device's failure.

We checked the product/app association, exact product ID, non-consumable type, localization, completed review image, ongoing US$1.00 USA price and 175 territories. Paid Apps Agreement, bank and tax forms are Active. Host eu.armand.--bit-art and extension eu.armand.--bit-art.StickerPackExtension have explicit registered IDs, In-App Purchase capability and valid signing. The exported build has no StoreKit fixture or purchase simulation. Its real StoreKit implementation accepts verified production and sandbox transactions.

Studio Unlock permanently enables the 16×16 editor and saved drafts. It is not a subscription. Included stickers, search and favorites stay free.

An owner-provided TestFlight build-12 diagnostic report on OS 27.2 / USA storefront 143441 at 2026-11-02T10:53:51Z returned one exact matching Non-Consumable product at $1.00, with no error. The same real product query is used in build 11. This was an already-owned sandbox account, may use SDK caching, and does not prove a fresh purchase, your review-device behavior or production availability. We are not claiming a verified fix.

To reach the offer: Messages → a conversation → + / More → 8 bit art → Studio → Try Studio (or Unlock Studio when drafts exist). “Try loading the price again” repeats Apple's product query. Restore Purchases is also available. No app-specific login is required.

Please confirm the review storefront, whether retry still returns no product, and whether this first IAP is correctly queued and served for this app in your review catalog. If further changes are required, please advise which configuration or diagnostic is needed. We need the app and first IAP reviewed together; approving only the app would leave App Store customers unable to buy Studio. We are not requesting an app-only bug-fix exception.

Thank you.

## Internal notes — do not include when sending

- This is an unsent draft. Do not post it, resubmit either item or change the review until authorized by the owner/root task.
- Root verified configuration and Business statuses on November 2. Preserve sanitized evidence; do not include bank details, personal contact information, credentials or account identifiers in a reply.
- The owner supplied the build-12 report. A sanitized evidence summary is in `release/studio-1.4.1/owner-lookup-evidence.json`; the complete report stays ignored under `build/rejection-2026-11-02/owner-lookup-report.json`. No account, transaction, receipt or private device identifiers should be added to this response.
- The earlier TestFlight purchase had already worked before the original App Store failure. The owner has deferred more TestFlight testing. The next proposed action is this factual App Review inquiry, not an unchanged resubmission. A clean purchase remains unverified and must never be invented.
- Current root cause remains unresolved. Do not assert that approval alone fixes sandbox lookup, that Apple’s catalog is defective, or that a StoreKit 1 fallback is proven necessary.
- Before sending, confirm the exact rejection wording and submission/product states against the current readback. The app version resource is **6cd58d90-1728-495e-a02d-2b5fc571a519**.
- Live production evidence and acceptance criteria: `release/studio-production-availability-status.json` and `docs/studio-production-availability.md`.
- Relevant Apple references: [production availability / TN3188](https://developer.apple.com/documentation/technotes/tn3188-troubleshooting-in-app-purchases-availability-in-the-app-store), [configure In-App Purchases for sandbox review](https://developer.apple.com/help/app-review/before-submitting-for-review/configure-in-app-purchases/), [TN3186](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox), and [standalone iMessage app support for IAP](https://developer.apple.com/imessage/).
