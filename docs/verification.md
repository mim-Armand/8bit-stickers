# Verification — October 26–27, 2026

## Public Studio candidate — 1.4 (10)

The owner requested preparation of the paid Studio update. Production App Store StoreKit code passed **29 AppStore / 26 screenshot-configuration / 31 Debug** core/model checks and an additional **1 ordinary Release restriction check**. Actual Messages UI checkout completed with verified Xcode StoreKit purchases on iPhone and iPad. No remote Apple sandbox/device purchase is claimed. The visible offer supplies supported UIKit controller/scene confirmation; verified ownership is scoped to the published app/product/non-consumable and never comes from test preferences.

Clean signed archive/export and Apple validation/upload succeeded with zero errors and expected hidden Messages-only warnings 90863/90984. Build `626b2c8b-f888-4d02-81f5-14999de27c89` is **VALID / APP_STORE_ELIGIBLE / IN_BETA_TESTING** and selected in the unsubmitted **1.4** draft, with **AFTER_APPROVAL** retained. Both privacy manifests declare app-local UserDefaults reason CA92.1; the IPA excludes wine, test fixtures, browser bridge, preview host and StoreKitTest.

Eight reviewed native captures have **16 COMPLETE App Store/Messages placements**, and the IAP review screenshot is COMPLETE. Inherited copies were retired only from draft 1.4; published image IDs were protected. Studio Unlock's exact US$1.00 schedule and text are saved. Automatic approval review rejected enabling the proposed 175 territories, so availability remains unchanged pending explicit owner approval; the IAP currently reports MISSING_METADATA / version PREPARE_FOR_SUBMISSION. No public app/IAP review was submitted.

Public **1.2 (5)** is now approved and Ready for Distribution; its prior review is COMPLETE. See the [release handoff](studio-release-preparation.md) and [sanitized status](../release/studio-1.4/preparation-status.json) for current evidence and outstanding availability/device checks. Detailed logs/readbacks and signed output stay ignored under `build/studio-release/`. Support/privacy source is updated; no website deployment occurred.

## Native Studio — sandbox purchase configuration 1.4 (9)

After the free beta was distributed, the owner selected Apple's actual sandbox purchase/restore flow. A separate release-based **TestFlightSandbox** configuration and **Studio Sandbox Internal** scheme now use **1.4 (9)**. Clean signed archive/export and Apple validation/upload succeeded with zero errors and expected warnings 90863/90984. Upload `97fbb69d-ef07-4c84-800a-3798ceaec769` is **PROCESSING** with no processing errors; the verified internal group automatically receives completed builds. Check the [sandbox guide](studio-sandbox.md) for the current distribution state; this section does not claim an installed device or completed remote transaction.

The draft **Studio Unlock** non-consumable is registered under the existing app as **`eu.armand.bitart.studio.unlock`**, Apple ID **`6827336076`**. Apple rejected the earlier proposed ID because IAP identifiers cannot contain hyphens; that ID was never registered and the app/extension identities are unchanged. English localization is saved in metadata version `45b42e0b-bc8a-4835-8bc8-4d766e48bda1` (`PREPARE_FOR_SUBMISSION`). The actual IAP's exact **US$1.00** point was found, scheduled and read back. Family Sharing is false. No public-sale availability or review screenshot/submission was created; product state remains `MISSING_METADATA`.

Read-only Business UI verification on **October 26, 2026** confirmed **Paid Apps Agreement ACTIVE**, effective **October 22, 2026–May 15, 2027**, **bank account ACTIVE** and **US tax form ACTIVE**. Sanitized statuses are saved under ignored `build/studio-sandbox/business-readback.json`; personal/bank details are not committed. Recheck these statuses before public sale.

**29 sandbox/model tests and 31 Debug regression tests passed** on the iPhone 15 Pro Max / iOS 17.5 simulator. Sandbox tests verify isolation from mock/free-beta ownership, disabled initialization and strict environment acceptance. A real signature-verified Xcode transaction is rejected by the sandbox adapter. Debug regression covers actual Xcode purchase → restore → refund with the valid shared product ID. Evidence is ignored `build/studio-sandbox/sandbox-tests.log`/`.xcresult` and `debug-regression.log`/`.xcresult`. These checks do not establish a transaction against Apple's remote sandbox; purchase/restore still needs TestFlight on a physical device.

