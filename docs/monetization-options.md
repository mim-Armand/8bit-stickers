# One-time sticker pricing

Researched October 26, 2026. This is a proposal; no app price, In-App Purchase, tax, banking or agreement settings were changed during this research.

## Available approaches

| Approach | Customer experience | Work required |
| --- | --- | --- |
| Paid sticker pack | Pay once to download the complete pack from the App Store, including the App Store inside Messages. Use its stickers repeatedly. | Set the app's price in App Store Connect. The current sticker-catalog binary does not need StoreKit for a paid download. |
| Free pack with a permanent premium collection | Download the app free, then buy an optional collection inside a custom Messages interface. | Replace the generated sticker browser with a custom iMessage interface, implement StoreKit purchase/entitlement/restore behavior, and submit a new binary and its first non-consumable In-App Purchase together. |
| Permanent purchase of individual designs | Buy each design once inside the custom interface. | Similar StoreKit work, with separate products and entitlement states for the individual designs. A collection purchase offers a simpler experience. |

Apple explicitly supports paid sticker packs and In-App Purchase in code-based standalone iMessage apps. A non-consumable product is bought once and does not expire or diminish with use; this fits a permanent sticker or collection unlock. A consumable is depleted and repurchased, so it does not describe permanent access. See [Apple's iMessage apps and stickers guide](https://developer.apple.com/imessage/) and [In-App Purchase types](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types/).

## Exact US $1 availability

A read-only App Store Connect API query for this app (`1366485724`) returned a USA app price point with `customerPrice: "1.0"`. An exact **US $1.00 paid download** is available, as well as $0.99. This checks app-download pricing; it does not create or verify an In-App Purchase product's price schedule.

The chosen US price can stay fixed as the base storefront price. Other storefronts use their own currencies and applicable taxes; a US $1 price does not make every international price literally $1. Paid distribution also requires the current Paid Apps Agreement and completed tax/banking information. See [set an app price](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/) and [schedule app price changes](https://developer.apple.com/help/app-store-connect/manage-app-pricing/schedule-price-changes-for-apps).

Changing the app-download price is separate from changing the binary. It charges new purchasers; it does not introduce a charge each time a sticker is sent. Existing owners keep their app purchase. Apple's [iPhone App Store guide](https://support.apple.com/en-gb/guide/iphone/iphc90580097/26/ios/26) describes redownloading an already purchased app for free; applying that ownership model to an app acquired while free means those customers should not be asked to buy the download again. A later premium In-App Purchase would be a separate entitlement, so any grandfathering promise would need explicit implementation.

## Recommendation for this project

For a simple fixed charge, offer the complete pack as a one-time US $1 download after the owner explicitly chooses that business model. If the goal is specifically to sell designs **within** the Messages interface, keep the current pack accessible and plan a later update with a permanent premium-collection unlock. Do not put existing stickers behind a new paywall without deciding how existing users retain access.

Version 1.2 build 5 is a predefined sticker catalog and has no StoreKit purchase interface. App Store Connect alone cannot add an in-Messages unlock to that binary. Apple's [In-App Purchase submission instructions](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/) require the first product of each In-App Purchase type to accompany a new app version. StoreKit implementation, purchase/restore testing and that review belong to a subsequent update if build 5 proceeds as prepared.
