# Studio purchase correction — 1.4.1 (11)

On October 31, 2026, an App Store customer reported **Price unavailable** on the Studio Unlock offer. At diagnosis, a fresh App Store Connect readback confirmed public **1.4 (10) is Ready for Distribution**, but Studio Unlock **6827336076 / eu.armand.bitart.studio.unlock** was **READY_TO_SUBMIT**. Its sole metadata version **45b42e0b-bc8a-4835-8bc8-4d766e48bda1** was **PREPARE_FOR_SUBMISSION**. The completed October 27 review **62051c1f-8195-49b2-8dae-fc6083e2ce41** contains only one approved app item.

The screenshot's precise message comes from a successful `Product.products(for:)` request with no matching product, rather than an exception or checkout failure. The code requests the correct non-consumable identifier. Apple has not approved this product for production sale. Its ongoing exact **US$1.00** price, the approved **175 territories**, automatic new-territory availability **off**, and Family Sharing **off** all match the intended configuration.

[Apple requires the first non-consumable to be submitted with a new app version](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/). [Ready to Submit is not Approved](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-statuses/). Price lookup and production checkout cannot be considered fixed until Apple approves the purchase and it becomes available in the production catalog. Local StoreKit success does not establish that.

## Corrective candidate

**1.4.1 (11)** retains both published bundle IDs and the existing purchase. Do not create another purchase, change the $1.00 price, or delete user artwork. It includes:

- Consistent cream/ink styling for Studio-owned sheets, correcting white headings and invisible feature names when Messages uses Dark Mode.
- A retry that dismisses its own stale price error after product metadata recovers, while preserving unresolved ownership or checkout notices.
- Protection against overlapping product-loading operations.
- The same 67 included stickers, 45 remix templates, entitlement verification and local draft format.

`Config/StudioAppStoreMetadata.json` and the generated AppStore configuration now describe this candidate. The original 1.4 metadata is preserved in `release/studio-1.4/1.4-build10-metadata.json`; tag `v1.4-build10-candidate` preserves its code. The old release-preparation JSON remains a historical preparation snapshot, not current Apple status.

The new Apple draft is **6cd58d90-1728-495e-a02d-2b5fc571a519**, with en-US localization **25f0993f-cae4-48be-8b3a-f87677a6ce21**. It inherits all 16 native screenshot placements, each **COMPLETE**. Those screenshots still represent the included artwork and Studio features. Reviewer notes explicitly describe the missing first-IAP review and request review of the existing product with this correction. Automatic release remains **AFTER_APPROVAL**.

Build **63c7404d-e3b0-4136-8ae2-6a6bb90d652e** is now **VALID / APP_STORE_ELIGIBLE**, selected in 1.4.1, and **IN_BETA_TESTING** in the existing internal group. Signed candidate source is commit **bb9acf8c24a3cf32f8a98620030213eaf4dc716c**, tagged **v1.4.1-build11-candidate**. [GitHub PR #8](https://github.com/mim-Armand/8bit-stickers/pull/8) records the correction.

The owner explicitly approved **“Submit both; release automatically after approval.”** Combined submission **4ab04eda-8610-4e9d-8552-8617b6a3f7e2** was sent at **2026-10-31T07:42:46.946Z** (**2:42 AM CDT, October 31**). Readback verifies exactly two items in the same submission: app version **6cd58d90-1728-495e-a02d-2b5fc571a519** and IAP metadata version **45b42e0b-bc8a-4835-8bc8-4d766e48bda1**. The submission, app version, IAP product and IAP metadata version all report **WAITING_FOR_REVIEW**. Release remains **AFTER_APPROVAL**. Do not submit either item again or cancel this active review. Tag **v1.4.1-build11-submitted** preserves the exact candidate source.

## Preparation and release controls

`scripts/prepare-studio-purchase-fix.mjs` is a dry run by default. `--apply` creates/updates this exact editable draft and selects processed build 11. `--apply --stage-review` requires a selected **VALID / APP_STORE_ELIGIBLE** build, all inherited screenshots, the completed IAP review image, the exact $1.00 price and the recorded territory approval. It then attaches **both** the app version and existing first-IAP metadata version to **one unsubmitted review draft**. It rejects unrelated review items. It deliberately contains no review-submission operation.

```sh
node scripts/prepare-studio-purchase-fix.mjs
./scripts/archive-studio-appstore.sh
# After Apple validation/upload and build processing:
node scripts/prepare-studio-purchase-fix.mjs --apply --stage-review
```

The signed output is `build/studio-release/1.4.1-11/`. Private Apple readbacks and test logs stay under ignored `build/purchase-investigation/` and `build/studio-price-fix-*`. Sanitized final state and verification are recorded in `release/studio-1.4.1/preparation-status.json` when preparation finishes.

Before this authorized submission, the items were read back using `include=appStoreVersion,inAppPurchaseVersion`, requiring both exact IDs in the same submission. An app-only review would repeat the production failure. The final submitted readback preserves **AFTER_APPROVAL**. After approval, verify the **IAP itself is APPROVED**, then test production price loading, purchase and restore on a physical device. Preserve saved drawings; uninstalling is unnecessary to diagnose an unapproved purchase and may erase local drafts.

The separate explicit owner submission request has now been received and fulfilled. Existing TestFlight/sandbox purchases do not establish production ownership. Production purchase and restore remain unverified until Apple approves the product and a device completes the real flow.
