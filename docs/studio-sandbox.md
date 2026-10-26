# Studio Unlock — Apple sandbox testing

The owner chose **Apple's actual sandbox purchase and restore flow** after the free beta was uploaded. This supersedes free activation for the next test build, **1.4 (9)**. Apple accepted the signed internal-only upload with no errors; processing/API visibility is pending. Build 8 remains the free Studio preview; use **build 9** to exercise StoreKit. Check the [sandbox status record](../release/studio-sandbox-status.json) for the verified upload/distribution state.

This is the same **8 bit art** Messages app, Apple ID **1366485724**. Public **1.2 (5)** remains Waiting for Review with automatic release after approval. No new public app/IAP review was submitted, no public sale availability was configured, and the app-download price and support website were not changed.

## Install and test

1. Open **TestFlight → 8 bit art → 1.4 (9)** and install/update. If another build is selected, choose build 9 from the available builds. The account holder was already invited to the internal group. Accept Apple's invitation if required. This beta replaces the installed app on that device.
2. Open **Messages → a conversation → + → More → 8 bit art**. There is no separate home-screen Studio. Browse/search/favorite the **67 included stickers**; those remain free.
3. Open **Studio → Try Studio** or choose **Details → Make it yours** on a tiny template. The offer shows **Test unlock** with Apple's localized price. The US price schedule is exactly **US$1.00**, but the TestFlight transaction takes no real payment.
4. First cancel Apple's purchase sheet. Studio should stay locked and the included stickers should remain usable. Open the offer again and complete the sandbox purchase. The requested blank drawing or remix should open after verified ownership arrives.
5. Try pencil, eraser, fill, undo/redo and the **16×16 grid**. Rename and reopen a draft, duplicate it, remix one of the **45 templates**, and export a PNG. **Insert sticker** places it in the Messages composer; you choose whether to tap Send.
6. Close/reopen Messages and Studio. StoreKit should recover the verified test entitlement. Under **Help → Restore Purchases**, restore using the same purchase account and confirm access returns. Restoring tools does not restore deleted drawings; export work before deleting the app or reinstalling.

Build 9 deliberately ignores the earlier **Enable Studio for this beta** record and local mock purchases. You should see the purchase offer even if build 8 was enabled. Existing local drafts/favorites are kept; they remain readable/exportable while editing is locked. A sandbox purchase does not grant ownership of the future public paid unlock.

TestFlight purchases always run in Apple's sandbox and incur no charges. A normal TestFlight Apple Account is sufficient for the initial test; there is no need to sign out just to try the purchase. See [Apple's sandbox testing guide](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox).

## If the price does not load

New product metadata can take **up to one hour** to reach the sandbox. Keep the connection online, reopen the offer and tap **Try loading the price again**. The button stays disabled until Apple returns product metadata; saved work is preserved. Report the exact message and build number if it remains unavailable after propagation.

The app and extension both have In-App Purchase enabled. On October 26, 2026, read-only App Store Connect Business inspection confirmed the **Paid Apps Agreement, bank account and US tax form were Active**. These were not changed or newly accepted. Product reference name, valid product ID, localized display name and price are configured. No review screenshot, prior IAP approval or review submission is required to start sandbox testing. See [Apple TN3186](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox).

The product currently reports `MISSING_METADATA`, with metadata version `PREPARE_FOR_SUBMISSION`: public release metadata and sale/review preparation are intentionally incomplete. Do not treat that as proof of a failed sandbox transaction or as permission to submit. Actual on-device product lookup and purchase remain the tester's verification step.

## Optional repeat, reset and refund testing

Use **App Store Connect → Users and Access → Sandbox** to create a dedicated Sandbox Apple Account if you want test controls such as purchase-history reset. Apple exposes account creation through its UI. Choose/store the password yourself; no password belongs in this repository or chat.

