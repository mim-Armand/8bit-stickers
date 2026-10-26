# Recovery and release roadmap

Investigation date: October 26, 2026.

## What we recovered

The project was already on GitHub: [mim-Armand/8bit-stickers](https://github.com/mim-Armand/8bit-stickers). We recovered its history, Xcode project, **11 original sticker PNGs**, sticker asset catalogs and icon assets from [`816eba1`](https://github.com/mim-Armand/8bit-stickers/commit/816eba1). The local checkout keeps that history and the original GitHub remote.

This is an **iMessage sticker pack**, rather than a drawing app. The [Apple listing](https://apps.apple.com/us/app/8-bit-art/id1366485724) and [Apple lookup response](https://itunes.apple.com/lookup?id=1366485724&country=us) identify the published app as version **1.1**, released April 21, 2018. The recovered source declares **1.2, build 3**. We have recovered a real source revision, but cannot establish that it is exactly the revision used for the published 1.1 binary.

| Identity | Recovered value |
| --- | --- |
| Existing published app | **8 bit art**, Apple ID **1366485724** |
| Main bundle identifier | `eu.armand.--bit-art` |
| Sticker extension identifier | `eu.armand.--bit-art.StickerPackExtension` |
| Development team in recovered project | `7N3Y4QZT3Z` |
| Current development collection | **1.3 / 6**, 60 stickers prepared for a later update |
| Submitted version | **1.2 / 5**, 46 shipping stickers, frozen at `v1.2-build5-submitted` |

The two consecutive hyphens in the bundle identifier are intentional. The screenshot also contains **8-bit art**, Apple ID **1366403490**, in Prepare for Submission. That is a separate record; uploading to it would not update the published app.

The repository's older commit message says a sticker was removed after an App Review issue. We preserve the recovered head's 11 stickers and do not restore deleted historical artwork. Review the included legacy designs and any relevant review correspondence before submission.

## The two working MVPs

**Submitted native update MVP — version 1.2 (5).** The standalone sticker pack contains 46 shipping stickers: 10 recovered classics plus 36 new pixel-art designs, including two APNG animations. All eleven recovered PNGs remain preserved; wine is retained under `art/recovered/wine_01.sticker/` and excluded from the shipping catalog at the owner's request. The latest 24 are cute characters and meme reactions drawn on a true 16×16 grid, with simple shapes, dark outlines and chunky pixels closer to the original collection. Preserve the existing app and extension identifiers, modernize project settings, share the Xcode scheme, and automate asset validation and simulator builds. This is the shortest route to an update that existing users can install.

**Development art expansion — version 1.3 (6).** The forthcoming collection has 60 stickers: ten classics plus fifty new designs. Fourteen additional meme-inspired compositions include Absolute cinema, Let me cook, Popcorn mode, Locked in, Tiny violin, No thoughts, Aura +1, Keyboard cat, Dramatic cat and NPC mode, plus the four 67 designs Six seven!, Six-seven hands, Number 67 and Certified 67 cat. The tiny collection now has 38 true 16×16 sources: twelve cute and twenty-six meme designs. Each uses dark outlines and at most six opaque colors, enlarged exactly 18× to 288×288 with six transparent pixels of padding on each side for the 300×300 native PNG. No antialiasing is used. The editable sources live in `art/meme-reactions-sprites.json`, `art/meme-animals-sprites.json` and `art/six-seven-sprites.json`; review the new set on `docs/previews/meme-expansion-board.png`. This source expansion changes neither the submitted build 5 binary nor its App Review submission. It adds no native Studio or in-app purchase code, and does not establish a completed build 6 submission or device test.

**Local Studio MVP — a product exploration.** A browser interface presents categories, search, favorites, a conversation preview, PNG export and a basic pixel editor. It makes the art direction and possible future browsing/editing experience tangible. This prototype runs locally; it is not functionality shipped inside the native 1.2 sticker pack. Browser favorites and drawings stay on that browser/device. A preview conversation is illustrative and does not send messages.

The new art is designed around familiar conversation needs: affection, celebration, encouragement, cozy moments and playful reactions. The tiny collection adds cute animals and food characters alongside expressive meme faces, loading, stonks and touch-grass reactions. The 16×16 source resolution is preserved through integer nearest-neighbor scaling into the 300×300 native assets; the larger export does not add detail. Keep the source definitions and generation tools alongside the exported PNGs so a color or shape change can be reproduced. Use the supplied contact sheet to review the collection together, then test individual stickers at their real Messages size against light and dark bubbles.

Apple's [sticker specifications](https://developer.apple.com/documentation/messages/adding-your-sticker-packs-to-messages) require each file to be below 500 KB. Its @3x sticker sizes are 300×300, 408×408 and 618×618. Transparent PNGs and integer nearest-neighbor scaling suit this art style. Animated formats are also supported.

## App Review and release

The submitted update remains **1.2 (5)**, frozen at `v1.2-build5-submitted`, with a clean signed archive/export and wine absent from the simulator/archive/export products. Apple validation/upload passed without errors and with two expected hidden-app Mac/visionOS compatibility warnings. Build `ecc379bc-4471-489b-887b-826ec30d9c6b` processed as `VALID` and remains selected. The preceding build 4 passed Apple validation/upload and processed as `VALID`, but contains wine and is not the intended release. Version `7c6caa34-4ee8-4423-87d9-e4acc09b1b40` is **Waiting for Review** with **automatic release after approval** selected.

Revised native-only listing copy, support/privacy URLs, reviewer notes and age-rating answers were staged and read back. Omitting the wine sticker and setting alcohol references to `NONE` returns API age rating `FOUR_PLUS` without an override. The [support](https://mim-armand.github.io/8bit-stickers/support/) and [privacy](https://mim-armand.github.io/8bit-stickers/privacy/) pages are live on GitHub Pages, with HTTP 200 responses and HTTPS enforcement verified. The current published website describes the 46-sticker collection; the interactive Studio is not part of that public deployment.

The owner's publication and submission instructions were completed October 26, 2026:

1. **App Privacy published.** App Store Connect shows the **Data Not Collected** label as published. Evidence is ignored `build/submission/privacy-published.jpg`. The live public policy URL and the privacy label are separate disclosures. [Privacy disclosure guidance](https://developer.apple.com/app-store/app-privacy-details/).
2. **App Review submission created.** Review submission `d6780537-3c51-43b3-97d9-67f900dfc768` was submitted at `2026-10-26T20:01:02.003Z` / **3:01 PM CDT**. The submission and version both report `WAITING_FOR_REVIEW`, with build 5 selected. Final evidence is ignored `build/submission/review-submitted.json` and `final-readback.json`.
3. **Automatic release selected.** The saved release type is `AFTER_APPROVAL`; Apple will automatically release the update after approval. Six genuine native screenshots have twelve `COMPLETE` placements across App Store/iMessage iPhone/iPad sets; old 2018 images were removed only from the editable draft. Approval and public release remain pending.

An optional physical-device/TestFlight pass can still check sending, peel/place, animation playback, light/dark use and installation over the live version. The native 46-sticker picker rendered on iPhone and iPad simulators; these device checks are recommendations, not claimed completed tests. The published app supports iOS 10+, while this update requires iOS 15+.

The [release checklist](release-checklist.md) records completed and outstanding steps. Existing identity is preserved as required by [Apple's app information rules](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information); the update uses the [existing record's version workflow](https://developer.apple.com/help/app-store-connect/update-your-app/create-a-new-version).

## Enhancements after the recovery update

| Increment | Useful outcome | Scope |
| --- | --- | --- |
| Custom native Messages browser | Find reactions quickly | Categories, search, favorites and accessible sticker descriptions using the [Messages framework](https://developer.apple.com/documentation/messages/). |
| More animation | More expressive replies | Build on the included heart pulse and robot blink with star twinkles and seasonal characters, with restrained timing and file-size checks. |
| New themes | A distinctive growing library | Cozy desk, space garden, celebration, Persian-inspired seasonal motifs and nature; prioritize original artwork. |
| Localization | Broader everyday use | Localize listing, category names and descriptions; prefer art that works without embedded English text. |
| Native Studio inside Messages | Create and insert personal stickers | Extend the existing app into a custom standalone iMessage app with local drafts and a small pixel editor. |
| Optional home-screen Studio | A larger creative workspace | Requires a separate app record and app identity rather than conversion of this existing standalone listing. |

Apple permits standalone sticker-pack ↔ custom standalone iMessage updates in the same record, but requires a new app to change standalone ↔ extension-within-iOS-app. [Apple's explicit app-type rule](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-imessage-app-information). The recommended continuation is Studio **inside Messages**; a home-screen app is a separate product decision. See the [Studio product plan](studio-product-plan.md) for that distinction and optional web hosting.

## Keep it recoverable

- Commit source, original artwork, editable art definitions, generated assets, scripts and release notes to the existing GitHub repository. Keep signing keys, provisioning secrets, personal Xcode state and build output out of Git.
- Push small reviewed changes and run the repository checks in GitHub Actions. Tag the exact source commit for each submitted build, as with `v1.2-build5-submitted`, and record the App Store version, build number and validation outcome in its release notes. Metadata-only submission records may follow in later commits without changing the uploaded binary.
- Retain signed archives and an encrypted signing-key backup separately from the public repository. Keep a periodic independent repository/artwork export in a second location such as an external drive or private cloud backup. GitHub plus an independent export gives recovery options if either account or local storage is lost.
- Preserve the recovered history. Do not overwrite it with a new unrelated repository or regenerate art without keeping the editable source.
