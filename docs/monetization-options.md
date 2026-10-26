# Studio Unlock — agreed monetization plan

Updated October 26, 2026. This supersedes the earlier recommendation to charge for downloading the sticker pack. The owner clarified that payment is for **the native Studio tools inside Messages**, then asked for this future implementation to be planned and documented. The local native implementation now exercises this offer with no-charge test purchases. No live pricing or product settings have been changed.

## Product and access

Keep the included sticker catalogue, categories, search and favorites free. Offer **Studio Unlock**, a single **non-consumable In-App Purchase** that permanently enables the 16×16 editor, multiple local drafts and creating/inserting custom stickers. No subscription, consumable credits, per-drawing charge, per-send charge or separate paid individual designs in this plan.

Proposed product ID: `eu.armand.--bit-art.studio.unlock`, under app **1366485724**. Check availability/validity before registration. One product covers the tools across future updates; do not sell the same entitlement again in each version. Restore Purchases recovers ownership under the purchasing App Store account; it does not recover deleted local artwork. No app-specific user account or developer-operated backend is required for this local feature set.

Apple permits In-App Purchase in custom standalone iMessage apps. A non-consumable is purchased once and does not expire or diminish with use. [iMessage app support](https://developer.apple.com/imessage/), [IAP types](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types/).

## US$1 price target

The intended USA base price is **exactly US$1.00 once**, subject to verifying an available price point for this **IAP product**. Previously, a read-only query verified an exact $1.00 **app-download** price point. That is a different pricing resource and does not verify the Studio Unlock price.

When configuring the new IAP, inspect its USA price points, record the chosen point and price readback, and select $1.00 if available. If unavailable, present the actual options to the owner; do not silently change to $0.99. Leave the app-download price unchanged. Display StoreKit's `Product.displayPrice`, including currency/localization, rather than hard-coded $1 text. Other territories use localized prices and applicable taxes. [Set an IAP price](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase/), [displayPrice](https://developer.apple.com/documentation/storekit/product/displayprice).

Before sale, verify the current Paid Apps Agreement and tax/banking setup. Do not assume those prerequisites are complete from the existing app's availability.

## Purchase behavior and boundaries

The [implementation handoff](native-studio-implementation-plan.md) is authoritative for the state machine and test matrix: verified StoreKit 2 entitlements, explicit purchase, cancellation/pending handling, automatic transaction updates, user-initiated Restore Purchases and offline use for known verified owners. Refunded/revoked access locks new paid editing/insertion after reconciliation but never deletes drafts or favorites; existing drawings remain viewable/exportable.

**Family Sharing is not decided.** Leave it off until the owner chooses it, then test family entitlement behavior if enabled. Apple's setting cannot be turned off after activation. [Family Sharing](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases/).

Current 1.2 (5) and development 1.3 (6) are static sticker packs without StoreKit. The local 1.4 (7) Studio project supplies that custom Messages implementation, with simulated checkout and verified Xcode StoreKit testing. Normal release builds currently disable checkout; no production product has been registered. See [local testing](native-studio-local.md). A future release needs its own validated custom Messages binary. Apple's first non-consumable product must accompany the new app version **in the same review submission**. Do not attach this plan/product to the already submitted build 5. [First-IAP submission](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/).

A paid download, premium sticker collections, subscriptions, web checkout and per-design purchases remain outside this chosen scope. Reconsider them only if the owner changes the product direction.
