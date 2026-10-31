# Native Studio public release preparation — 1.4 (10)

**October 31 status:** 1.4 (10) is now released, but the Studio Unlock IAP was omitted from its completed app-only review and remains unsubmitted. See [the 1.4.1 (11) purchase correction](studio-purchase-fix.md) for the current investigation, fixes and combined-review preparation. The remainder of this file preserves the original October 27 preparation handoff.

The owner requested a new review candidate with native Studio and the optional paid tools on October 27, 2026. This work prepares the candidate and editable Apple metadata; **it does not submit the app or IAP review**.

Fresh Apple readback confirms **1.2 (5) is approved and Ready for Distribution**, with the old review submission complete. Internal sandbox **1.4 (9)** is now `VALID`, `INTERNAL_ONLY` and `IN_BETA_TESTING`. Neither version needs cancellation. The new public candidate is **1.4 (10)** under the same Apple ID **1366485724**, host **eu.armand.--bit-art** and extension **eu.armand.--bit-art.StickerPackExtension**.

The editable 1.4 version is `2d64f5fa-b9c8-4d60-94ec-1cf3f03e65d0`; its English localization is `d56f8cc2-94b7-420a-816a-9a939395c054`. It retains **AFTER_APPROVAL** for the eventual submission. Build **626b2c8b-f888-4d02-81f5-14999de27c89** is **VALID / APP_STORE_ELIGIBLE**, selected in the editable 1.4 draft and **IN_BETA_TESTING** for internal testers. Apple validation/upload succeeded with zero errors and expected Messages-only compatibility warnings 90863/90984. The signed candidate, current Apple readback and outstanding steps are recorded in [`release/studio-1.4/preparation-status.json`](../release/studio-1.4/preparation-status.json). This document is a handoff; recheck live Apple state before a future submission.

## What the update includes

All **67 included stickers**, categories, search and favorites remain usable without Studio Unlock. The permanent **non-consumable Studio Unlock** enables the **16×16 editor**, **45 exact-grid remix templates**, named local drafts, custom sticker insertion and PNG export. Pencil/eraser/fill, undo/redo, rename/duplicate and atomic local saving are implemented. The app remains inside Messages, with no separate home-screen editor or new hosting/backend.

The registered purchase is **eu.armand.bitart.studio.unlock / 6827336076**. Its own USA price points and saved schedule verify **US$1.00 exactly**; the app displays Apple's localized price. Family Sharing remains off. There is no subscription or charge per drawing/send. The app-download price is unchanged.

The dedicated **AppStore** configuration enables real StoreKit ownership and checkout; it accepts Apple's verified production/sandbox transactions for the exact published app, product and non-consumable type. StoreKit provides the environment for the installed app/TestFlight/review context. Ownership is never inferred from mock/free-beta preferences. Product-price failure preserves known verified access, and refund/revocation leaves saved artwork viewable/exportable. Restore retains verification errors instead of replacing them with a misleading success message.

The offer supplies its own visible UIKit controller/scene to Apple's purchase API on supported OS versions; iOS 15/16 use the original supported overload. Normal unconfigured Release checkout remains disabled. Debug, free beta, sandbox beta and screenshot configurations remain separate.

## Approved purchase availability

On **October 27, 2026**, the owner explicitly approved Studio Unlock for **the same 175 territories where this app is already available**. The exact approved list is now applied and read back under availability ID **`6827336076`**, with **automatic new-territory availability off**. [`availability-plan.json`](../release/studio-1.4/availability-plan.json) preserves the approved list and verification. The USA price remains **US$1.00**, localized prices remain in place elsewhere, and Family Sharing remains off.

Studio Unlock now reports **`READY_TO_SUBMIT`**; metadata version `45b42e0b-bc8a-4835-8bc8-4d766e48bda1` remains **`PREPARE_FOR_SUBMISSION`**. These states do not mean App Review has been submitted or the product is approved for sale. **No app/IAP review has been submitted.** Physical-device purchase/restore and final acceptance remain to be completed.

The earlier automatic approval rejection is historical and **resolved by the owner's explicit approval**. The rejected combined command did not run; availability was subsequently applied within the approved scope. Do not ask for this same territory approval again. The metadata helper continues to leave availability unchanged when refreshing draft text.

## Metadata, support and privacy

[`Config/StudioAppStoreMetadata.json`](../Config/StudioAppStoreMetadata.json) is the source for the new listing, What's New, reviewer path and registered purchase. [`studio-app-store-draft.md`](studio-app-store-draft.md) records the copy and assessment. The original sticker-only `Config/AppStoreMetadata.json`, 1.2 screenshots/submission evidence and original Xcode project remain separate.

The English draft text and review notes are saved through `scripts/prepare-studio-appstore.mjs --apply`. The helper validates version, identities, field lengths, 67/45 resources and the exact IAP price, requires an editable 1.4 draft, and never submits or changes availability. Contact fields are inherited from the existing review record and kept out of Git.