Install the TestFlight beta using the ordinary Apple Account first. To use a dedicated test account's controls, Apple's current instructions require signing out of **Media & Purchases**, then signing into **Settings → Developer → Sandbox Apple Account** with Developer Mode enabled. Do not sign out of iCloud. Signing out of Media & Purchases can affect access to purchased content in other apps, so a dedicated testing device is preferable for this optional setup. See [Apple's device instructions](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox) and [create a Sandbox Apple Account](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/create-a-sandbox-apple-account/).

After clearing **this test account's** purchase history, reopen the app/Restore Purchases and repeat the purchase. Test cancellation, interrupted checkout, relaunch, restore and any available refund/revocation controls. Confirm entitlement loss never deletes drawings/favorites. Record device/OS, build, storefront and outcome; do not claim these passed until someone performs them on a device.

## Registered product and price

| Setting | Verified value |
| --- | --- |
| App | `1366485724` |
| IAP Apple ID | `6827336076` |
| Product ID | `eu.armand.bitart.studio.unlock` |
| Type | `NON_CONSUMABLE` |
| Reference/display name | Studio Unlock |
| English description | 16×16 editor, remix templates, and saved drafts. |
| Metadata version | `45b42e0b-bc8a-4835-8bc8-4d766e48bda1` |
| USA price | **US$1.00**, verified against the IAP's own price points and saved schedule |
| USA price-point ID | `eyJzIjoiNjgyNzMzNjA3NiIsInQiOiJVU0EiLCJwIjoiMTAwMTEifQ` |
| Family Sharing | Off |
| Public availability/review | Not configured/submitted by this work |

The earlier speculative ID `eu.armand.--bit-art.studio.unlock` could not be registered because Apple's IAP IDs cannot contain hyphens. It never represented a product or purchase. Code and the local `.storekit` fixture now use the valid ID above. **Published host/extension bundle IDs are unchanged.**

The API uses the current version-based metadata flow: `POST /v2/inAppPurchases`, `POST /v1/inAppPurchaseVersions`, `POST /v2/inAppPurchaseLocalizations` relating to the version, and `POST /v1/inAppPurchasePriceSchedules`. Localizations are read through the version. Price schedules remain on the stable product. Never create a second unlock to redo this setup. See [Apple's metadata migration reference](https://developer.apple.com/documentation/appstoreconnectapi/migrating-in-app-purchase-metadata-to-v2).

## Source and verification

- **TestFlightSandbox** is a separate release-based configuration with only `STUDIO_SANDBOX_TESTING`; **Studio Sandbox Internal** archives **1.4 (9)** using the existing app/extension distribution profiles. It exports with `testFlightInternalTestingOnly=true`.
- Normal **Release** checkout remains disabled. **TestFlight** preserves build 8's free beta behavior. **Debug** preserves isolated mock/Xcode StoreKit testing.
- Sandbox mode reads Apple's localized `Product.displayPrice`, calls real StoreKit purchase/restore, listens for transaction updates, and grants access only after verification of a **sandbox** transaction. Xcode/production/unknown environments fail closed. iOS 15 uses the signed string environment field; iOS 16+ uses StoreKit's environment value.
- **29 sandbox model/commerce tests passed**, including four new checks for ownership isolation, environment policy, disabled initialization and rejection of a real verified transaction from the wrong Xcode environment. **31 Debug regression tests passed**, including Xcode-local purchase, restore and refund with the valid product ID. These do not establish an Apple sandbox transaction on a phone.
- Clean signed archive/export and Apple validation passed with **zero errors**, plus expected hidden Messages-only Mac/visionOS compatibility warnings `90863` / `90984`. The IPA preserves both app IDs, contains exactly 67 stickers and excludes wine, preview hosts, test runners, HTML bridge and `.storekit` files. It carries `TFInternalTestingOnly=true`.

Rebuild/export locally:

```sh
./scripts/archive-studio-sandbox.sh
```

This helper never uploads. Later uploads need a new unused build number and fresh identity/payload checks; do not overwrite the build 9 evidence. Signed outputs, private account readback and logs remain ignored under `build/studio-sandbox/`. The sanitized status record stores the uploaded build ID, processing/audience state, product/price and public-review readback.

Before public release, complete physical-device purchase/restore/insertion and accessibility checks, enable verified production ownership in a separately reviewed implementation, complete actual IAP sale/review metadata and native screenshots, and submit the app with its first IAP only when authorized. Recheck agreements and prices then. The internal-only binary cannot be used for public App Store distribution.

Support: **seltzer.wisdom7h@icloud.com**.
