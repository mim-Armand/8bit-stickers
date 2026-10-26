# Native Studio — local testing build

Implemented October 26, 2026 at the owner's request. This guide describes the original **local Debug/testing build**. The owner subsequently requested TestFlight access: **1.4 (8) is now available for internal testing with free beta activation**; see the [TestFlight guide](studio-testflight.md). Public App Review and production IAP setup remain deferred. The original sticker-only project and pending 1.2 (5) release remain intact.

## Try it in the local browser viewer

Open **http://127.0.0.1:8792/** while the preview runner is active. This displays and controls the **actual native iPhone simulator app** through a development-only XCTest bridge; it is not a browser reimplementation of Studio. Click/tap native controls, drag to draw or scroll, and use the text-entry box after tapping a native search/name field. The viewer confirms that all payments are local tests. Reloading the app preserves ordinary local drafts.

The environment used for this work has simulator runtimes without a Simulator window app, so the viewer provides the interactive route here. On a Mac with the full Simulator app, use the Xcode schemes below directly.

Start or restart the local viewer with a booted iPhone simulator:

```sh
./scripts/run-native-viewer.sh SIMULATOR_UUID
```

Keep the command running; Ctrl+C stops it and each preview session expires after one hour. It listens only on 127.0.0.1 and controls only the development preview app. It does not provide a public website or a backend for the shipping app. The bridge/HTML live only in the test target and are not bundled into the native Messages product.

## Try it in Xcode

Open [`NativeStudio/Studio.xcodeproj`](../NativeStudio/Studio.xcodeproj) in Xcode.

| Scheme | What runs |
| --- | --- |
| **Studio Local** | A local preview app containing the same native Studio UI. Select an iPhone/iPad simulator and Run. This test host has its own development-only app identity; it is not a new public product. |
| **Studio Messages Local** | The actual standalone Messages app and custom Messages extension, preserving `eu.armand.--bit-art` and `eu.armand.--bit-art.StickerPackExtension`. Run with Messages as the host, open a conversation, then choose 8 bit art from the app menu. |
| **Studio Messages Tests** | Simulator-only integration checks using Apple's fictional conversation fixture. Install the Messages build first. The test inserts a sticker in the composer and never taps Send. |

Debug/local configurations use version **1.4 (7)** for testing; build 7 was not uploaded. The dedicated TestFlight configuration uses the uploaded internal beta **1.4 (8)**. The separate original project remains the prepared **1.3 (6)** sticker-only build. Submitted **1.2 (5)** and its automatic-release setting were not changed.

Command-line shortcuts, with a simulator already booted:

```sh
./scripts/run-native-studio.sh preview
./scripts/run-native-studio.sh messages
```

Pass a simulator UUID as the second argument to choose a particular device. Both commands build unsigned Debug products, install only into that simulator and open it. There is no upload or App Store Connect call.

## The user flow

1. **Stickers:** browse all 67, search by feeling/category or `67`, and tap a heart to keep favorites. Included art is always free. In Messages, native sticker views support the platform's tap/hold interactions. The Details button offers insertion and, for true 16×16 art, **Make it yours**.
2. **Studio:** explains the editor and saved drawings. The optional **Studio Unlock** sheet states the one-time $1 test price, no subscription and no per-drawing/per-send charges. It is clearly labeled **Local test — no charge**.
3. **Continue where you started:** buying the test unlock takes a new drawing or requested remix straight to the editor. Selecting Studio in compact Messages expands the workspace first. Dismissing the offer leaves included stickers available.
4. **Draw:** use a true 16×16 canvas, palette, pencil, eraser, fill, undo/redo and optional precise cursor controls. The checkerboard is transparency, not exported artwork. The editor name and completed strokes autosave on this device. The phone canvas leaves room for the palette and primary actions.
5. **Drafts:** reopen, rename, duplicate, export or delete named drawings. Deletion is confirmed. A failed rename stays open with a visible retry message; failed writes retain in-memory work and never say Saved. Corrupt files are isolated for recovery and reported without blocking other drawings.
6. **Insert sticker:** adds a generated transparent PNG to the actual Messages composer. The person still taps Send. The local preview app shows a confirmation instead, because it has no conversation. Insertion never deletes a draft.
7. **Keep your work:** Restore Purchases recovers tools, not deleted drawings. Refund/revocation locks new editing but retains viewing/export of existing drafts. Local drawings do not sync to the website or other devices.

