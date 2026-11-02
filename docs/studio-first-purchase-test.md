# First-time Studio purchase — private TestFlight test

On November 2, 2026, the owner authorized adding one supplied Apple Account email for a purchase test on another device. The target is stored only in ignored `build/fresh-buyer-test/` readbacks. No App Store Connect role is granted. The external group **Studio First Purchase Test** has public links off and receives only the authorized beta.

Internal build 12 cannot be distributed to an external tester. **1.4.1 (13)** uses **TestFlightExternalDiagnostics** and is eligible for external TestFlight distribution. The first external build requires **Beta App Review** before the tester can install it. This beta review does not change the rejected production app/IAP submission or select a new production build.

Ordinary TestFlight purchases automatically use Apple's sandbox. The other device's **Media & Purchases Apple Account** must be the intended account with no Studio Unlock purchase. Signing into iCloud alone does not prove which account is used for purchases. The supplied existing iCloud identity is added as a TestFlight tester; it is not converted into a separate Sandbox Apple Account. A dedicated Sandbox Apple Account would require a different unused address and separate sandbox-control sign-in, which is unnecessary for this basic clean purchase test. [Apple's TestFlight purchase behavior](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight/), [Sandbox Apple Account requirements](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/create-a-sandbox-apple-account/).

## What build 13 records

The first normal checkout product request is captured **before filtering**. Its result, request times, pre-request Studio access, app/build identity and sanitized error domain/code are saved once per build in local preferences. Storefront enrichment runs afterward without delaying checkout. Later retries, manual checks and service recreation cannot replace the original result. The record contains no account address, purchase/transaction identifiers, receipt, messages or drawings.

Help adds **Copy initial price report** alongside the existing current availability probe. These are observation tools: checkout still requires the exact Apple product and verified ownership; there is no fallback price or free access. The public AppStore configuration and rejected build 11 remain unchanged.

## Device test

1. Accept the named TestFlight invitation when Beta App Review permits distribution. Install **8 bit art 1.4.1 (13)** through TestFlight on the other device, using the intended unowned Media & Purchases account.
2. Open **Messages → a conversation → + / More → 8 bit art → Studio**. Studio should initially be locked. Before buying or restoring, open **? → Copy initial price report** and send that report to this chat. It should show `studioUnlockedBeforeRequest: false`. If Studio is already unlocked, this is not a clean purchase context; report that state without resetting the owner's history.
3. Open the unlock offer and record whether Apple's localized price appears on its first load. If it says **Price unavailable**, preserve the initial report before trying **Check purchase availability** and copying the current technical report. The two reports distinguish the first result from a later retry.
4. If the price appears, complete the **TestFlight sandbox** purchase. It makes no real charge. Confirm the editor opens automatically and a small test drawing saves.
5. Close and reopen Messages, confirm Studio is still unlocked and the drawing remains, then use **Help → Restore Purchases** and report the result. Do not send a message merely to test purchase access.

Report: initial price/report, whether the sandbox confirmation completed, whether the editor opened, and whether relaunch/restore retained access. A diagnostic read or a model test alone is not a successful first-time purchase.

## Release controls and evidence

Source configuration: `Config/StudioExternalTestMetadata.json`; scheme: **Studio External Diagnostics**; archive helper: `scripts/archive-studio-external-diagnostics.sh`. The signed export uses the eligible App Store Connect export method, but **is not selected or submitted for production review**. External access is confined to the private named-email group, not a public link.

Sanitized progress is in `release/studio-first-purchase-status.json`; private invitation/contact/readbacks and signing output remain ignored under `build/fresh-buyer-test/` and `build/studio-external-test/`. All **37 core/model tests** pass, including first empty/error report persistence across successful retries and service recreation. These tests use Xcode StoreKit fixtures only in the test host; fixtures are excluded from the beta archive.

Production submission **4ab04eda-8610-4e9d-8552-8617b6a3f7e2**, selected app **1.4.1 (11)** and its IAP item remain intact. The root cause is still unresolved until a clean device result or Apple reviewer diagnostics explains the failure. Do not claim the purchase issue fixed, repeat production review, change the $1.00 price/175 territories, or send the unsent App Review response merely because the existing owner can fetch the product.
