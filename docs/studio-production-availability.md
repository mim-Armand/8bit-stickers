# Studio Unlock — production availability investigation

Updated November 2, 2026. The owner deferred additional TestFlight purchase tests and requested focus on the released App Store failure. No Sandbox account was created, no purchase was reset, and the existing beta/review distribution was not cancelled.

## Confirmed production blocker

The released app and its purchase are separate approval resources. Public **1.4 (10)** is released, but **Studio Unlock / 6827336076 / eu.armand.bitart.studio.unlock** has never reached **APPROVED**. The October 27 completed review contained only the app. A fresh November 2 API readback still reports **READY_TO_SUBMIT** for the parent IAP and **READY_FOR_REVIEW** for its first metadata version.

This directly explains how a TestFlight purchase can succeed while the App Store copy returns no purchasable product. Apple's [TN3188](https://developer.apple.com/documentation/technotes/tn3188-troubleshooting-in-app-purchases-availability-in-the-app-store) explicitly lists unapproved or unavailable products as a cause of an empty `Product.products(for:)` result in an App Store app. TestFlight uses sandbox, where prior approval is unnecessary; it is not a production catalog check. This is a verified release blocker, not proof that no other failure exists.

The corrective **1.4.1 (11)** submission already contains both the exact app version and first-IAP metadata version, as Apple [requires for a first IAP](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/). Its current **UNRESOLVED_ISSUES** state has not approved the purchase. Waiting for the external TestFlight build does not advance production approval.

## Current checks

Sanitized state is in `release/studio-production-availability-status.json`. Private readbacks stay under ignored `build/fresh-buyer-test/` and signing/source evidence under `build/production-investigation/`.

| Check | Result | Meaning |
| --- | --- | --- |
| Published app identity | Apple ID 1366485724; host eu.armand.--bit-art | Correct existing listing |
| Product membership | Exact SKU appears under this app's inAppPurchasesV2 relationship | Not attached to the separate unpublished app |
| Product type | NON_CONSUMABLE | Correct permanent unlock |
| Approval | Parent READY_TO_SUBMIT; metadata READY_FOR_REVIEW | Production sale remains blocked |
| Price | Ongoing USA US$1.00 | Intended price retained |
| Availability | Exact owner-approved 175 territories, including USA | No missing USA availability; new territories off |
| Family Sharing | Off | Intended policy retained |
| Corrective review | App REJECTED; IAP READY_FOR_REVIEW; same combined submission | Both items remain attached; neither was resubmitted |
| Business | Paid agreement, bank, tax verified Active November 2 | No known business setup action |
| Exported payloads | Real StoreKit path, exact SKU, no local fixtures; host/extension signing valid | No evidenced production-only client/signing defect |

The raw Product query occurs before any transaction verification. A response without the exact matching SKU/non-consumable type produces the unavailable-price notice; the failing raw response itself was not recorded, so an empty raw list versus a filtered mismatch cannot be distinguished from the screenshot. The production configuration accepts verified Production and Sandbox transactions, so a sandbox-only ownership restriction is not blocking production price discovery. There is no developer receipt server or shared-secret routing to switch. An iMessage app can support IAP; a new app or website is not required.

## Separate unresolved reviewer failure

Apple also received an unavailable price in the review sandbox on iPadOS 27.2. Approval cannot explain that: Apple [explicitly states that prior approval is unnecessary during review](https://developer.apple.com/help/app-review/before-submitting-for-review/configure-in-app-purchases/). The existing owner's successful TestFlight lookup does not establish the review device's initial result or storefront. A transient request, storefront/account difference, catalog association issue or other client behavior remains a hypothesis.

The owner explicitly authorized the factual inquiry, and the exact [review reply](app-review-response-1.4.1.md) was **sent in the existing review conversation on November 2 at 16:23 UTC (10:23 AM CST)**. Its presence persisted after a Chrome reload. It asks Apple to check the SKU's review-catalog association, queue and storefront, includes the combined submission IDs and checked settings, and explains the limited scope of the TestFlight evidence. It requests review of both items and makes no claim of a verified fix. See the [send confirmation](../release/studio-1.4.1/app-review-reply-status.json).

**Next action: await Apple's response and evaluate the requested diagnostics.** Follow-up API readback at **2026-11-02T16:23:28.591Z** still shows **UNRESOLVED_ISSUES**, parent IAP **READY_TO_SUBMIT**, metadata **READY_FOR_REVIEW**, and selected build **11**. Sending the reply did not resubmit or approve either item. Do not repeat an unchanged submission, recreate the SKU, alter pricing/territories, accept app-only approval, or reset existing purchases.

## Completion criteria

1. Resolve the reviewer discrepancy using Apple's diagnostics or an evidenced implementation/configuration correction.
2. Complete approval of the app and **first IAP together**. App approval alone is insufficient.
3. Read back **APPROVED** on the IAP itself, retain the exact price/availability, and allow catalog propagation. Apple documents possible propagation time after approval without promising a fixed deadline.
4. On a physical device using an unowned production purchase account, install the **App Store** version and verify initial localized price, real one-time checkout, automatic editor access, then relaunch and restore. A real purchase is charged; its execution needs the owner's specific authorization. Preserve all drawings.

Do not call the production issue resolved before this final device evidence exists. Configuration approval and TestFlight success alone are insufficient.
