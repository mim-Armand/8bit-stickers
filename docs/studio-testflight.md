# Studio TestFlight beta — 1.4 (8)

The owner requested TestFlight access after the local Studio was completed. Version **1.4, build 8** is uploaded, processed and available for **internal testing only** under the existing **8 bit art** App Store record, **1366485724**. The account holder is invited to the existing internal group. No public App Review submission or live In-App Purchase was created for this beta.

## Install and try it

1. Open Apple's **TestFlight** app on your iPhone or iPad using the Apple Account associated with your App Store Connect invitation. Look for **8 bit art → 1.4 (8)** and tap Install. If it is not listed yet, accept Apple's invitation at your App Store Connect email address and reopen TestFlight.
2. Open **Messages**, choose a conversation, tap **+**, and select **8 bit art**. Look under **More** if needed. This remains a Messages app; it has no separate home-screen editor icon.
3. All 67 included stickers, search, categories and favorites are free. Open **Studio → Enable Studio for this beta** to use the editor and saved drafts.
4. Try drawing on the 16×16 grid or choosing **Details → Make it yours** on one of the 45 tiny templates. Use pencil/eraser/fill, undo/redo, rename, duplicate, export and saved drafts. Close/reopen Messages to verify persistence.
5. **Insert sticker** adds the image to the conversation composer. You choose when to tap Send. The automated tests inserted a sticker but never sent a message.

Installing the beta replaces the installed copy of the same Messages app on that device. Drafts stay on the device; deleting the app can remove them, so export drawings you want to keep.

## Free beta access

This is a **free Studio preview**, clearly labeled **TESTFLIGHT PREVIEW · NO CHARGES**. It makes no product lookup, purchase or payment request. Enabling/restoring beta access uses a separate device-local record; it neither charges $1 nor creates ownership of the future paid unlock. Enable it free on each beta device. Real Apple purchase/restore testing remains a separate step requiring the actual IAP setup.

The intended public release still has a permanent one-time Studio Unlock targeting US$1.00. Exact production IAP price-point availability is unverified. No product, price, agreement or banking setting was changed for this beta.

## Verified distribution state

| Field | Value |
| --- | --- |
| App | 8 bit art, Apple ID 1366485724 |
| Version/build | 1.4 / 8 |
| Build ID | `886a1635-0abf-4a13-9299-12aa814bcbd9` |
| Apple processing | `VALID` |
| Audience | `INTERNAL_ONLY` |
| Internal beta status | `IN_BETA_TESTING` |
| External beta status | `NOT_APPLICABLE` |
| Internal group | App Store Connect Users |
| Tester access | Account holder invited; app/group linkage verified |
| Expiration | January 24, 2027 |
| Included art | 67 stickers, 45 exact-grid templates, wine excluded |

Apple confirmed `buildAudienceType: INTERNAL_ONLY`. The exported signed app also contains `TFInternalTestingOnly=true`. This build cannot be distributed to external TestFlight testers or App Store customers. External testing would require a separate eligible build and its beta review; do not treat this upload as authorization for that.

The current public review remains **1.2 (5), Waiting for Review, AFTER_APPROVAL**, with selected build `ecc379bc-4471-489b-887b-826ec30d9c6b` unchanged. The old submission, screenshots, privacy label, current app price and public support website were not modified. The prepared 1.3 (6) sticker-only project is also unchanged.

## Build configuration and evidence

`NativeStudio/project.yml` adds a release-based **TestFlight** configuration and **Studio TestFlight Internal** archive scheme. Only this configuration enables `STUDIO_BETA_TESTING`. Normal Release checkout remains disabled; Debug retains its separate local simulation/Xcode StoreKit tests. The beta uses manual Apple Distribution signing with the existing app/extension profiles and identities. Host `SKIP_INSTALL=NO`; the extension remains embedded and signed.

The archive contains the actual standalone Messages app/extension and 67 stickers. It excludes the preview home-screen test host, XCTest runners, browser bridge/HTML, local `.storekit` configuration and wine. A regular opaque 1024-square host AppIcon preserves the original icon pixels; the extension retains its original Messages icon. This fixes the missing distribution icon metadata found by the first validation attempt.

Verification:

- 29 beta/model tests and 2 beta UI tests passed, including free activation, restart/restore, isolation from local mock ownership and preserved saved work.
- 31 existing Debug model/purchase tests passed again, including actual Xcode StoreKit testing and ordinary checkout restrictions.
- Signed archive/export succeeded. Final Apple validation and upload reported **zero errors**, with the two expected hidden Messages-only Mac/visionOS compatibility warnings.
- Apple readback verified internal-only availability, account-holder membership/invitation, build assignment, testing notes and unchanged public-review selection.

Public machine-readable summary: [`release/studio-testflight-status.json`](../release/studio-testflight-status.json). Detailed logs/readbacks, tester email records, signed archive and IPA remain under ignored `build/studio-testflight/`; credentials remain outside the repository.

Rebuild/export locally with:

```sh
./scripts/archive-studio-testflight.sh
```

That helper does not upload. Do not use `scripts/archive-release.sh` for Studio: it builds the separate sticker-only project. For a later beta, choose a new unused build number and update the dedicated TestFlight configuration/output path. Before uploading any future build, require the internal-only marker, verify identities/signatures and preserve the public-review selection. A public Studio release still needs production StoreKit enablement, IAP setup/price verification, broader physical-device testing and a separately authorized review submission.

Apple references: [internal TestFlight testing](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/), [upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [TestFlight and sandbox purchases](https://developer.apple.com/in-app-purchase/).

Support: **seltzer.wisdom7h@icloud.com**.