The sandbox mode displays Apple's localized price and a no-real-charge notice. It accepts verified sandbox transactions only and rejects production, Xcode and unknown environments. Normal Release checkout stays disabled. Existing free beta build 8 retains its separate device-local activation behavior. The public **1.2 (5)** remains **Waiting for Review / AFTER_APPROVAL**, with its original selected build unchanged.

## Native Studio — free internal TestFlight 1.4 (8)

The owner requested TestFlight after local implementation. A clean signed archive/export of the dedicated release-based **TestFlight** configuration passed final Apple validation and upload with **zero errors** and expected hidden Messages-only compatibility warnings **90863 / 90984**. The first validation found missing host icon metadata; an opaque regular AppIcon and `CFBundleIconName` fixed it before the successful upload. The icon retains the original source pixels.

Apple readback confirms build **`886a1635-0abf-4a13-9299-12aa814bcbd9`**, version **1.4 (8)**, processing **`VALID`**, audience **`INTERNAL_ONLY`**, internal state **`IN_BETA_TESTING`**, external state **`NOT_APPLICABLE`**. The account holder is invited to the existing internal group and the beta build is available there. No physical-device installation or accepted invitation is claimed. The selected public **1.2 (5)** build remains **Waiting for Review / AFTER_APPROVAL**.

**29 beta/model tests and 2 beta UI tests passed** on iPhone 15 Pro Max / iOS 17.5. They exercise free beta activation, persistence/restore, isolation from local mock ownership, normal disabled initialization and preserved drawings. **31 existing Debug model/purchase tests passed again**, including the actual Xcode StoreKit test. Build 8 performs no product lookup/purchase/payment call; actual Apple sandbox transactions remain untested.

The signed IPA has exactly 67 included stickers, 45 templates and no wine. Both bundle identities and version/build match; its host declares `TFInternalTestingOnly=true`. Preview host, XCTest/HTML bridge and `.storekit` files are excluded. Logs, xcresults, archive, IPA and private tester readback are ignored under `build/studio-testflight/`. The sanitized [beta status](../release/studio-testflight-status.json) records its SHA-256 and distribution fields; [installation/build guide](studio-testflight.md) explains the beta and remaining production work. No IAP or pricing change was made during the build-8 phase; the later authorized draft sandbox product is recorded above. The public website remains unchanged.

## Native Studio — original local verification

The separate `NativeStudio/Studio.xcodeproj` implements the custom standalone Messages extension and a local preview host. Both share the native catalogue, editor, draft and purchase UI. All 67 included stickers are available free; 45 sources support exact-grid remixing. Local project version 1.4 (7) is a development label, not an uploaded or reserved App Store version. The original 1.3 (6) sticker project, active App Store metadata, submitted 1.2 records/screenshots and archive script remain byte-identical to the preceding source revision.

**Builds:** unsigned Debug simulator/device and Release device Messages builds passed under Xcode 27.1. The custom extension preserves the parent/extension bundle identity. Other media contexts use a native browsing-only fallback; full keyboard/camera/FaceTime coverage and physical-device testing remain future release checks.

**Models and commerce:** 31 unit tests passed on the iPhone 15 Pro / iOS 17.5 simulator. They cover document validation, interpolated strokes, fill/history, atomic multi-draft persistence/favorites, corrupt-file recovery, exact PNG dimensions/padding/pixels, all 67 bundled resources, all 45 templates, APNG frames, local purchase states and fail-closed checkout. The actual `SKTestSession` test loaded the local non-consumable at $1.00, completed a verified Xcode transaction, restored it through a new service instance and revoked it through a simulated refund while preserving unrelated work. Evidence: ignored `build/native-studio-core-final.log`/`.xcresult` (all 31 passed again after the final commerce retry fix), with earlier full-run evidence in `native-studio-tests-2.log`. These are Xcode-local transactions, not Apple sandbox/TestFlight or production purchases.

