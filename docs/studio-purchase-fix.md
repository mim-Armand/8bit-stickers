# Studio purchase correction — 1.4.1 (11)

On October 31, 2026, an App Store customer reported **Price unavailable** on the Studio Unlock offer. A fresh App Store Connect readback confirmed that public **1.4 (10) is Ready for Distribution**, but Studio Unlock **6827336076 / eu.armand.bitart.studio.unlock** is still **READY_TO_SUBMIT**. Its sole metadata version **45b42e0b-bc8a-4835-8bc8-4d766e48bda1** is still **PREPARE_FOR_SUBMISSION**. The completed October 27 review **62051c1f-8195-49b2-8dae-fc6083e2ce41** contains only one approved app item.

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

## Preparation and release controls

`scripts/prepare-studio-purchase-fix.mjs` is a dry run by default. `--apply` creates/updates this exact editable draft and selects processed build 11. `--apply --stage-review` requires a selected **VALID / APP_STORE_ELIGIBLE** build, all inherited screenshots, the completed IAP review image, the exact $1.00 price and the recorded territory approval. It then attaches **both** the app version and existing first-IAP metadata version to **one unsubmitted review draft**. It rejects unrelated review items. It deliberately contains no review-submission operation.

```sh
node scripts/prepare-studio-purchase-fix.mjs
./scripts/archive-studio-appstore.sh
# After Apple validation/upload and build processing:
node scripts/prepare-studio-purchase-fix.mjs --apply --stage-review
```

The signed output is `build/studio-release/1.4.1-11/`. Private Apple readbacks and test logs stay under ignored `build/purchase-investigation/` and `build/studio-price-fix-*`. Sanitized final state and verification are recorded in `release/studio-1.4.1/preparation-status.json` when preparation finishes.

Before a later authorized submission, read the draft items back using `include=appStoreVersion,inAppPurchaseVersion` and require both exact IDs in the same submission. An app-only review would repeat the production failure. Keep **AFTER_APPROVAL**. After approval, verify the **IAP itself is APPROVED**, then test production price loading, purchase and restore on a physical device. Preserve saved drawings; uninstalling is unnecessary to diagnose an unapproved purchase and may erase local drafts.

This corrective preparation does not authorize App Review submission. The project requires a separate explicit submission request. Existing TestFlight/sandbox purchases do not establish production ownership.