Support/privacy sources now describe the forthcoming native tools, purchase restoration and local draft deletion/export. `site/` is ready for a later intentional deployment; no support-site deployment occurred during this preparation. Support stays **seltzer.wisdom7h@icloud.com** and existing GitHub Pages URLs are unchanged.

The native app/extension now include a separate privacy manifest declaring **UserDefaults / CA92.1** for app-owned local preferences. It declares no tracking or collected data. This preserves the old sticker-only manifest. Apple's [required-reason documentation](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) supports this use.

**Privacy-label assessment:** Data Not Collected remains consistent with the implementation: developer code does not send drawings, messages, recipients or transaction data to a developer service; Apple handles payments and on-device StoreKit verification. This is an assessment against the actual code and [Apple's privacy definitions](https://developer.apple.com/app-store/app-privacy-details/), not a new privacy-label publication.

**Age-rating assessment:** the inherited questionnaire still calculates **4+**, with wine excluded. Apple defines age-rating UGC by **broad distribution**; this app has no public gallery/feed or user-hosted publishing service. Drawing is local and insertion hands a PNG to the Messages composer, whose Send action and communication service belong to Messages. We therefore retain the copied no-broad-UGC/no-in-app-chat/social-media answers. This is an interpretation of [Apple's definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/) for the actual app, not a claim that all drawing/sharing apps have identical answers. Reassess if public galleries, chat or web browsing are added.

## Candidate build and validation

Open `NativeStudio/Studio.xcodeproj`, scheme **Studio App Store**, configuration **AppStore**, or run:

```sh
./scripts/archive-studio-appstore.sh
```

This creates the signed clean archive/export under ignored `build/studio-release/1.4-10/` and never uploads. Export options omit the internal-only TestFlight restriction. Verify identities/version/build, App Store eligibility, real commerce flag and absence of all test fixtures before any upload.

Eight actual native captures (four iPhone, four iPad) now have **16 COMPLETE placements** across the App Store and Messages wells. The separate phone IAP review image is also **COMPLETE**. Only the 12 inherited screenshot copies in the new 1.4 draft were retired; published 1.2/1.1 assets were protected. The screenshot uploader verifies RGB dimensions/checksums and tolerates Apple’s canonical `SOURCE` filename for the IAP image only when its size/checksum match.

The package verification checks exactly 67 stickers, wine exclusion, both UserDefaults privacy declarations, the custom Messages principal class, and exclusion of preview app, XCTest runners, browser bridge, HTML, `.storekit` and StoreKitTest framework. SHA-256, Apple validation/upload/processing and selection are recorded in the machine-readable status.

Model/commerce checks passed after the explicit purchase-presenter change: **29 AppStore tests**, **26 screenshot-configuration tests**, **31 Debug regressions**, and **1 ordinary Release checkout restriction check**. They cover ownership/environment/type isolation, verification failures, saved-work preservation and Xcode purchase/restore/refund. Actual Messages checkout also completed through the UI on both iPhone and iPad using verified Xcode StoreKit transactions. These checks do not establish a remote Apple sandbox purchase on a physical device.

The **Screenshots** configuration/target is a test aid with public UI copy and genuine verified Xcode StoreKit ownership. It does not use a preference entitlement bypass. Its test host is correctly attached to the Messages app; without that binding, an unhosted runner sent the extension to Apple's sandbox and encountered “No active account.” That earlier capture failure was a simulator setup issue; keep its logs separate from the successful capture flow.

## Remaining before submitting

1. Confirm the actual App Store eligible build is `VALID`, selected in 1.4, and the new native screenshots/IAP review image are all processed. Preserve the released 1.2 screenshot assets. Verify the prepared source tag matches the candidate.
2. Recheck the approved 175-territory availability, US$1.00 schedule and completed review image. Studio Unlock is `READY_TO_SUBMIT`; its metadata version remains `PREPARE_FOR_SUBMISSION`. Reuse the existing product/version and exact price. No repeat territory approval is needed.
3. Install the final candidate through internal TestFlight on an iPhone/iPad. Complete the real sandbox purchase, cancel/retry, restore under the same account, relaunch/offline access, saved drafts, drawing/PNG and Messages insertion. Check compact/expanded, large text and VoiceOver. Export existing drafts before destructive reinstall/history-reset tests. Do not claim message delivery from a composer insertion alone.
4. Refresh listing/support/privacy and age/agreements/price readback. Site copy can deploy intentionally when appropriate. The Paid Apps Agreement/tax/banking statuses were active at the preceding read-only verification; recheck if they change or significant time passes.
5. When the owner explicitly asks to submit, attach **both app 1.4 and the first Studio Unlock IAP metadata version** to the same review submission under Apple's current version-based IAP API. Submit neither item alone. Preserve `AFTER_APPROVAL` if still desired. Record the exact submission/readback and retain source tag, archive and backup.

No review submission or public release is authorized merely by preparing this candidate or by passing local tests. The owner can review the concrete candidate and outstanding device checks before the final submission action.