**User flow:** both preview UI cases passed on iPhone 15 Pro and iPad Pro 13-inch / iOS 17.5: free 67-item search/favorites and persistence, optional offer/dismissal, requested-remix continuation after unlock, renaming, drawing, undo/redo, autosave, preview insertion confirmation and reopening after termination. A further run verified the final responsive phone editor. Tests use isolated test preferences/drafts. Evidence: ignored `build/native-studio-ui-final.log`, `native-studio-ui-verified.log` and result bundles.

**Actual Messages:** the iPad simulator opened the custom Studio from the real Messages app, expanded the workspace, unlocked locally, created a drawing and inserted its PNG into the conversation composer. The Send button became enabled; the test never tapped it. Evidence: ignored `build/native-studio-message-verified.log`/`.xcresult`. This proves local insertion, not remote delivery.

**Interactive local viewer:** a UI-test-only server binds to 127.0.0.1:8792 and mirrors the real simulator app, because this environment has runtimes without the Simulator window app. Browser checks verified real screenshot delivery, a browser tap changing the native screen, typing into a native search field, desktop/mobile layout and rejection of foreign origins/invalid coordinates. It makes no purchase and cannot control Messages or other apps. This viewer is not part of the shipping binary.

Native resource verification checks all 67 copied image files byte-for-byte against source and all 45 logical templates pixel-for-pixel. The existing browser and artwork checks also passed after shared catalogue assembly was extracted to `scripts/catalog-source.py`; the generated browser catalogue stayed unchanged. Screenshots under `docs/previews/native-studio/` were captured from the local preview host and actual simulator Messages app, with fictional data. They are not submitted App Store screenshots.

The default unlock is a clearly marked no-charge simulation; Xcode StoreKit mode requires the supplied local configuration. Normal release builds disable checkout. At the original local-verification stage, no Apple upload or account setting was changed. The subsequently authorized free beta and sandbox setup are recorded above. Public review, app-download pricing and the website remain unchanged; the draft IAP has its own verified US$1.00 schedule. See [local testing instructions](native-studio-local.md) and [remaining release gates](native-studio-implementation-plan.md).

## Development art expansion — 1.3 (6)

The current source contains **67 available stickers, with wine excluded**: ten classics plus fifty-seven generated designs. The latest seven are Snack goblin, Unbothered capy, Big shrimp energy, Yap duck, Delulu bunny, I saw nothing and the 67 unlocked trophy, bringing the forthcoming meme additions to twenty-one and the 67-themed set to five. `scripts/verify-art.py` passed for all fifty-seven generated designs: raw/native/browser pixels and animation timing match editable sources, all exports have transparency and remain below 500 KB, and the 45 tiny sprites retain their logical 16×16 grid with at most six opaque colors and no rim. The verifier also checks unique native references, release-draft count agreement and wine exclusion. An independent review confirmed that all prior sixty designs retain their decoded pixels/animation timing and the ten classics remain byte-identical.

Clean unsigned **simulator and device Release builds passed** under Xcode 27.1. Both built extension bundles contain exactly sixty-seven sticker PNGs, exclude wine, and agree with the parent app on **version 1.3, build 6**. The new set has not been signed, uploaded, submitted or tested on a physical device. Logs are ignored `build/club67-simulator-check.log` and `build/club67-device-check.log`. The preceding sixty-sticker source also passed its separate builds and browser/art checks before these seven were added.

The full Playwright Studio check passed with installed Google Chrome: sixty-seven images decode, the tiny filter has 45 designs, Cute has twelve, Memes has thirty-three, and `67`, `6 7` and `six seven` each find all five number-themed stickers. Favorites, downloads, chat preview, editor tools, draft persistence, remixing and desktop/mobile layouts passed without browser or HTTP errors. The newest seven appear first in the preview. Updated screenshots are under `docs/previews/`; `club67-board.png` shows the latest seven and `meme-expansion-board.png` preserves the prior fourteen. Browser evidence is ignored `build/club67-browser-check.log`.

