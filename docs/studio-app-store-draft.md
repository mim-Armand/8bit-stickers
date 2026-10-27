# Native Studio 1.4 — App Store copy and review handoff

This is the **prepared public release copy for 1.4 (10)**, not a submission receipt or approval. Public **1.2 (5) is approved and available**. Keep its metadata, release evidence and 46-sticker screenshots intact. The native Studio candidate is a separate version with 67 included stickers, new native screens and its first optional tools purchase.

The machine-readable source is [`Config/StudioAppStoreMetadata.json`](../Config/StudioAppStoreMetadata.json). It is separate from the sticker-only `Config/AppStoreMetadata.json`, which remains the historical 1.3 (6) development pack. New release helpers must intentionally load the Studio file; do not accidentally sync the sticker-only copy into this release.

## Identity and offer

| Field | Prepared value |
| --- | --- |
| App name | 8 bit art |
| App Store ID | `1366485724` |
| Host bundle | `eu.armand.--bit-art` |
| Extension bundle | `eu.armand.--bit-art.StickerPackExtension` |
| Candidate | 1.4 (10), subject to final processed-build validation |
| Subtitle | Pixel stickers. Make your own. |
| Included without Studio Unlock | 67 stickers, search, categories and favorites |
| Optional tools | 16×16 editor, 45 remix templates, multiple local drafts, custom sticker insertion and PNG export |
| Purchase | Studio Unlock, one permanent non-consumable |
| Product ID / Apple ID | `eu.armand.bitart.studio.unlock` / `6827336076` |
| USA price | Exactly US$1.00, verified from this IAP's own price point and saved schedule |
| Other storefronts | Apple's localized price, shown before purchase |
| Family Sharing | Off |
| Release preference | Automatic after approval (`AFTER_APPROVAL`), to be verified on this version |

There is no subscription, consumable credit, per-drawing charge or charge per sticker sent. The optional tools purchase does not change the app-download price. In copy, “included without Studio Unlock” refers to access after installing the app; it does not promise that downloading the app itself is free.

## Listing preview

**Promotional text**

> 67 stickers. Your next tiny masterpiece. Explore cute reactions, save favorites, and create your own with the optional one-time Studio Unlock inside Messages.

The full description in the JSON introduces the sticker collection, then explains the editor, local drafts and one-time purchase. It explicitly says the app opens **inside Messages**, has no separate home-screen editor, and lets the user choose when to send. It distinguishes device-local artwork from restoring the purchase and avoids promising cloud synchronization or recovery of deleted drawings.

**What's New**

> Meet Studio, right inside Messages.
>
> • Browse all 67 stickers, including cute reactions, meme-inspired animals, five 67 designs, and two animations.
> • Find the right reaction with search, categories, and favorites.
> • Optional Studio Unlock: create on a true 16×16 grid, remix 45 tiny templates, and keep multiple named drafts.
> • Draw with pencil, eraser, and fill. Undo, redo, duplicate, export a PNG, or insert your own sticker into Messages.
>
> Studio Unlock is a permanent one-time purchase: US$1.00 in the USA, with localized prices elsewhere. No subscription or per-sticker charge. Included stickers, search, and favorites remain usable without it.
>
> Drawings stay on your device. Export work you want to keep before deleting the app.

The JSON validates the usual limits: name/subtitle 30 characters, promotional text 170, keywords 100, description and What's New 4,000. Review notes remain below 4,000 characters. Recheck these after copy edits.

## Reviewer path

The JSON's `reviewNotes` gives the full reviewer instructions:

1. Open **Messages → a conversation → + / More → 8 bit art**. On older OS versions, use the Apps drawer. No app-specific account or developer test credentials are needed.
2. Browse/search/favorite the included catalogue. These features remain usable without the purchase. Verify a classic, tiny sticker and both APNG animations.
3. Open **Studio → Try Studio → Unlock Studio** using Apple's localized price. Cancellation leaves the included collection available. A requested drawing/remix resumes after verified ownership.
4. For a remix, open **Collection → sticker Details → Make it yours** on one of the 45 tiny templates. Legacy and larger designs are not silently downsampled into templates.
5. Draw, fill, undo/redo, rename, return to drafts/reopen, duplicate and export. **Insert sticker** places the PNG in the Messages composer; the user taps Send.
6. Use **Help → Restore Purchases** under the same purchase account. Restore recovers the tools, not deleted drawings or drawings on another device. Entitlement loss does not delete saved artwork or favorites.

App Review purchases use Apple's test environment. The public binary needs production StoreKit entitlement support as well; local mocks, free beta records and Xcode transactions cannot grant public paid ownership. Submit the **first IAP and this new app version together** when the actual review submission is authorized. The release copy is not evidence that those device transactions have passed.

## Support and privacy source

[`site/support/index.html`](../site/support/index.html) now covers the current 1.2 pack and **forthcoming 1.4 Studio**, including finding the Messages app, the one-time purchase, cancellation, drafts, export and Restore Purchases. [`site/privacy/index.html`](../site/privacy/index.html) adds device-local drafts/favorites, user-directed sharing and Apple-handled StoreKit verification/payment. Both keep the public email and existing URLs. These are source edits only; no site deployment was performed by this copy-preparation task.

- Marketing: https://mim-armand.github.io/8bit-stickers/
- Support: https://mim-armand.github.io/8bit-stickers/support/
- Privacy: https://mim-armand.github.io/8bit-stickers/privacy/
- Email: **seltzer.wisdom7h@icloud.com**

The home page still describes the existing public release and remains a separate source to review for release timing. Do not claim Studio is publicly available before approval and actual rollout.

## Privacy-label assessment

The current design keeps drawings, names, favorites and StoreKit entitlement checks on device and has no developer backend, analytics SDK or account system. On that basis, **Data Not Collected remains consistent with the implementation**; this is an assessment, not a new App Store Connect privacy publication. Apple's definition excludes data used only on device. Payment information entered through a payment service is not collected by the app when the developer cannot access it, and Apple's own collection is not the developer's disclosure responsibility. See [Apple's App Privacy guidance](https://developer.apple.com/app-store/app-privacy-details/). Reassess if a future change adds server receipts, telemetry, artwork upload or other off-device processing.

The privacy manifest is a separate requirement from the label. Native Studio uses `UserDefaults` for its own preferences. Apple's app-only usage reason is **`NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1`**; the release build should declare it in the manifest bundled with the Studio targets. The old sticker-only manifest currently has an empty required-reason list. See [Apple's required-reason API guidance](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype). This copy task did not modify the manifest or label.

## Remaining release checks

- Confirm the real public candidate's minimum OS, production purchase behavior and exact version/build before applying this copy. The draft currently says iOS/iPadOS 15+.
- Capture and inspect actual native iPhone/iPad screenshots for the new catalogue, editor and drafts. The IAP review screenshot should show the actual offer and localized one-time purchase information. Do not reuse old pack screenshots or browser prototypes as the native release UI.
- Re-evaluate age-rating feature answers for the new editor/custom-sticker workflow. The old sync helper's “predefined art” rationale does not fully describe Studio. Wine remains excluded; private artwork insertion through Messages should be assessed against Apple's current definitions rather than automatically marked as public user-generated content or chat.
- Check IAP metadata, availability, price readback, review image and association with the version. Keep Family Sharing off unless the owner chooses to enable it.
- Verify support/privacy pages after any separately authorized deployment, and make public availability wording match the actual release state.
- Record processed build, screenshot, IAP and version IDs in sanitized release evidence. No submission or approval should be inferred from these drafts.
