# Native Studio inside Messages — implementation and release handoff

Status: **approved product direction; planning only, not implemented**. Updated October 26, 2026 after the owner requested a native Studio with a one-time US$1 unlock. This is the starting document for a future build iteration. Read it with [product context](studio-product-plan.md), [monetization decisions](monetization-options.md) and the actual [release record](../release/release-status.json).

## Decisions to carry forward

- Update **8 bit art, App Store ID `1366485724`**, as a custom **standalone iMessage app**. Preserve host `eu.armand.--bit-art`, extension `eu.armand.--bit-art.StickerPackExtension` and team `7N3Y4QZT3Z`. Do not use the separate `1366403490` record.
- Studio opens **inside Messages**, with compact browsing and an expanded editor. A home-screen app, public web Studio and cloud service are separate projects.
- Keep the included sticker catalogue, categories, search and favorites free. Current development includes sixty stickers; the submitted build contains forty-six. Do not charge existing users again for included stickers.
- Sell **Studio Unlock**, a single **non-consumable In-App Purchase** granting permanent editor access and local saved drafts. No subscription, credits, charge per drawing, or charge per send. A recipient does not need to buy the editor to receive a sticker.
- Intended USA base price: **US$1.00 once**. Exact IAP price-point availability has **not** been verified. The earlier $1 price-point query concerned app downloads. Before configuring this product, check its own USA price points; if $1.00 is unavailable, record the real options and return the price choice to the owner. Do not silently substitute $0.99 or change the app-download price.
- Use StoreKit's localized `Product.displayPrice` in the purchase button. International prices are localized; do not promise a literal $1 in every currency. Apple's standard purchase sheet confirms payment.
- Drafts and favorites are local to the device. No app-specific user account, developer backend, advertising, analytics or automatic cloud synchronization in this MVP. Apple handles the payment and purchase history.
- Public support email: **seltzer.wisdom7h@icloud.com**. Keep the current GitHub Pages support/privacy URLs.
- This request authorizes planning and documentation. It does not create products, charge users, change pricing, withdraw a submission, build Studio, or publish a release.