All 45 true 16×16 sources are exact-grid remix templates. Ten classics and twelve 50×50 revival designs remain sendable; they are not silently downsampled or flattened into templates. Both APNGs retain their original frames/timing. Wine stays archived outside all available collections.

## Two local purchase modes

**Default: simulated checkout.** No StoreKit product request or real payment is made. Tap Unlock to try the experience. Help → Local testing → Purchase test controls exposes cancellation, failure, pending approval, approval, refund and reset. Mock ownership is stored in a clearly separate local preference, never treated as a real purchase receipt. Reset/revoke does not delete drafts.

**Xcode StoreKit:** [`Config/Studio.storekit`](../Config/Studio.storekit) defines a local $1 non-consumable `eu.armand.--bit-art.studio.unlock`, with Family Sharing off. Both local schemes reference it. For interactive Apple payment-sheet testing, use a provided scheme with the local StoreKit configuration selected and add the Run environment variable `STUDIO_STOREKIT_TESTING=1`. Keep that configuration active; this is not sandbox/App Store testing. The adapter accepts only verified transactions identified as the Xcode environment.

The automated StoreKit test activates `SKTestSession` using the bundled configuration. It verifies product loading at $1, purchase, restoration after creating a new service, refund revocation and preservation of unrelated saved work. This does not establish the availability of an exact $1 production IAP price point.

Normal/non-Debug builds fail closed: checkout is disabled. Production purchase enablement is deliberately unfinished. No live product has been registered and no Apple account settings have been touched.

[Apple's local StoreKit testing guide](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode) describes how a local configuration replaces App Store data and produces test transactions without requiring a product in App Store Connect.

## Source map and regeneration

| Path | Responsibility |
| --- | --- |
| `NativeStudio/Core/` | Validated 256-cell document, drawing/history, atomic drafts/favorites and pixel-exact PNG renderer |
| `NativeStudio/Commerce/` | Local simulation, StoreKit 2 verification/updates/restore, pending/cancel/refund handling |
| `NativeStudio/Views/` | Shared native catalogue, offer, drafts, editor, accessibility and help |
| `NativeStudio/Integration/` | Bundled catalogue and real `MSMessagesAppViewController`/insertion; browsing-only fallback in media contexts |
| `NativeStudio/PreviewBridge/` | Optional loopback-only native screen/input viewer, compiled solely into a UI-test runner |
| `NativeStudio/LocalApp/` | Preview test host; UI-test storage is isolated from ordinary local drawings |
| `NativeStudio/Resources/` | All 67 byte-identical sticker files, 45 lossless templates and original icon |
| `NativeStudio/CoreTests/`, `CommerceTests/`, `UITests/`, `MessageTests/` | Model/resource, purchase, user-flow and Messages integration tests |
| `NativeStudio/project.yml` | XcodeGen source for the committed local project and shared schemes |
| `scripts/catalog-source.py` | Shared authoritative catalogue assembly, including ten classics |

Regenerate bundled art after changing the collection:

```sh
python3 scripts/build-native-catalog.py
python3 scripts/verify-native-studio.py
```

Use the Pillow version in `requirements-art.txt`. Normal Xcode builds use committed resources and need no Python. To regenerate the Xcode project after adding source files, use XcodeGen 2.46.0 or compatible:

```sh
xcodegen generate --spec NativeStudio/project.yml
```

## Verification and remaining release work

Verification logs and `.xcresult` bundles live under ignored `build/`. Review screenshots are under `docs/previews/native-studio/`; these are local test UI, not submitted App Store screenshots. The exact checks and limits are recorded in [verification notes](verification.md).

Run all local model/StoreKit/preview-UI tests:

```sh
./scripts/test-native-studio.sh SIMULATOR_UUID
```

Tests use a dedicated UI-test draft directory/preferences so repeated runs do not erase ordinary preview drawings. The actual Messages integration tests use the simulator fixture. Do not run those against a personal conversation.

Remaining before any production release: owner authorization to proceed after the current review; real-device/TestFlight and broader system-surface/accessibility testing; production StoreKit enablement; actual IAP price-point verification, agreements and product setup; updated native screenshots, privacy/support review; and app+first-IAP submission together. These steps are intentionally deferred. Do not infer permission to submit merely because the local tests pass or the earlier version is approved.

Support remains **seltzer.wisdom7h@icloud.com**. The [implementation/release handoff](native-studio-implementation-plan.md) remains the full product contract, with this document describing what can be tested now.
