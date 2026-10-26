# Support and privacy website

The complete static source is in `site/`. It contains a small app page, support instructions and a privacy policy. It does **not** publish Sticker Studio, host the editor, or provide an account/upload service.

## Live URLs

The static `site/` output was deployed to GitHub Pages for `mim-Armand/8bit-stickers`:

| Purpose | Verified public URL |
| --- | --- |
| App page / optional marketing URL | `https://mim-armand.github.io/8bit-stickers/` |
| App Store support URL | `https://mim-armand.github.io/8bit-stickers/support/` |
| App Store privacy policy URL | `https://mim-armand.github.io/8bit-stickers/privacy/` |

All three URLs returned **HTTP 200**, the Pages build completed, and **HTTPS enforcement is enabled**. The published `gh-pages` commit is `30355ecd03d7b135b002f614803367d73eb3c805`. The support/privacy URLs are staged in App Store Connect. This public site contains no Studio/editor bundle.

The published policy's effective date is **October 26, 2026**. Its hosting disclosure describes GitHub Pages. The App Privacy label in App Store Connect is a separate task and is not established by publishing this policy URL.

## Local review

```sh
python3 scripts/build-support-site.py
python3 -m http.server 8792 --bind 127.0.0.1
```

Open `http://127.0.0.1:8792/site/`, `.../site/support/` and `.../site/privacy/`. The script copies six selected pixel PNGs from the committed art catalog; no external service is involved. Deploy only the `site/` directory, not the repository root.

All HTML, CSS, SVG and PNG resources are local. There is no JavaScript, remote font, analytics, cookie banner, form, backend or Studio bundle. The public support address is `seltzer.wisdom7h@icloud.com`. The App Store link always identifies app **1366485724**.

The homepage explicitly says version 1.2 is being prepared. This avoids suggesting that its 46-sticker collection is already the released version while the existing App Store listing remains older. Change that release-status sentence only after version 1.2 is available. Support text explains Messages placement, the lack of a home-screen window, and the iOS/iPadOS 15 requirement for version 1.2.

The policy distinguishes offline app behavior from Apple services, voluntary support emails and website hosting logs. GitHub Pages logs visitor IP addresses for security: [GitHub Pages data collection](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages#data-collection).

## Local verification

Reviewed the homepage at desktop width and support page at 390-pixel mobile width. Local browser checks passed for all three pages returning HTTP 200, navigation links, all six sticker images decoding, a single main landmark per page, no browser/HTTP errors, no external resource requests, no horizontal overflow on mobile, and keyboard navigation through the skip link into main content. Review screenshots are under ignored `build/support-site-review/`. Public deployment was then verified separately through HTTP responses and the Pages build state. Neither website check establishes App Review approval or public release of version 1.2.
