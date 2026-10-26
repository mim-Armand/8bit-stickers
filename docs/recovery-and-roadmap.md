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
| Proposed next version/build | **1.2 / 4**, subject to existing uploaded-build history |

The two consecutive hyphens in the bundle identifier are intentional. The screenshot also contains **8-bit art**, Apple ID **1366403490**, in Prepare for Submission. That is a separate record; uploading to it would not update the published app.

The repository's older commit message says a sticker was removed after an App Review issue. We preserve the recovered head's 11 stickers and do not restore deleted historical artwork. Review the included legacy designs and any relevant review correspondence before submission.

## The two working MVPs

**Native update MVP — version 1.2.** Keep the standalone sticker pack experience, with 47 stickers: the 11 recovered stickers plus 36 new pixel-art designs, including two APNG animations. The latest 24 are cute characters and meme reactions drawn on a true 16×16 grid, with simple shapes, dark outlines and chunky pixels closer to the original collection. Preserve the existing app and extension identifiers, modernize project settings, share the Xcode scheme, and automate asset validation and simulator builds. This is the shortest route to an update that existing users can install.

**Local Studio MVP — a product exploration.** A browser interface presents categories, search, favorites, a conversation preview, PNG export and a basic pixel editor. It makes the art direction and possible future browsing/editing experience tangible. This prototype runs locally; it is not functionality shipped inside the native 1.2 sticker pack. Browser favorites and drawings stay on that browser/device. A preview conversation is illustrative and does not send messages.

The new art is designed around familiar conversation needs: affection, celebration, encouragement, cozy moments and playful reactions. The tiny collection adds cute animals and food characters alongside expressive meme faces, loading, stonks and touch-grass reactions. The 16×16 source resolution is preserved through integer nearest-neighbor scaling into the 300×300 native assets; the larger export does not add detail. Keep the source definitions and generation tools alongside the exported PNGs so a color or shape change can be reproduced. Use the supplied contact sheet to review the collection together, then test individual stickers at their real Messages size against light and dark bubbles.

Apple's [sticker specifications](https://developer.apple.com/documentation/messages/adding-your-sticker-packs-to-messages) require each file to be below 500 KB. Its @3x sticker sizes are 300×300, 408×408 and 618×618. Transparent PNGs and integer nearest-neighbor scaling suit this art style. Animated formats are also supported.

## What is needed before release

1. **Confirm account identity and build availability.** Open App Store Connect → 8 bit art → App Information. Verify Apple ID 1366485724 and the exact bundle ID. In Xcode, confirm access to the owning team and both identifiers. Check whether 1.2/build 4 has ever been uploaded; increase the version/build if necessary. [Apple requires the same bundle ID](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information) and an [incremental new version in the existing record](https://developer.apple.com/help/app-store-connect/update-your-app/create-a-new-version).
2. **Review the supported OS range.** The published app supports iOS 10+. The modernization currently targets iOS 15+. Building with a current SDK and choosing the minimum supported OS are separate decisions. Decide whether to retain this iOS 15 minimum after testing; users on older systems would not receive this update.
3. **Test on iPhone and iPad in Messages.** Verify installation over the old app, the existing pack's identity, every sticker, tap-to-send and peel/place behavior, transparency, compact/expanded layouts and light/dark appearance. A successful simulator build does not establish these release checks.
4. **Create and validate a signed archive.** Use the owning Apple Developer team. Lost original signing keys do not prevent an update: Apple says [recreating certificates does not affect the ability to update App Store apps](https://help.apple.com/xcode/mac/current/en.lproj/devd1432da9a.html). Use Xcode Organizer to validate and upload, then test the processed build through TestFlight. Current [upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/) list Xcode 26 or later for building iOS apps and extensions; recheck at submission time.
5. **Finish the product page.** Review new screenshots from actual Messages use, the art/content rights, current age-rating questions, support URL and privacy policy URL. The legacy wine sticker makes the alcohol-related age-rating question worth reviewing. The [privacy disclosure](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy) must accurately describe the app and any SDKs. Draft copy is in `docs/app-store-draft.md`; a public policy URL still needs hosting.
6. **Submit the completed 1.2 build for review.** Check outstanding agreements and any account-specific App Store Connect requirements. Confirm release timing after testing. No App Store submission or release is implied by this repository work.

## Enhancements after the recovery update

| Increment | Useful outcome | Scope |
| --- | --- | --- |
| Custom native Messages browser | Find reactions quickly | Categories, search, favorites and accessible sticker descriptions using the [Messages framework](https://developer.apple.com/documentation/messages/). |
| More animation | More expressive replies | Build on the included heart pulse and robot blink with star twinkles and seasonal characters, with restrained timing and file-size checks. |
| New themes | A distinctive growing library | Cozy desk, space garden, celebration, Persian-inspired seasonal motifs and nature; prioritize original artwork. |
| Localization | Broader everyday use | Localize listing, category names and descriptions; prefer art that works without embedded English text. |
| Optional companion editor | Create and export personal stickers | Promote the Studio experiment to native only after validating demand and export/import behavior. |

Adding a normal iOS companion app is a larger product change. Apple says iOS apps containing sticker extensions cannot select the **Stickers** category; [review the submission model](https://developer.apple.com/imessage/) before taking that route.

## Keep it recoverable

- Commit source, original artwork, editable art definitions, generated assets, scripts and release notes to the existing GitHub repository. Keep signing keys, provisioning secrets, personal Xcode state and build output out of Git.
- Push small reviewed changes and run the repository checks in GitHub Actions. Tag the exact source commit for each submitted build, for example `v1.2-build4`, and record the App Store version, build number and validation outcome in its release notes.
- Retain signed archives and an encrypted signing-key backup separately from the public repository. Keep a periodic independent repository/artwork export in a second location such as an external drive or private cloud backup. GitHub plus an independent export gives recovery options if either account or local storage is lost.
- Preserve the recovered history. Do not overwrite it with a new unrelated repository or regenerate art without keeping the editable source.