The submitted **1.2 (5)** remains unchanged at `v1.2-build5-submitted`. Its metadata is copied verbatim to `release/1.2-build5-metadata.json`; `release/release-status.json` and `release/screenshots/manifest.json` remain byte-identical to the submitted record and still describe forty-six stickers. The active `Config/AppStoreMetadata.json` is now a local 1.3 (6) draft. No App Store Connect or public website mutation was performed for this expansion. The sections below preserve the earlier release's evidence.

## Native pack

The initial expanded source passed unsigned simulator/device Release builds under Xcode 27.1 (27A9275), with 47 entries and two APNGs. At the owner's request, the wine-glass sticker was then omitted from shipping assets, producing release candidate **1.2 (5)** with **46 stickers: 10 classics and 36 new designs**. The revised candidate passed a clean simulator build and clean signed device archive/export, with wine absent from those products. The parent and extension identifiers match the recovered project. All eleven original sticker PNGs are preserved byte-identically to recovered commit `816eba1`; ten ship and wine is archived at `art/recovered/wine_01.sticker/`. The initial twelve revival designs are also byte-identical to commit `423256b` in both their native and browser copies.

The initial 47-sticker app installed into an iOS 27.0 iPhone 17 simulator; `pluginkit` confirmed `eu.armand.--bit-art.StickerPackExtension` version 1.2 registered in Messages. Messages launched successfully. Apple supplies the sticker browser runtime for this catalog-only extension.

The pack also rendered in the iOS 17.5 native Messages sticker picker. The current iOS 27 simulator fixture omitted the system Stickers entry itself; comparison against Xcode 27.1's templates found matching product types, principal class and sharing keys. Registration alone was not treated as proof of rendering.

See [native MVP](native-mvp.md) for build commands. Installation over the published app, real-device send/place behavior, animation playback, iPad layouts, TestFlight use and App Review remain separate checks.

## Signed build and App Store staging

The owning team and distribution signing path were verified. The revised **1.2 (5)** candidate has a clean signed archive and exported IPA under ignored `build/release/1.2-5/`. Apple validation/upload succeeded without errors and with two expected hidden-app Mac/visionOS compatibility warnings. Delivery UUID: `ecc379bc-4471-489b-887b-826ec30d9c6b`; ignored evidence is `build/release/apple-validation-build5.json` and `apple-upload-build5.json`. Build 5 processed as `VALID` and is selected in the 1.2 draft. It reports `usesNonExemptEncryption: false`, `READY_FOR_BETA_TESTING` internally and `READY_FOR_BETA_SUBMISSION` externally. No completed TestFlight device pass is claimed. A stale wine file was caught in an incremental build product, so release preparation now uses a clean archive and explicitly verifies wine is absent from the simulator bundle, archive and IPA.

The preceding **1.2 (4)** passed Apple's validation/upload with zero errors, then processed as `VALID`. Its two expected compatibility warnings concerned the hidden sticker-only app being unlaunchable as a normal Mac or visionOS app. Build 4 is not the intended release because it contains wine. Build 5 replaced it as the selected build in version `7c6caa34-4ee8-4423-87d9-e4acc09b1b40`, which now reports **Waiting for Review** with release type **`AFTER_APPROVAL`**.

The revised description, keywords, promotional text, support/privacy URLs and review notes were saved and read back through the API. Evidence is ignored `build/release/draft-metadata-readback.json`. Existing App Review contact details remain private. Removing wine and declaring alcohol references `NONE` produces API age rating `FOUR_PLUS` without an override.