Apple permits standalone sticker-pack ↔ custom standalone iMessage updates on the same record. Moving this standalone listing into a normal iOS app requires a new app record. See [app-type rules](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-imessage-app-information/) and [iMessage distribution and purchase support](https://developer.apple.com/imessage/).

## Baseline and proposed release sequence

| Baseline | What exists | Future handling |
| --- | --- | --- |
| Submitted 1.2 (5) | 46 stickers; Data Not Collected label published; submission recorded as Waiting for Review with `AFTER_APPROVAL` | Preserve tag `v1.2-build5-submitted`, metadata snapshot, signed archive and release evidence. Recheck current Apple status when resuming; this document is not a live status feed. |
| Development 1.3 (6) | 60 stickers, including fourteen additional memes and four 67 designs; unsigned builds and browser/art checks passed | Can ship as a separate art update before Studio. It has not been uploaded or submitted. |
| Native Studio release | Custom Messages browser, free search/favorites, paid 16×16 editor and multiple drafts | Prefer a later 1.4 if 1.3 ships first. If the owner chooses to combine the work before 1.3 submission, it may become 1.3. Recheck App Store version/build availability before choosing numbers. |
| Follow-up fixes | Accessibility, purchase/layout fixes and measured usability improvements | Patch release after Studio; keep the same non-consumable entitlement. |

Do not attach Studio or its first IAP to submitted 1.2 (5). Do not overwrite an existing signed archive or pretend its 46-sticker screenshots depict the new interface. The planned release split is a sequencing recommendation, not a reservation of version numbers.

## Feature contract and screens

| Feature | Free | Studio Unlock |
| --- | --- | --- |
| Included sticker catalogue, animations, categories, text search | Yes | Same catalogue |
| Favorites for included stickers | Yes, persistent | Same |
| Send/place included stickers using native Messages interactions | Yes | Same |
| Blank 16×16 editor and exact-grid remix templates | Preview of features/paywall only | Create and edit |
| Named saved drafts, rename, duplicate, delete, reopen | Existing work remains readable/exportable if entitlement is lost | Create and edit multiple drafts |
| Insert user-created stickers into the active conversation | Requires Studio | Yes, reusable without per-send charges |
| Transparent PNG export of the user's work | Existing saved work remains exportable | Yes |
| Restore Purchases, support and privacy links | Always accessible | Always accessible |

1. **Collection:** search field, category controls, favorites toggle and a native sticker grid. Keep catalogue IDs stable so favorites survive artwork updates. Search titles and tags, including `67`, `6 7` and `six seven`. Show a useful empty state and clear filters action.
2. **Studio tab:** owners see Drafts and New drawing. Others see an honest feature preview and an optional purchase action. Do not interrupt free browsing with a paywall. New drawing/Edit on a template is the entry point to the offer, never an automatic purchase.
3. **Unlock sheet:** “Studio Unlock”, localized one-time price, “16×16 editor · saved drafts · create your own stickers”, “One-time purchase. No subscription.”, Restore Purchases and dismiss. Disable Buy while loading/unavailable; keep free browsing available. Request expanded presentation if needed and verify checkout works inside Messages.
4. **Editor:** expanded canvas, title, palette, pencil, eraser, fill, undo/redo, save status, Drafts/back, Export PNG and Insert sticker. Returning to compact presentation preserves the document; offer Expand to continue editing rather than an unusably small canvas.
5. **Drafts:** named thumbnails ordered by last edit; reopen, rename, duplicate, export and delete. Confirm deletion; after a confirmed save, reopening should reproduce every cell. No artificial creation quota in the MVP; handle real storage limits visibly.
6. **Settings/help:** Restore Purchases, current unlock status, local-draft storage explanation, support and privacy links. Explain that restoring the purchase restores tools, **not deleted drawings**.

Use a UIKit `MSMessagesAppViewController` as the lifecycle/presentation boundary. Default implementation choice: host SwiftUI feature views in that controller, with reusable pure-Swift models and services. Use native sticker views for real sticker gestures; do not implement the app as a web view.

## Technical spike before full implementation

The current extension target is `com.apple.product-type.app-extension.messages-sticker-pack`, has no Swift Sources phase and uses generated `StickerBrowserViewController` in its plist. The hidden standalone host is `com.apple.product-type.application.messages`.

Create a small conversion spike using the current Xcode **custom Messages extension** template as the reference. Preserve the published identities, standalone host and icon. Update the extension's product type, build phases, module/principal-class or storyboard setup and signing as required by that template; do not leave the generated sticker-browser principal class attached to a code-based target. Keep app-extension-safe APIs enabled and retain iOS/iPadOS 15 unless a documented SDK requirement makes that impossible.

Before building the editor, prove all of the following on a real device:

- The converted app installs as an update under the same identities and opens inside Messages.
- A bundled classic, a new tiny PNG and both existing APNGs load through `MSSticker` and work in the browser.
- Compact ↔ expanded transitions work, and a test sticker inserts into the active conversation.
- A local StoreKit test purchase can present and complete from the Messages interface; also check sandbox/TestFlight before release.
- Supported system sticker surfaces still have a usable fallback. `NSStickerSharingLevel = OS` is not proof that the editor or purchase UI works in the keyboard, camera or FaceTime. Keep checkout/editing scoped to the Messages conversation context; test other contexts separately against current Apple guidance.

Resolve template, bundle-resource and StoreKit presentation problems during this spike. Do not solve them by silently creating a new app listing. [Messages controller](https://developer.apple.com/documentation/messages/msmessagesappviewcontroller), [presentation styles](https://developer.apple.com/documentation/messages/msmessagesappviewcontroller/presentationstyle), [system sticker contexts](https://developer.apple.com/documentation/messages/adding-sticker-packs-and-imessage-apps-to-the-system-stickers-app-messages-camera-and-facetime).

## Proposed source layout and catalogue migration

Paths below are planned; these files do not exist yet.

| Proposed path | Responsibility |
| --- | --- |
| `NativeStudio/MessagesViewController.swift` | Messages lifecycle, current conversation, compact/expanded transitions, SwiftUI containment |
| `NativeStudio/Views/` | Collection, draft list, editor, unlock sheet and help |
| `NativeStudio/Models/PixelDocument.swift` | Versioned 16×16 document model and validation |
| `NativeStudio/Models/StickerItem.swift` | Stable catalogue IDs, categories, search tags and descriptions |
| `NativeStudio/Services/CatalogStore.swift` | Load bundled catalogue and construct/cache native stickers |
| `NativeStudio/Services/DraftStore.swift` | Serialized atomic document persistence, recovery, thumbnails |
| `NativeStudio/Services/PixelRenderer.swift` | Deterministic transparent PNG generation |
| `NativeStudio/Services/StudioPurchaseStore.swift` | StoreKit products, verified entitlements and purchase state |
| `NativeStudio/Services/StickerInserter.swift` | Local-file sticker insertion and completion/error handling |
| `NativeStudio/Resources/` | Generated native JSON catalogue, raw tiny templates, bundled PNG/APNG files and localized strings |
| `NativeStudioTests/` | Pixel operations, document/persistence/export and commerce state tests |
| `Config/Studio.storekit` | Local StoreKit test product; no live credential or production receipt |
| `scripts/build-native-catalog.py` | Deterministically package the existing art for the code-based extension |

`art/manifest.json` contains **50 generated designs only**. `scripts/build-preview.py` combines these with the **ten classics** to build the sixty-item browser catalogue. The native generator must use the same full source set, not mistake the art manifest for all sixty. Refactor the shared catalogue-building logic rather than parsing JavaScript or maintaining a hand-copied list.

Native entries need ID, localized title/accessibility description, category/tags, animation flag, bundle-relative export filename, logical size and optional raw template data. Keep old artwork pixels, APNG timings, IDs and native sticker order intact; omit wine. Generate copied resources/manifest from tracked source and commit outputs so ordinary Xcode builds need no Python. Verify bundle paths in the new target rather than assuming `.xcstickers` compiles identically after conversion.

Only the **38 true 16×16** sources are initial remix templates. Do not silently shrink the 50×50 revival art or recovered originals. Built-in animations remain sendable but animation editing is outside this MVP.

## Pixel model, drawing and export

The browser Pixel Lab currently uses **32×32 / 1,024 cells** (`prototype/app.js`, `N = 32`). Its interaction patterns are useful; its draft dimensions are not the native specification. Implement a **16×16 / 256-cell** native model. Browser localStorage drafts/favorites do not migrate automatically.

Proposed document schema version 1: UUID; title; created/updated dates; width/height fixed to 16; a palette of explicit sRGB RGBA values with transparent index 0; exactly 256 row-major palette indices; optional source template ID. Reject unsupported dimensions, invalid color indices, oversized titles and unsupported schemas without destroying the original file. Keep custom documents independent of mutable catalogue entries.

- Pencil and eraser operate on whole cells. Interpolate pointer movement so quick drags leave no gaps. A completed stroke is one undo step.
- Fill uses four-neighbor connectivity and handles no-op fills without adding history. Undo/redo retains the last fifty operations in memory; a new edit clears redo. Durable draft pixels, not undo history, are the persistence requirement.
- Start with a fixed, accessible palette and transparency. Do not enforce the catalogue's six-color art rule on user drawings. No antialiasing, gradients, photo access or image-import workflow in the first native release.
- Render a logical RGBA image at 16×16, enlarge **18×** to 288×288 with nearest-neighbor sampling, then center it in a **300×300** transparent PNG with six pixels of padding per side. Do not stretch to fractional 18.75× cells. Checkerboards, cursor and grid never enter exports.
- Reject an empty transparent drawing before insertion, with a clear prompt to draw. Validate the generated file and its size; use the existing under-500,000-byte release check. Export raw 16×16 and native 300×300 sizes as named options if both are exposed.
- Persist the render in a disposable cache with a stable lifetime long enough for the Messages insertion/drag operation. Do not delete the file immediately after starting the asynchronous insertion.

Apple's [sticker initializer](https://developer.apple.com/documentation/messages/mssticker/init(contentsoffileurl:localizeddescription:)) requires a local image file and a localized accessibility description, and documents supported image sizes/formats. Keep the existing 300×300 format unless device testing gives a reason to change it.

## Persistence and extension lifecycle

Use the extension's Application Support directory with one versioned document per UUID and an atomic write strategy. Store favorites as stable catalogue IDs. Keep thumbnails/render caches separate from editable source. An App Group is not needed for this extension-only scope; introduce one only if another real target needs shared data.

Save after each completed stroke, fill, rename and other meaningful document mutation, serialized off the main thread with ordered completion. Track dirty state until persistence succeeds. Lifecycle callbacks provide an additional flush, not the only save path: Messages can terminate the extension. A visible save failure must retain in-memory edits, offer retry/export and never claim “Saved”. Only delete a draft after its confirmed deletion action.

On startup, load valid documents and isolate corrupt ones with a recovery message and export/recovery path. A damaged draft must not stop the catalogue or other drafts from opening. Duplicate creates a new UUID. Resume the last active draft when practical; presentation transitions, keyboard changes and conversation changes must not clear it.

Show a short storage notice: “Drafts stay on this device. Deleting the app can remove them. Export drawings you want to keep.” Restore Purchases recovers the feature entitlement, not artwork. No promise of cross-device drafts, permanent local retention after uninstall, or browser-to-native migration.

## Native insertion behavior

Use `MSStickerBrowserView` / `MSStickerView` for included and saved stickers where practical, preserving native tap/hold/peel/drag behavior. For the editor's explicit **Insert sticker** action, validate the latest drawing, save it, export a local PNG, create `MSSticker`, check `activeConversation`, and call `MSConversation.insert(_:completionHandler:)` for the sticker.

Insertion places the sticker in the Messages composer; **the user taps Send**. Do not report delivery or delete the draft after insertion. Handle no active conversation, unsupported presentation context, export failures and insertion errors. Keep UI work on the main actor; respect the callback's threading contract. In other supported contexts expose an appropriate native sticker browsing/insertion fallback, not an assumed full editor.

[Apple's insertion contract](https://developer.apple.com/documentation/messages/msconversation/insert(_:completionhandler:)-7fpdd) and [native sticker browser](https://developer.apple.com/documentation/messages/msstickerbrowserview).

## Studio Unlock product and entitlement implementation

Proposed product ID: **`eu.armand.--bit-art.studio.unlock`**, display name **Studio Unlock**, description **16×16 editor and saved drafts.** These are planned identifiers/strings, not a product already registered. Verify the ID is unused and valid for this app before creation; once registered, use the same exact ID across source, local StoreKit config and App Store Connect. Do not create one product per design or version.

Use StoreKit 2, compatible with the existing iOS 15 baseline. Keep purchases behind a single testable service; views never decide ownership from an ordinary preferences flag. Check the registered explicit identity and applicable target/signing configuration against the current Xcode template. No invented payment entitlement or developer payment server is needed for this plan. [Sandbox availability guidance](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox).

Entitlement flow:

1. Start one managed `Transaction.updates` listener when the extension process starts; avoid duplicate listeners on every view appearance.
2. Read verified `Transaction.currentEntitlements` on activation and after purchase/restore/account-state changes. Match the exact product ID; reconcile listener events and snapshots serially so a stale result cannot overwrite a newer successful purchase.
3. Load the StoreKit product independently of entitlement. A product-price/network failure must not remove previously verified ownership or block the free collection.
4. Start `purchase()` only after the user's Buy action. Grant access after verified success, deliver the unlock, then finish the transaction. Handle repeated deliveries idempotently.
5. Pending/Ask to Buy keeps free browsing usable. Later verified approval must unlock through the listener, including after termination/relaunch. Cancellation leaves the prior entitlement unchanged. Unverified transactions never grant access.
6. Always expose Restore Purchases. On that explicit action, call `AppStore.sync()` and reread entitlements. Do not prompt authentication by calling sync automatically during launch. Distinguish “No Studio purchase found” from a network/restore failure.
7. Respect verified refunds/revocations/account changes. Lock new paid editing/insertion if entitlement is lost, but retain drafts and favorites and permit viewing/export of existing work. A transient failure is not evidence of revocation.

[Current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements), [transaction delivery/finishing](https://developer.apple.com/documentation/storekit/transaction), [purchase results](https://developer.apple.com/documentation/storekit/product/purchaseresult), [user-initiated restore](https://developer.apple.com/documentation/storekit/appstore/sync%28%29).

| UI state | Required behavior |
| --- | --- |
| Checking | Free collection works; avoid briefly showing Buy to a known owner. Resolve ownership before opening paid tools. |
| Not owned; product loaded | Optional localized one-time offer and Restore Purchases. |
| Buying | Show progress and suppress duplicate Buy taps; preserve current drawing/navigation. |
| Pending | Say approval is pending; no unlock yet; allow continued free use. |
| Owned | Editor/drafts enabled; no further charge per drawing/send. |
| Product/verification unavailable | Explain retry/restore; keep free features and existing work available; retain a known verified entitlement when appropriate. |
| Refunded/revoked | Paid editing/insertion locked after verified reconciliation; drawings retained for viewing/export. |

Offline requirement: once ownership has been verified locally, editor/draft use must work offline using valid locally available StoreKit entitlement information. Do not rely on a bare saved Boolean, force a purchase recheck network round-trip before every edit, or promise immediate detection of offline refunds. A fresh install without resolvable ownership may need an online restore. Test these cases on a device.

**Family Sharing is undecided and must remain off during initial setup.** Non-consumables can support it, but Apple does not allow disabling it after it is enabled. Bring that choice to the owner before enabling it; if later enabled, add family/revocation cases. [Family Sharing rule](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases/).

## Accessibility, privacy and website scope

- Support VoiceOver titles and sticker descriptions, Dynamic Type, adequate targets and contrast, Reduce Motion, and visible selection/tool state. Do not use color alone to communicate state.
- Provide an accessible non-gesture canvas route: labeled row/column cursor, directional controls and Paint/Erase actions, usable with VoiceOver/Switch Control. Keyboard arrows and explicit paint action are useful on iPad. Test the editor, not just the paywall, with assistive technology.
- Keep animation previews manageable for Reduce Motion. Preserve the actual APNG when sending an included animated sticker.
- Store drafts/favorites locally, keep image/entitlement data out of diagnostic logs, and add no analytics or account system. Re-audit the final binary, privacy manifests and App Privacy answers before release; do not copy the prior declaration blindly after adding SDKs or data flows.
- Update public support/privacy wording to explain native drawings, local storage and Apple-managed purchases when Studio is released. The current site is **GitHub Pages**, `https://mim-armand.github.io/8bit-stickers/`; its `/support/` and `/privacy/` routes remain the support destinations.
- The browser Studio remains localhost-only. No new hosting is required for the native editor. Publishing a web editor, purchasing on the web or sharing a web/native entitlement is outside this plan.

## Implementation milestones and acceptance gates

| Milestone | Deliverable | Gate before proceeding |
| --- | --- | --- |
| S0 — conversion spike | Custom standalone Messages target, sample catalogue and local purchase test | Same identities; actual device launch, native insertion/APNGs, compact/expanded and checkout proven |
| S1 — free collection | Full sixty-item native JSON/resources, categories/search/favorites | All sixty available without purchase; four 67 results; originals/animations intact; persistent favorites; context fallback works |
| S2 — editor and drafts | 256-cell model, tools, autosave, multi-drafts, transparent export/insertion | Pixel/export tests and termination recovery pass; real iPhone/iPad editor usable |
| S3 — commerce | StoreKit 2 purchase/restore service and optional paywall; configure the draft App Store IAP after checking its ID/price so real sandbox tests can run | Commerce matrix below passes in local StoreKit and relevant real sandbox flows; no draft loss |
| S4 — release candidate | One signed build, first IAP configured, real screenshots and support/privacy updates | Exact USA IAP price verified; product+app ready for same submission; full acceptance evidence recorded |
| S5 — release | Owner-authorized upload/submission and chosen release mode | App and IAP availability verified after approval; source tag/archive/readback retained |

Keep each milestone in reviewable commits/PRs with source, tests and generated art together. Do not release an editor with an unfinished purchase path or quietly deliver the paid feature as an unannounced free unlock. A standalone free browsing update is possible if explicitly chosen; the permanent Studio purchase should launch with a usable editor and draft flow.

### Required test matrix

| Area | Cases and expected result |
| --- | --- |
| Upgrade/catalogue | Install update over the existing app; full included set accessible free; IDs/icon preserved; wine absent; PNG/APNG pixels/timings unchanged |
| Presentation | Small/large iPhones and iPad, portrait/landscape where supported, compact/expanded, keyboard and conversation changes; no obscured controls or cleared work |
| Drawing | Fast drags, edges, erase, four-neighbor fill, no-op fill, grouped undo/redo, clear, blank rejection and 38 exact-grid remix templates |
| Export | 256-cell round-trip, 18× integer scale, 6px padding, 300×300 RGBA, transparent background, no grid/smoothing; file under limit |
| Persistence | Multiple drafts, rename/duplicate/delete, close/reopen, force termination, interrupted/failed write, corrupt/unsupported document; valid work preserved and errors visible |
| Messages | Insert then user Send, receive on another device, tap/peel/place where supported, APNG playback, absent conversation/insertion failure; drafts survive all outcomes |
| Purchase success | Exactly one confirmed non-consumable purchase unlocks immediately; no repeated charge per drawing/send; duplicate transaction delivery harmless |
| Purchase incomplete | Cancel, failure, restrictions, unavailable product, pending approval then approve/decline, unverified result; no false unlock and free collection usable |
| Purchase lifecycle | Terminate during purchase; approval while extension closed; relaunch reconciles correctly |
| Restore/account | Fresh installation/device and same App Store account restore ownership; no-purchase restore is distinct from failure; account change/refund/revocation reconciles without deleting drawings |
| Offline | Previously verified owner edits/saves/inserts offline; metadata fetch failure does not lock owner; first-time purchase/restore handles lack of network |
| Localization | Actual `displayPrice`, non-USA currency, large text, long strings, VoiceOver/cursor editing and Reduce Motion |
| Distribution | Local `.storekit` tests plus sandbox/TestFlight inside **real Messages**; passing a simulator build is insufficient for purchase and sending claims |

Use pure model/rendering/persistence tests for deterministic behavior, StoreKit test sessions for commerce state transitions, focused UI tests for free versus paid paths, and a concise manual device script for Messages/system-surface gestures. Extend existing art/browser checks rather than replacing them. Store ignored logs/receipts/screenshots safely; commit only sanitized evidence summaries.

## App Store setup and release checklist for the future iteration

1. Read current branch/tag, `Config/AppStoreMetadata.json`, `release/release-status.json` and live App Store Connect status before edits. Confirm whether 1.3 already shipped and choose an unused version/build. Current support identity and submitted 1.2 evidence are not to be overwritten.
2. Complete S0–S2 and the local StoreKit test implementation. Keep signing keys, provisioning profiles and real receipts outside Git. Recheck explicit App ID/product/signing configuration and App Store **Paid Apps Agreement, tax and banking readiness**. Configure the draft IAP in the next step before S3's real sandbox tests; local StoreKit testing alone does not establish sandbox availability.
3. Create the one non-consumable Studio Unlock product under app 1366485724, using the exact checked product ID. Add localized name/description, territories, review screenshot and review notes. Verify its **IAP** USA price points, select exact $1.00 if available, and save price/availability readback. Display real StoreKit pricing. Do not enable Family Sharing without the owner's decision.
4. Complete S3 using the configured product in real sandbox/TestFlight Messages sessions, then obtain the final signed candidate. Capture actual native iPhone/iPad screenshots showing free catalogue, editor, drafts and accurate optional purchase messaging. Add the IAP review screenshot from the real unlock sheet. Never substitute the browser prototype/art boards for shipping UI.
5. Update description, What's New, support/privacy pages and reviewer instructions. Explain “Messages → 8 bit art → Studio → Studio Unlock”, one-time purchase, Restore Purchases, no account, local draft behavior and access to included stickers. Verify the app's age-rating/privacy answers for the actual build.
6. Submit the **first non-consumable and its new app version in the same review submission**. The current build 5 cannot gain StoreKit features from a metadata change. Check product readiness/missing metadata and association before sending the app to review. [Apple's first-IAP submission requirements](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/).
7. When the owner asks to build/release, complete validation and present the concrete candidate with test evidence and price readback. Follow the release authorization then in force. Recommend automatic release after approval to match the owner's earlier preference; verify `AFTER_APPROVAL` on the new version when authorized, rather than assuming build 5's setting carries over.
8. Tag the exact submitted source, preserve the signed archive/IPA and sanitized metadata/product/submission IDs, update release docs and refresh the Git backup bundle. After approval, verify **both app and IAP availability**, production price and restore behavior, and update the public site. Do not mark Studio released based only on upload or app approval.

Official setup references: [IAP product types](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types/), [IAP price schedules](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase/), [localized display price](https://developer.apple.com/documentation/storekit/product/displayprice), [IAP information fields](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/), [StoreKit testing](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-in-xcode).

## Deferred scope and decisions still to resolve

Outside the MVP: subscriptions, consumable credits, paid individual stickers, public galleries, user accounts, cloud draft sync, public web Studio, photo import, animation creation, arbitrary canvas sizes, home-screen app and automatic cross-browser migration. Existing artwork remains preserved in Git.

Resolve during the future build: exact IAP $1 availability; final product ID registration; current SDK/template and supported presentation contexts; actual release number/build; and any owner decision to enable Family Sharing. These do not block documentation. If SDK limitations change the agreed in-Messages experience or the exact price is unavailable, document the concrete finding and bring that decision back before altering the product promise.

**Completion means:** the owner can install the update to the same listing, continue using included stickers/search/favorites free, buy Studio once at the verified localized price, create/reopen a 16×16 drawing, insert it into Messages, restore the tools on another device, and retain their saved artwork through recoverable errors. Release evidence must show those behaviors, not only a successful compile.
