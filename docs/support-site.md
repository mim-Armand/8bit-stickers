# Support and privacy website

The complete static source is in `site/`. It contains a small app page, support instructions and a privacy policy. It does **not** publish Sticker Studio, host the editor, or provide an account/upload service.

## Prepared URLs

If the owner deploys `site/` to GitHub Pages for `mim-Armand/8bit-stickers`, the intended URLs are:

| Purpose | Prepared URL |
| --- | --- |
| App page / optional marketing URL | `https://mim-armand.github.io/8bit-stickers/` |
| App Store support URL | `https://mim-armand.github.io/8bit-stickers/support/` |
| App Store privacy policy URL | `https://mim-armand.github.io/8bit-stickers/privacy/` |

**These are proposed destinations, not confirmation that the site is live.** Hosting configuration and deployment are separate root-agent/owner actions. Verify the returned public URLs and HTTP responses before entering them in App Store Connect.

The source is ready for review with a privacy effective date of **October 26, 2026**, for publication on that date. It remains a draft until deployed. Update the effective date if publication happens later, and use the actual hosting provider's disclosure if GitHub Pages is not selected.

## Local review

```sh
python3 scripts/build-support-site.py
python3 -m http.server 8792 --bind 127.0.0.1
```

Open `http://127.0.0.1:8792/site/`, `.../site/support/` and `.../site/privacy/`. The script copies six selected pixel PNGs from the committed art catalog; no external service is involved. Deploy only the `site/` directory, not the repository root.

All HTML, CSS, SVG and PNG resources are local. There is no JavaScript, remote font, analytics, cookie banner, form, backend or Studio bundle. The public support address is `seltzer.wisdom7h@icloud.com`. The App Store link always identifies app **1366485724**.

The homepage explicitly says version 1.2 is being prepared. This avoids suggesting that its 47-sticker collection is already the released version while the existing App Store listing remains older. Change that release-status sentence only after version 1.2 is available. Support text explains Messages placement, the lack of a home-screen window, and the iOS/iPadOS 15 requirement for version 1.2.

The policy distinguishes offline app behavior from Apple services, voluntary support emails and website hosting logs. GitHub Pages logs visitor IP addresses for security: [GitHub Pages data collection](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages#data-collection). Confirm that disclosure at deployment.

## Local verification

Reviewed the homepage at desktop width and support page at 390-pixel mobile width. Browser checks passed for all three pages returning HTTP 200, local navigation links, all six sticker images decoding, a single main landmark per page, no browser/HTTP errors, no external resource requests, no horizontal overflow on mobile, and keyboard navigation through the skip link into main content. Review screenshots are under ignored `build/support-site-review/`. These checks establish the local static source, not public deployment or App Store approval.
