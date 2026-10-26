# Release checklist — 8 bit art

Updated October 26, 2026. **1.2 (5)** was submitted for App Review at **3:01 PM CDT** with **46 stickers**, a selected `VALID` build and twelve `COMPLETE` screenshot placements. Both the version and its review submission report **`WAITING_FOR_REVIEW`**. The **Data Not Collected** App Privacy label is published, and release type **`AFTER_APPROVAL`** is saved. Apple has not yet approved or publicly released the update.

## Completed preparation

- [x] Preserve Apple ID **1366485724**, host `eu.armand.--bit-art`, extension `eu.armand.--bit-art.StickerPackExtension` and owning team `7N3Y4QZT3Z`.
- [x] Preserve all eleven original PNGs as source. Ship **10 classics + 36 new designs = 46 stickers**, including two APNG animations. At the owner's request, wine is archived at `art/recovered/wine_01.sticker/` and excluded from the app/gallery.
- [x] Prepare a clean simulator build, clean signed build 5 archive and exported IPA. Check simulator/archive/export products for wine absence; release archiving now uses `clean archive` to avoid stale incremental assets.
- [x] Pass Apple validation/upload with **zero errors** and two expected hidden-app Mac/visionOS compatibility warnings. Public signing configuration is `Config/ExportOptions.plist`; credentials and artifacts remain outside Git.
- [x] Select processed build **5**, ID `ecc379bc-4471-489b-887b-826ec30d9c6b`, state `VALID`, in draft `7c6caa34-4ee8-4423-87d9-e4acc09b1b40`, replacing build 4. Verify `usesNonExemptEncryption: false`. Internal beta state is `READY_FOR_BETA_TESTING`; external state is `READY_FOR_BETA_SUBMISSION`.
- [x] Stage and read back the revised native-only copy, keywords, promotional text, support/privacy URLs and review notes. Authoritative copy is `Config/AppStoreMetadata.json`; ignored evidence is `build/release/draft-metadata-readback.json` and `selected-build.json`.
- [x] Verify public support email **seltzer.wisdom7h@icloud.com**, [support](https://mim-armand.github.io/8bit-stickers/support/) and [privacy](https://mim-armand.github.io/8bit-stickers/privacy/) URLs. The GitHub Pages site returns HTTP 200 and enforces HTTPS. It does not publish Studio.
- [x] Stage alcohol references `NONE` after excluding wine; API readback reports **`FOUR_PLUS`**, with no override or Made for Kids selection.
- [x] Preserve existing App Review contact privately and retain the existing content-rights declaration. No reviewer phone/email details are copied into public repository metadata.
- [x] Capture six actual native build 5 screenshots on iOS/iPadOS 17.5: three iPhone RGB images at **1179×2556** and three iPad RGB images at **2064×2752**. Source manifest: `release/screenshots/manifest.json`, `stickerCount: 46`, `wineExcluded: true`.
- [x] Upload those six files as twelve placements across `APP_IPHONE_61`, `IMESSAGE_APP_IPHONE_61`, `APP_IPAD_PRO_3GEN_129` and `IMESSAGE_APP_IPAD_PRO_3GEN_129`. All are `COMPLETE`, with no errors. Evidence: ignored `build/release/screenshot-upload-readback.json`.
- [x] Remove legacy 2018 screenshot placements only from editable draft 1.2; leave the published 1.1 sets/assets untouched.
- [x] Publish the **Data Not Collected** App Privacy label through App Store Connect. The UI showed “Published a few seconds ago by mim Armand” and Data Not Collected. Evidence: ignored `build/submission/privacy-published.jpg`. Publishing the public policy URL is a separate task.

The staged capability declarations are `userGeneratedContent: false`, `socialMedia: false` and `messagingAndChat: false`. This is an implementation-based interpretation: the predefined pack has no own chat/feed/editor and supplies developer artwork; Apple's host Messages app handles conversations. [Apple's capability definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions).

## Submission completed

- [x] Save and read back **`AFTER_APPROVAL`** so Apple automatically releases this version after approval.
- [x] Submit **1.2 (5)** for **App Review**. Review submission ID: `d6780537-3c51-43b3-97d9-67f900dfc768`; submitted at `2026-10-26T20:01:02.003Z`. The submission and version both report `WAITING_FOR_REVIEW`, with build 5 unchanged.

Final API evidence is ignored `build/submission/review-submitted.json` and `build/submission/final-readback.json`. Public release evidence is summarized in [`release/release-status.json`](../release/release-status.json); candidate tagging and archive backup accompany the source handoff. App Review approval remains pending. No purchase or app-price change was made.

## Optional final device checks

The actual picker rendered on iPhone and iPad simulators. A physical-device/TestFlight pass can still check installation over the live app, sending, peel/place, animations, light/dark appearance and supported layouts. These are recommendations; no completed physical-device or TestFlight pass is claimed. Beta readiness and Apple processing acceptance do not establish those tests.

## Screenshot and privacy references

The native screenshots meet the current supported portrait dimensions and contain no alpha. The same actual Messages experience is staged for normal App Store and iMessage surfaces because this record uses both families. [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [iMessage screenshot workflow](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-imessage-app-information).

The no-collected-data label describes the catalog-only native binary, not hypothetical future Studio features. The hosted policy separately covers Apple services, voluntary support email and GitHub Pages security logs. [Apple privacy disclosure guidance](https://developer.apple.com/app-store/app-privacy-details/).

## What the documented API can stage

Apple's [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi) supports app versions, localization metadata, screenshots, build selection and age-rating declarations. Read the existing resources and IDs before changing them; these calls affect production account data.

Inspection of Apple's [OpenAPI specification](https://developer.apple.com/sample-code/app-store-connect/app-store-connect-openapi-specification.zip), version **4.5.1**, on this preparation date found:

- `AppInfoLocalization` exposes `privacyPolicyUrl`; version-localization resources carry the version's product-page copy/support URL.
- `GET /v1/appInfos/{id}/ageRatingDeclaration` reads the declaration and `PATCH /v1/ageRatingDeclarations/{id}` edits it. Use current values such as `INFREQUENT`/`FREQUENT` where applicable, not deprecated mild/intense enum names.
- `ScreenshotDisplayType` includes `IMESSAGE_APP_IPHONE_61`, `IMESSAGE_APP_IPHONE_67` and `IMESSAGE_APP_IPAD_PRO_3GEN_129`, among other iMessage sets. Match returned account requirements and upload validation; the enum name is not an instruction to resize arbitrarily.
- The downloaded specification contained no App Privacy questionnaire/data-usage resource paths. Treat the privacy-policy URL and the App Privacy questionnaire as separate tasks; verify/publish the questionnaire in the App Store Connect UI when the public API does not expose it.
