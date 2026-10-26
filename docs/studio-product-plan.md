# Sticker Studio product plan

Updated October 26, 2026. The owner has chosen the future product direction: **native Studio inside Messages, on the existing 8 bit art listing, with an optional one-time US$1 Studio Unlock**. This is a documented plan; the native editor and purchase code have not been built.

**Start future implementation with [the native Studio implementation and release handoff](native-studio-implementation-plan.md).** It defines feature access, screen behavior, source layout, catalogue migration, the 16×16 model, local drafts, StoreKit state handling, tests and release gates. [Monetization decisions](monetization-options.md) record the price target and unresolved configuration choices.

## Product decision

| Part | Agreed direction |
| --- | --- |
| App | Same listing: Apple ID `1366485724`, host `eu.armand.--bit-art`, extension `eu.armand.--bit-art.StickerPackExtension` |
| Where Studio opens | A custom standalone iMessage app inside Messages, compact for browsing and expanded for editing |
| Included free | Included stickers, categories, search, favorites, ordinary sticker sending/placement |
| Optional paid tools | Native 16×16 editor, exact-grid remix templates, multiple named local drafts, custom sticker creation/insertion and PNG export |
| Purchase | One permanent non-consumable **Studio Unlock**, intended USA base price **US$1.00**; localized prices from Apple; restore supported |
| Data | Device-local drafts/favorites, no developer account or backend; restoring purchases does not restore deleted local drawings |
| Hosting | No new hosting for native Studio. Existing support/privacy pages remain on GitHub Pages. |

All included catalogue art remains available without buying Studio. There is no per-drawing or per-send charge and no subscription. Exact $1.00 **IAP** price-point availability must be checked when the product is configured; the earlier $1.00 app-download price point does not establish it. Family Sharing remains off/undecided pending an explicit owner choice because enabling it is irreversible.

Apple allows a standalone sticker pack to become a custom standalone iMessage app on the **same record**. A full home-screen app requires a **new app record** under its app-type rules. See [Apple's app-type rules](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-imessage-app-information/) and [iMessage purchase support](https://developer.apple.com/imessage/).

## Existing releases and prototypes

- **Submitted 1.2 (5):** forty-six stickers, no native editor or StoreKit code. Last verified October 26, 2026 as Waiting for Review with automatic release after approval and a published Data Not Collected label. Preserve `v1.2-build5-submitted`, its signed archive, [metadata snapshot](../release/1.2-build5-metadata.json), screenshot manifest and [release record](../release/release-status.json). Recheck live status when resuming.
- **Development 1.3 (6):** sixty stickers, including fourteen more memes and four 67 designs. Unsigned simulator/device builds and art/browser checks passed. Not uploaded/submitted. It can ship as an art update before Studio; the likely separate Studio release would then be 1.4, with version/build confirmed later.
- **Browser Studio:** `http://127.0.0.1:8787/prototype/`, served locally by Python. It is a reference prototype, not bundled native functionality or a public website. Its editor currently uses 32×32 cells and stores one draft in browser localStorage. Native Studio deliberately uses 16×16 / 256 cells and multiple saved documents. Browser data does not automatically migrate.

The full included catalogue is built from ten classics and fifty generated designs; `art/manifest.json` contains only the fifty generated entries. The native migration must include all sixty. Thirty-eight sources are true 16×16 and eligible for exact-grid remixing; do not silently downsample legacy / 50×50 art or flatten animations.

## Website and scope

The existing [app page](https://mim-armand.github.io/8bit-stickers/), [support page](https://mim-armand.github.io/8bit-stickers/support/) and [privacy policy](https://mim-armand.github.io/8bit-stickers/privacy/) are hosted on **GitHub Pages**, from the repository's `gh-pages` branch. The last recorded deployment is `30355ecd03d7b135b002f614803367d73eb3c805`. Support email: **seltzer.wisdom7h@icloud.com**.

The interactive web Studio is not deployed there. A future static `/studio/` route is optional and separate; native editing does not depend on it. If later publishing the web editor, deploy an intentional static output rather than the whole local repository server. A web/native purchase bridge, cloud drafts and a normal home-screen app are outside the first Studio release.

## Sequence for a future iteration

1. Read the [implementation handoff](native-studio-implementation-plan.md) and current Git/App Store status. Keep submitted 1.2 and development 1.3 separate.
2. Prove conversion to a custom standalone Messages extension, native insertion and StoreKit purchase presentation on a device while preserving identity.
3. Implement the free native catalogue/search/favorites, then the 256-cell editor, atomic multi-draft storage and PNG insertion.
4. Add the permanent StoreKit unlock and purchase/restore/refund/offline behavior. Validate the exact IAP price point; retain all drafts on entitlement loss.
5. Pass the specified model/UI/StoreKit/device tests, prepare actual native screenshots and revised support/privacy copy, and submit the first IAP with the new app version when release is authorized.

No app price, IAP product, Apple submission, public website or binary was changed by this planning work. The implementation milestones and acceptance criteria are the work queue; this summary should not be interpreted as a completed feature list.
