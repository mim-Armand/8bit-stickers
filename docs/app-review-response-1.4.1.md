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

The owner reports having completed a purchase in an earlier TestFlight session and has now confirmed that Studio is currently unlocked and the editor works in TestFlight. This confirms the reported access state, but we have not independently verified a fresh product lookup or purchase/restore in submitted build 11, nor reproduced the flow on your iPad configuration. Our Xcode StoreKit checks also do not establish the current remote sandbox catalog response. We are preparing an internal, read-only product-availability check that will preserve existing access and artwork while obtaining a fresh result.

Could you please help verify that this existing product is being served for this app in the review sandbox, and retry the offer if the catalog association is available? If it still fails, please advise which storefront or device diagnostics would help identify the cause. We are not requesting a bug-fix exception or approval of the app without the purchase; we want both items to be testable and reviewed together.

Thank you.

## Internal notes — do not include when sending

- This is an unsent draft. Do not post it, resubmit either item or change the review until authorized by the owner/root task.
- Root verified configuration and Business statuses on November 2. Preserve sanitized evidence; do not include bank details, personal contact information, credentials or account identifiers in a reply.
- The owner has clarified that TestFlight Studio is currently unlocked and the editor works. The missing purchase offer is consistent with existing access, but does not establish a fresh catalog lookup or restore. Obtain the read-only availability report without resetting ownership or deleting the app/artwork before drawing a conclusion.
- Current root cause remains unresolved. Do not assert that approval alone fixes sandbox lookup, that Apple’s catalog is defective, or that a StoreKit 1 fallback is proven necessary.
- Before sending, confirm the exact rejection wording and submission/product states against the current readback. The app version resource is **6cd58d90-1728-495e-a02d-2b5fc571a519**.
- Relevant Apple references: [configure In-App Purchases for sandbox review](https://developer.apple.com/help/app-review/before-submitting-for-review/configure-in-app-purchases/), [TN3186](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox), and [standalone iMessage app support for IAP](https://developer.apple.com/imessage/).
