# Sticker Studio product plan

Updated October 26, 2026. The owner has chosen the future product direction: **native Studio inside Messages, on the existing 8 bit art listing, with an optional one-time US$1 Studio Unlock**. The native editor and drafts are implemented, and **1.4 (8) is available in internal TestFlight with free beta activation**; see the [TestFlight guide](studio-testflight.md). Local purchase flows remain covered by the [local testing guide](native-studio-local.md). The owner then chose real sandbox purchase testing: a draft product and exact US$1.00 price are configured, with a separate 1.4 (9) sandbox configuration; see the [sandbox guide](studio-sandbox.md). Public sale and release remain deferred.

**Start local testing with [the native Studio guide](native-studio-local.md); use [the implementation/release handoff](native-studio-implementation-plan.md) for the full contract and remaining release work.** It defines feature access, screen behavior, source layout, catalogue migration, the 16×16 model, local drafts, StoreKit state handling, tests and release gates. [Monetization decisions](monetization-options.md) record the price target and unresolved configuration choices.

## Product decision

| Part | Agreed direction |
| --- | --- |
| App | Same listing: Apple ID `1366485724`, host `eu.armand.--bit-art`, extension `eu.armand.--bit-art.StickerPackExtension` |
| Where Studio opens | A custom standalone iMessage app inside Messages, compact for browsing and expanded for editing |
| Included free | Included stickers, categories, search, favorites, ordinary sticker sending/placement |
| Optional paid tools | Native 16×16 editor, exact-grid remix templates, multiple named local drafts, custom sticker creation/insertion and PNG export |
| Purchase | One permanent non-consumable **Studio Unlock**, intended USA base price **US$1.00**; localized prices from Apple; restore supported |
| Data | Device-local drafts/favorites, no app-specific account or backend; restoring purchases does not restore deleted local drawings |
| Hosting | No new hosting for native Studio. Existing support/privacy pages remain on GitHub Pages. |

All included catalogue art remains available without buying Studio. There is no per-drawing or per-send charge and no subscription. The exact US$1.00 **IAP** point is now verified and its schedule saved for draft product `eu.armand.bitart.studio.unlock` / `6827336076`. This is separate from the earlier app-download price query. Family Sharing remains off/undecided pending an explicit owner choice because enabling it is irreversible.

Apple allows a standalone sticker pack to become a custom standalone iMessage app on the **same record**. A full home-screen app requires a **new app record** under its app-type rules. See [Apple's app-type rules](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-imessage-app-information/) and [iMessage purchase support](https://developer.apple.com/imessage/).

## Existing releases and prototypes

- **Submitted 1.2 (5):** forty-six stickers, no native editor or StoreKit code. Last verified October 26, 2026 as Waiting for Review with automatic release after approval and a published Data Not Collected label. Preserve `v1.2-build5-submitted`, its signed archive, [metadata snapshot](../release/1.2-build5-metadata.json), screenshot manifest and [release record](../release/release-status.json). Recheck live status when resuming.
- **Development 1.3 (6):** sixty-seven stickers, including twenty-one more memes since submitted 1.2 (5) and five 67 designs. The preceding sixty-sticker source passed unsigned simulator/device builds and art/browser checks; verification for the latest seven is recorded separately in [verification notes](verification.md). Not uploaded/submitted. It can ship as an art update before Studio; the likely separate Studio release would then be 1.4, with version/build confirmed later.
- **Local native Studio 1.4 (7):** `NativeStudio/Studio.xcodeproj` contains the custom standalone Messages extension and a preview test host. Free browsing/favorites, 16×16 editing, multi-drafts and local purchase/restore/refund flows are implemented. This original local stage required no App Store product or submission; the later sandbox setup is described below.
- **Internal TestFlight Studio 1.4 (8):** uploaded, processed `VALID`, `INTERNAL_ONLY` and `IN_BETA_TESTING`; the account holder is invited. All 67 stickers and native tools are available with free beta activation. This does not create ownership of the planned paid unlock. See [beta status and install steps](studio-testflight.md).
- **Sandbox Studio 1.4 (9):** dedicated release-based `TestFlightSandbox` configuration uses actual StoreKit lookup/purchase/restore, accepts verified sandbox transactions only and ignores free-beta/mock ownership. The draft product is registered at exact US$1.00; actual device purchase/restore remains a tester check. See the [sandbox guide](studio-sandbox.md) for current upload/distribution state.
- **Browser Studio:** `http://127.0.0.1:8787/prototype/`, served locally by Python. It is a reference prototype, not bundled native functionality or a public website. Its editor currently uses 32×32 cells and stores one draft in browser localStorage. Native Studio deliberately uses 16×16 / 256 cells and multiple saved documents. Browser data does not automatically migrate.

The full included catalogue is built from ten classics and fifty-seven generated designs; `art/manifest.json` contains only the fifty-seven generated entries. The native migration must include all sixty-seven. Forty-five sources are true 16×16 and eligible for exact-grid remixing; do not silently downsample legacy / 50×50 art or flatten animations.

## Website and scope

The existing [app page](https://mim-armand.github.io/8bit-stickers/), [support page](https://mim-armand.github.io/8bit-stickers/support/) and [privacy policy](https://mim-armand.github.io/8bit-stickers/privacy/) are hosted on **GitHub Pages**, from the repository's `gh-pages` branch. The last recorded deployment is `30355ecd03d7b135b002f614803367d73eb3c805`. Support email: **seltzer.wisdom7h@icloud.com**.

The interactive web Studio is not deployed there. A future static `/studio/` route is optional and separate; native editing does not depend on it. If later publishing the web editor, deploy an intentional static output rather than the whole local repository server. A web/native purchase bridge, cloud drafts and a normal home-screen app are outside the first Studio release.

## Production sequence after local testing

1. Read the [implementation handoff](native-studio-implementation-plan.md) and current Git/App Store status. Keep submitted 1.2 and development 1.3 separate.
2. Prove conversion to a custom standalone Messages extension, native insertion and StoreKit purchase presentation on a device while preserving identity.
3. Implement the free native catalogue/search/favorites, then the 256-cell editor, atomic multi-draft storage and PNG insertion.
4. Add the permanent StoreKit unlock and purchase/restore/refund/offline behavior. Retain the registered product and verified exact IAP price schedule; complete actual sandbox/device checks and retain all drafts on entitlement loss.
5. Pass the specified model/UI/StoreKit/device tests, prepare actual native screenshots and revised support/privacy copy, and submit the first IAP with the new app version when release is authorized.

Local native code now exists; its current verification and limitations are recorded in [the testing guide](native-studio-local.md) and [verification notes](verification.md). The app-download price, public App Review submission and public hosting remain unchanged. A draft IAP and its US$1.00 schedule now support authorized sandbox testing; public-sale availability remains unset. The remaining production milestones do not authorize a release.
