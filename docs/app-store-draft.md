# App Store submission — 8 bit art 1.2

Updated October 26, 2026. Revised 46-sticker metadata was saved in App Store Connect and read back through the API. Authoritative copy is [`Config/AppStoreMetadata.json`](../Config/AppStoreMetadata.json). The submitted update is **1.2 (5)**; its clean signed archive/export passed Apple validation/upload with no errors and two expected platform warnings. Build 5 processed as `VALID` and remains selected. The predecessor build 4 was accepted but contains the omitted wine artwork and is not the intended release.

The version and review submission are **Waiting for Review**. The **Data Not Collected** App Privacy label is published. Release type **`AFTER_APPROVAL`** means Apple will automatically release the version after approval. The update has not yet been approved or publicly released.

## Release state

| Field | Verified value |
| --- | --- |
| Existing app | **8 bit art**, Apple ID **1366485724** |
| Host / extension IDs | `eu.armand.--bit-art` / `eu.armand.--bit-art.StickerPackExtension` |
| Submitted version / build | **1.2 / 5**, 46 stickers |
| App Store version ID | `7c6caa34-4ee8-4423-87d9-e4acc09b1b40` |
| Selected processed build | `ecc379bc-4471-489b-887b-826ec30d9c6b`, build 5, `VALID` |
| Review submission ID | `d6780537-3c51-43b3-97d9-67f900dfc768` |
| Submitted at | `2026-10-26T20:01:02.003Z` / October 26, 2026, 3:01 PM CDT |
| Version / review state | `WAITING_FOR_REVIEW` |
| Release option | `AFTER_APPROVAL` — automatically release after approval |
| App Privacy label | Published — Data Not Collected |
| Public support email | **seltzer.wisdom7h@icloud.com** |
| App page / marketing URL | [App page](https://mim-armand.github.io/8bit-stickers/) |
| Support URL | [Support](https://mim-armand.github.io/8bit-stickers/support/) |
| Privacy policy URL | [Privacy policy](https://mim-armand.github.io/8bit-stickers/privacy/) |
| Age-rating API result | `FOUR_PLUS`, alcohol references `NONE`, no override |

All eleven recovered original PNGs remain preserved in source; the wine original is archived at `art/recovered/wine_01.sticker/` and excluded from shipping assets at the owner's request. This version ships ten classics and thirty-six new designs.

The three public pages are live on GitHub Pages with HTTP 200 responses and HTTPS enforcement. The interactive Studio remains localhost only. The no-collected-data App Privacy label was published separately in App Store Connect. Six actual native screenshots have twelve placements across the App Store/iMessage iPhone/iPad wells. All are `COMPLETE`, with no errors; legacy 2018 images were removed only from the editable 1.2 draft, leaving published 1.1 untouched. Final evidence is ignored `build/submission/privacy-published.jpg`, `review-submitted.json` and `final-readback.json`.

## Listing copy

**Name:** 8 bit art

**Subtitle:** Pixel stickers, big feelings

**Promotional text:** Tiny pixel characters, cute animals, and very relatable reactions. Explore 46 retro stickers for Messages, including a pulsing heart and blinking robot.

**Description:**

Give your messages a little 8-bit love.

8 bit art brings 46 pixel-art stickers to Messages, including 10 classics and 36 fresh designs. Meet tiny cute animals, share a side-eye or a shocked reaction, and add some retro personality to everyday conversations.

Twenty-four cute characters and meme reactions use a chunky 16×16 pixel grid. A pulsing heart and blinking robot add a little movement. Tap a sticker to send it, or touch and hold to place it on a message or photo.

The sticker pack works offline. There are no accounts, ads, subscriptions, or developer analytics.

Open a conversation in Messages, tap the add/apps button, and open Stickers. Choose 8 bit art from your sticker apps. The exact steps vary by iOS version. This is a Messages sticker pack and does not have a separate home-screen editor.

Version 1.2 requires iOS or iPadOS 15 or later.

Questions or feedback? Contact seltzer.wisdom7h@icloud.com.

**Keywords:** pixel,retro,8bit,stickers,art,love,reactions,cute,meme,heart,cat,frog,boba

**What's New:**

8 bit art is back!

• 36 new pixel-art stickers, bringing the collection to 46.
• 24 chunky 16×16 cute characters and meme reactions.
• A pulsing heart and a blinking robot.
• Refreshed for modern iPhone and iPad versions.

Your 10 classic stickers are still included. Requires iOS or iPadOS 15 or later.

## Reviewer notes

Update to the existing standalone iMessage sticker pack, Apple ID 1366485724. The app and extension identifiers are preserved. The collection contains 46 stickers: 10 existing classics, 12 revival designs (including a pulsing heart and blinking robot), and 24 static cute/meme reactions drawn on a 16×16 source grid.

No login, purchase, account, server, or permissions are required. Open a conversation in Messages, open the apps/sticker picker, and select 8 bit art. Tap to send or touch and hold to place stickers. Exact picker labels vary with the OS version.

This is an iMessage-only app and has no home-screen editor. The web Sticker Studio in the GitHub source is a local prototype and is not included in this build. The public website contains app support and privacy pages only.

The sticker pack contains no tracking, advertising, analytics SDKs, or developer data collection. Version 1.2 requires iOS/iPadOS 15+.

The legacy wine-glass sticker is omitted from this release. Its source is archived in GitHub and is not included in the app asset catalog.

The existing App Review contact was preserved privately. Reviewer email/phone details are not copied into the public repository.

## Screenshots and disclosures

Native iPhone/iPad screenshots must show the actual 46-sticker pack in Messages with fictional conversation details and no phone numbers. Browser Studio previews and art contact sheets must not imply that editing/search/favorites ship in native 1.2.

After the wine sticker was omitted, alcohol references were changed to `NONE`. The API-derived rating is `FOUR_PLUS`, with no override or Made for Kids selection. Other capability declarations reflect the predefined pack: it has no own chat, user-content feed or editor; the host Messages app handles conversations.

The published App Privacy answer is **“No, we do not collect data from this app.”** The public policy is effective **October 26, 2026**, with source in `site/privacy/index.html`; it distinguishes offline app behavior, Apple services, voluntary support emails and GitHub Pages hosting logs.

See [release-checklist.md](release-checklist.md) for publication/submission evidence and optional physical-device/TestFlight checks. Submission and complete screenshot placements do not establish App Review approval or public release. Pricing is unchanged; possible future paid designs are described in [monetization-options.md](monetization-options.md).
