/* Run against scripts/start-preview.sh; requires Playwright + its Chromium. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const path = require("node:path");
(async () => {
  const browser = await chromium.launch({
    headless: true,
    ...(process.env.PLAYWRIGHT_CHANNEL
      ? { channel: process.env.PLAYWRIGHT_CHANNEL }
      : {}),
  });
  const page = await browser.newPage({
    viewport: { width: 1440, height: 1050 },
    deviceScaleFactor: 1,
  });
  const errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  page.on("response", (r) => {
    if (r.status() >= 400) errors.push(`${r.status()} ${r.url()}`);
  });
  const previewDir = path.join(__dirname, "../docs/previews");
  await fs.mkdir(previewDir, { recursive: true });
  const root = process.env.PREVIEW_URL || "http://127.0.0.1:8787/prototype/";
  try {
    await page.goto(root);
    await page.locator(".sticker-card").last().waitFor();
    assert.equal(await page.locator(".sticker-card").count(), 67);
    await page.evaluate(() => {
      [...document.images].forEach((image) => {
        image.loading = "eager";
      });
    });
    // Switching lazy images to eager can replace a pending decode request.
    // Wait for the actual load result rather than racing that transition.
    await page.waitForFunction(() =>
      [...document.images]
        .filter((image) => image.getAttribute("src"))
        .every((image) => image.complete && image.naturalWidth > 0),
    );
    assert.equal(
      await page.evaluate(
        () =>
          [...document.images].filter(
            (i) => i.getAttribute("src") && (!i.complete || !i.naturalWidth),
          ).length,
      ),
      0,
    );
    await page.screenshot({
      path: path.join(previewDir, "studio-desktop.png"),
      fullPage: true,
    });
    await page.getByRole("button", { name: /Fresh pixels/ }).click();
    assert.equal(await page.locator(".sticker-card").count(), 57);
    await page.getByRole("button", { name: /Tiny pixels/ }).click();
    assert.equal(await page.locator(".sticker-card").count(), 45);
    await page.getByRole("button", { name: "Cute", exact: true }).click();
    assert.equal(await page.locator(".sticker-card").count(), 12);
    await page
      .getByRole("button", { name: "Preview Henlo", exact: true })
      .click();
    const tinyDownload = page.waitForEvent("download");
    await page.getByRole("link", { name: /Download 16 × 16 PNG/ }).click();
    const tinyFile = await tinyDownload;
    const tinyPath = path.join(__dirname, "../build/tiny-test-export.png");
    await fs.mkdir(path.dirname(tinyPath), { recursive: true });
    await tinyFile.saveAs(tinyPath);
    const tinyPng = await fs.readFile(tinyPath);
    assert.equal(tinyPng.readUInt32BE(16), 16);
    assert.equal(tinyPng.readUInt32BE(20), 16);
    await page
      .getByRole("button", { name: "Close sticker preview", exact: true })
      .click();
    await page.getByRole("button", { name: "Memes", exact: true }).click();
    assert.equal(await page.locator(".sticker-card").count(), 33);
    // All five 67 designs must be discoverable under common spellings.
    for (const query of ["67", "6 7", "six seven"]) {
      await page.getByRole("searchbox").fill(query);
      assert.equal(await page.locator(".sticker-card").count(), 5);
    }
    await page.getByRole("searchbox").fill("");
    await page.getByRole("button", { name: /Fresh pixels/ }).click();
    await page.getByRole("button", { name: "Everyday", exact: true }).click();
    assert.equal(await page.locator(".sticker-card").count(), 2);
    await page.getByRole("button", { name: /In motion/ }).click();
    assert.equal(await page.locator(".sticker-card").count(), 2);
    await page.getByRole("button", { name: /All stickers/ }).click();
    await page.getByRole("searchbox").fill("warm & awake");
    assert.equal(await page.locator(".sticker-card").count(), 1);
    await page
      .getByRole("button", { name: "Save Warm & awake", exact: true })
      .click();
    await page.reload();
    await page.getByRole("button", { name: /Your favorites/ }).click();
    assert.equal(await page.locator(".sticker-card").count(), 1);
    await page
      .getByRole("button", { name: "Preview Warm & awake", exact: true })
      .click();
    const imageDownload = page.waitForEvent("download");
    await page.getByRole("link", { name: /Download sticker/ }).click();
    assert.equal((await imageDownload).suggestedFilename(), "new_coffee.png");
    await page.getByRole("button", { name: /Add to chat preview/ }).click();
    assert.equal(
      await page.locator("#chat-sticker").getAttribute("alt"),
      "Warm & awake in local chat preview",
    );
    await page.getByRole("button", { name: /Pixel lab/ }).click();
    await page.getByRole("button", { name: /Start with a tiny heart/ }).click();
    const draft = await page.evaluate(() =>
      JSON.parse(localStorage.getItem("8bit-draft")),
    );
    assert(draft.some(Boolean));
    await page.evaluate(() =>
      document.querySelector("#toast").classList.remove("show"),
    );
    await page.screenshot({
      path: path.join(previewDir, "pixel-lab-desktop.png"),
      fullPage: true,
    });
    const pngDownload = page.waitForEvent("download");
    await page.getByRole("button", { name: /Download your sticker/ }).click();
    const exported = await pngDownload;
    const exportPath = path.join(__dirname, "../build/studio-test-export.png");
    await fs.mkdir(path.dirname(exportPath), { recursive: true });
    await exported.saveAs(exportPath);
    const png = await fs.readFile(exportPath);
    assert.equal(png.readUInt32BE(16), 300);
    assert.equal(png.readUInt32BE(20), 300);
    assert.equal(png[25], 6); // RGBA
    await page
      .getByRole("button", { name: "Clear canvas", exact: true })
      .click();
    assert.equal(
      await page.evaluate(() =>
        JSON.parse(localStorage.getItem("8bit-draft")).some(Boolean),
      ),
      false,
    );
    await page.getByRole("button", { name: /Undo/ }).click();
    assert.deepEqual(
      await page.evaluate(() => JSON.parse(localStorage.getItem("8bit-draft"))),
      draft,
    );
    await page.reload();
    await page.getByRole("button", { name: /Pixel lab/ }).click();
    assert.deepEqual(
      await page.evaluate(() => JSON.parse(localStorage.getItem("8bit-draft"))),
      draft,
    );
    // Painting, erasing, flood fill, and pointer capture work on actual canvas coordinates.
    const box = await page.locator("#pixel-canvas").boundingBox();
    await page.mouse.click(box.x + box.width / 64, box.y + box.height / 64);
    assert.equal(
      await page.evaluate(
        () => JSON.parse(localStorage.getItem("8bit-draft"))[0],
      ),
      "#f16b85",
    );
    await page.getByRole("button", { name: /Eraser/ }).click();
    await page.mouse.click(box.x + box.width / 64, box.y + box.height / 64);
    assert.equal(
      await page.evaluate(
        () => JSON.parse(localStorage.getItem("8bit-draft"))[0],
      ),
      null,
    );
    await page
      .getByRole("button", { name: "Clear canvas", exact: true })
      .click();
    await page.getByRole("button", { name: /Fill/ }).click();
    await page.mouse.click(box.x + box.width / 64, box.y + box.height / 64);
    assert.equal(
      await page.evaluate(
        () =>
          JSON.parse(localStorage.getItem("8bit-draft")).filter(Boolean).length,
      ),
      1024,
    );
    await page
      .getByRole("button", { name: "Clear canvas", exact: true })
      .click();
    await page.getByRole("button", { name: /Pencil/ }).click();
    await page.locator("#pixel-canvas").focus();
    await page.keyboard.press("ArrowRight");
    await page.keyboard.press("Space");
    assert.equal(
      await page.evaluate(
        () =>
          JSON.parse(localStorage.getItem("8bit-draft")).filter(Boolean).length,
      ),
      1,
    );
    await page
      .getByRole("button", { name: "Clear canvas", exact: true })
      .click();
    await page.getByRole("button", { name: /Start with a tiny heart/ }).click();
    await page
      .getByRole("button", { name: "The collection", exact: true })
      .click();
    await page.getByRole("button", { name: /Fresh pixels/ }).click();
    await page
      .getByRole("button", { name: "Preview Do not disturb", exact: true })
      .click();
    await page.getByRole("button", { name: /Edit pixels/ }).click();
    assert.equal(await page.locator("#lab-view").isVisible(), true);
    assert(
      await page.evaluate(() =>
        JSON.parse(localStorage.getItem("8bit-draft")).some(Boolean),
      ),
    );
    await page
      .getByRole("button", { name: "The collection", exact: true })
      .click();
    await page.getByRole("button", { name: /All stickers/ }).click();
    await page.getByRole("searchbox").fill("impossible-match");
    assert.equal(await page.locator("#empty-state").isVisible(), true);
    await page
      .getByRole("button", { name: "Show all stickers", exact: true })
      .click();
    assert.equal(await page.locator(".sticker-card").count(), 67);
    await page.setViewportSize({ width: 390, height: 844 });
    await page.evaluate(() =>
      document.querySelector("#toast").classList.remove("show"),
    );
    await page.screenshot({
      path: path.join(previewDir, "studio-mobile.png"),
      fullPage: true,
    });
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      ),
      false,
    );
    await page.getByRole("button", { name: /Pixel lab/ }).click();
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      ),
      false,
    );
    await page.evaluate(() =>
      document.querySelector("#toast").classList.remove("show"),
    );
    await page.screenshot({
      path: path.join(previewDir, "pixel-lab-mobile.png"),
      fullPage: true,
    });
    await page.evaluate(() => localStorage.setItem("8bit-favorites", "{}"));
    await page.reload();
    assert.equal(await page.locator(".sticker-card").count(), 67);
    assert.deepEqual(errors, []);
    console.log(
      "PASS: 67 images, 45 tiny sprites, 33 memes, all five 67 designs searchable, favorites persistence, local chat, PNG downloads, editor tools/persistence, transparent 300px export, remix, responsive layout, no browser/network errors.",
    );
  } finally {
    await browser.close();
  }
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