Six actual native screenshots were captured for build 5's 46-sticker pack: three iPhone RGB images at 1179×2556 and three iPad RGB images at 2064×2752. The source manifest is `release/screenshots/manifest.json`, with `nativePackBuild: 5`, `stickerCount: 46` and `wineExcluded: true`. The same six images form twelve placements across `APP_IPHONE_61`, `IMESSAGE_APP_IPHONE_61`, `APP_IPAD_PRO_3GEN_129` and `IMESSAGE_APP_IPAD_PRO_3GEN_129`; all processed as `COMPLETE`, with no errors. Ignored readback evidence is `build/release/screenshot-upload-readback.json`. Legacy 2018 placements were removed only from draft 1.2; published 1.1 sets/assets were protected.

The **Data Not Collected** App Privacy label was published through the App Store Connect UI, which showed “Published a few seconds ago by mim Armand”; evidence is ignored `build/submission/privacy-published.jpg`. Review submission `d6780537-3c51-43b3-97d9-67f900dfc768` was submitted at `2026-10-26T20:01:02.003Z` / October 26, 2026, **3:01 PM CDT**. API readback verified both the submission and version as `WAITING_FOR_REVIEW`, release type `AFTER_APPROVAL` and selected build 5 unchanged. Evidence is ignored `build/submission/review-submitted.json` and `final-readback.json`; public fields are recorded in [`release/release-status.json`](../release/release-status.json). The update has not yet been approved or publicly released. A physical-device/TestFlight pass remains optional; simulator capture and processed-build acceptance do not establish that testing.

## Public support website

The app page, support instructions and privacy policy are live at `https://mim-armand.github.io/8bit-stickers/`, `/support/` and `/privacy/`. All three returned HTTP 200, the GitHub Pages build completed, and HTTPS enforcement is enabled. The published `gh-pages` source is commit `30355ecd03d7b135b002f614803367d73eb3c805`. The public homepage now describes 46 stickers, and all three pages were rechecked with HTTP 200 responses after that update.

This deployment contains only the app/support/privacy site. It does not publish the interactive Sticker Studio or its pixel editor.

## Artwork

`scripts/generate-art.py` validates generated images as RGBA with transparent pixels, 300×300 dimensions, and each below 500 KB. The expanded collection contains 36 generated designs: 12 revival designs and 24 cute/meme designs on a true 16×16 source grid. The expanded set passes source-pixel and animation-timing checks for both native and browser exports. The heart contains four APNG frames and the robot three. Native generated files are 895–4,419 bytes each. Regeneration was checked twice byte-for-byte in the local Pillow 12.3.0 environment. Pixel sources and palettes are committed alongside exports. The latest twenty-four PNGs retain a 16×16 logical grid, enlarged 18× to 288×288 and centered in a transparent 300×300 native canvas; no smoothing or white rim is added.

`scripts/verify-art.py` compares every decoded native/browser frame and animation duration directly to the editable source. This is the cross-platform integrity check: PNG compression bytes differ between the local macOS encoder and GitHub's Linux encoder even when decoded pixels are identical.

## Browser Studio

The initial expanded 47-sticker source passed `scripts/verify-preview.cjs` against the local server using Playwright and installed Google Chrome. The revised gallery contains 46 stickers because wine is omitted. The prior Studio checks covered:

- All original expanded catalog image paths decode, and no JavaScript errors or failed HTTP responses occur.
- New/original/animated/theme filters, the 24-sticker tiny collection, 12 Cute and 12 Memes filters, text search and empty-state reset.
- Favorites survive a reload; local conversation preview updates to the chosen sticker.
- The original PNG downloads with its correct filename; a tiny source PNG downloads at its actual 16×16 resolution.
- Pixel drawing, erasing, flood fill, undo, draft persistence and remixing work.
- Pixel export produces a 300×300 RGBA PNG; the export canvas is transparent before drawing.
- Collection and editor fit a 390-pixel viewport without horizontal overflow.

Reviewed screenshots: `studio-desktop.png`, `studio-mobile.png`, `pixel-lab-desktop.png` and `pixel-lab-mobile.png` under `docs/previews/`. These show browser prototypes, not App Store screenshots of shipped iOS functionality.

The Studio is served locally, has no service API calls and uses local browser storage. It has not been deployed as a public website. Browser storage can be cleared or disabled; downloaded artwork and committed source remain separate from drafts.
