# Sticker Studio product plan

Updated October 26, 2026. This separates the submitted release from future product choices.

## What is shipping in 1.2

The existing **8 bit art** app, Apple ID **1366485724**, remains a standalone iMessage sticker pack with 46 stickers. Version **1.2 (5)** has a clean signed archive/export and passed Apple validation/upload, processed as `VALID` and replaced build 4 as the selected build. The wine-glass sticker is retained in recovered source but omitted from shipping assets. It was submitted for App Review on October 26, 2026, at **3:01 PM CDT**, and is **Waiting for Review**, with **automatic release after approval** selected. The **Data Not Collected** privacy label is published. The update has not yet been approved or publicly released. It preserves `eu.armand.--bit-art` and `eu.armand.--bit-art.StickerPackExtension`. There is no home-screen editor in this release. The browser Studio is not bundled, and its screenshots must not be presented as shipped iOS functionality.

The current Studio at `http://127.0.0.1:8787/prototype/` is served by a Python process on this Mac. It has no public deployment. Its drawings and favorites live in that browser's local storage; stopping the server makes the local URL unavailable. Keeping its source on GitHub does not itself publish a website.

## Which native Studio can use the existing listing?

Apple makes a distinction that affects the plan: a standalone sticker pack can become a **standalone custom iMessage app** through an update to the same App Store record. Changing a standalone app into an extension inside a normal iOS app requires a **new app**, as does the reverse. Therefore a home-screen Studio cannot be promised as an ordinary update to this existing listing. [Apple: change iMessage app type](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-imessage-app-information).

| Option | Where it opens | Existing listing? | Hosting |
| --- | --- | --- | --- |
| Current 1.2 sticker pack | Messages and supported system sticker surfaces | Yes | No app backend needed |
| Future native Studio inside Messages | Custom compact/expanded Messages interface | Yes, as a standalone iMessage app update | No backend needed for local editing |
| Full home-screen Studio app | A normal iPhone/iPad app | New app record and app identity required | No backend needed for local editing |
| Optional web Studio | Safari, Chrome and other browsers | Separate website, not an App Store app | Static web host such as GitHub Pages |

The recommended continuation of the existing app is **Studio inside Messages**: first add categories, search and favorites, then a 16×16 editor with saved drafts and a button to insert the resulting sticker into the active conversation. That is a native implementation using the [Messages framework](https://developer.apple.com/documentation/messages), including `MSMessagesAppViewController`, `MSStickerBrowserViewController` and `MSConversation`. It can reuse the repository's editable pixel data and generated artwork; the current browser UI is a design and interaction reference.

The native work still needs its own implementation, sandbox persistence, accessibility, compact/expanded layout tests and real-device sending tests. Browser drafts will not automatically appear in the native app. Export/import of PNG files is the initial bridge; account-based synchronization would be a separate feature with a backend and updated privacy disclosures.

If a full home-screen creative app becomes the priority, treat it as a separate product decision and new app submission. An iOS app can include its own Messages extension; its App Store categories and description then also apply to that extension, and the containing app cannot use the Stickers category. [Apple's app and extension distribution models](https://developer.apple.com/imessage/). A containing app and its extension can share selected local files/preferences through an explicitly configured [App Group](https://developer.apple.com/documentation/xcode/configuring-app-groups); that entitlement is not configured for this release.

## What happens to the website?

The web Studio is useful as an optional public try-it-out page and desktop pixel editor. It is not needed to make the native stickers work. A release support site can be deployed independently of the full Studio.

**Hosting now in use:** GitHub Pages from the existing public `mim-Armand/8bit-stickers` repository hosts the [app page](https://mim-armand.github.io/8bit-stickers/), [support page](https://mim-armand.github.io/8bit-stickers/support/) and [privacy policy](https://mim-armand.github.io/8bit-stickers/privacy/). All three were verified with HTTP 200 responses, a completed Pages build and HTTPS enforcement. The deployed `gh-pages` commit is `30355ecd03d7b135b002f614803367d73eb3c805`.

**The interactive Studio is not on that public site.** It remains at the local `127.0.0.1` URL. If a public web Studio is wanted later, the same Pages host can serve an intentional static Studio output, for example under a future `/studio/` route. That route is a proposal, not a live destination. Pages supports static HTML, CSS, JavaScript and PNG files without an application backend; a custom domain is optional. [GitHub Pages hosting model](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages).

For a public Studio, publish an intentional static output folder rather than the whole local repository server. Keep scripts, build archives and credentials out of the website artifact. Add a website privacy notice that distinguishes local browser drafts from hosting logs; GitHub Pages records visitor IP addresses for security. The native sticker pack's no-data-collection disclosure remains a separate statement about the native binary.

## Sequence

1. The 46-sticker 1.2 (5) update is submitted: signing, upload, selected `VALID` build, six native screenshots/twelve complete placements, revised metadata, API age rating `FOUR_PLUS` and live support/privacy URLs are verified. The no-collected-data privacy label is published. A physical-device/TestFlight pass is still available as an optional final check, not a claimed completed test.
2. App Review is pending under submission `d6780537-3c51-43b3-97d9-67f900dfc768`. Release type `AFTER_APPROVAL` will automatically publish the update after approval.
3. Build Studio inside Messages as the next update to the existing app, beginning with browsing and favorites.
4. Optionally publish the web demo on GitHub Pages; decide separately whether a full home-screen Studio justifies a new app.

No new home-screen app, sync service or public Studio deployment is implied by submitting version 1.2. Pricing is unchanged; see [monetization options](monetization-options.md) for a paid pack or future Studio purchase.
