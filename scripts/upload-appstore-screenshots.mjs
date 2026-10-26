#!/usr/bin/env node
// Uploads reviewed native screenshots into the editable version only.
import { readFile, readdir, mkdir, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { api, all, APP_ID } from "./appstore-connect.mjs";
const metadata = JSON.parse(
  await readFile(
    new URL("../Config/AppStoreMetadata.json", import.meta.url),
    "utf8",
  ),
);
const apply = process.argv.includes("--apply");
const includeStore = process.argv.includes("--include-store-wells");
const removeLegacy = process.argv.includes("--remove-legacy");
const version = (
  await all(`/v1/apps/${APP_ID}/appStoreVersions?limit=50`)
).find(
  (v) =>
    v.attributes.platform === "IOS" &&
    v.attributes.versionString === metadata.version,
);
if (!version || version.attributes.appStoreState !== "PREPARE_FOR_SUBMISSION")
  throw new Error("Only the unsubmitted release draft may receive assets");
const locale = (
  await all(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`)
).find((l) => l.attributes.locale === metadata.locale);
if (!locale) throw new Error("Release localization is missing");
const groups = [
  {
    directory: "iphone-6.1",
    size: [1179, 2556],
    types: [
      "IMESSAGE_APP_IPHONE_61",
      ...(includeStore ? ["APP_IPHONE_61"] : []),
    ],
  },
  {
    directory: "ipad-13",
    size: [2064, 2752],
    types: [
      "IMESSAGE_APP_IPAD_PRO_3GEN_129",
      ...(includeStore ? ["APP_IPAD_PRO_3GEN_129"] : []),
    ],
  },
];
const report = {
  appId: APP_ID,
  version: metadata.version,
  build: metadata.build,
  localizationId: locale.id,
  apply,
  sets: [],
};
let sets = await all(
  `/v1/appStoreVersionLocalizations/${locale.id}/appScreenshotSets`,
);
for (const group of groups) {
  const directory = new URL(
    `../release/screenshots/${group.directory}/`,
    import.meta.url,
  );
  const files = (await readdir(directory))
    .filter((f) => f.endsWith(".png"))
    .sort();
  if (files.length !== 3)
    throw new Error("Expected the three reviewed native captures per device");
  for (const displayType of group.types) {
    let set = sets.find(
      (s) => s.attributes.screenshotDisplayType === displayType,
    );
    if (!set && apply) {
      set = (
        await api("POST", "/v1/appScreenshotSets", {
          data: {
            type: "appScreenshotSets",
            attributes: { screenshotDisplayType: displayType },
            relationships: {
              appStoreVersionLocalization: {
                data: { type: "appStoreVersionLocalizations", id: locale.id },
              },
            },
          },
        })
      ).data;
      sets.push(set);
    }
    const existing = set
      ? await all(`/v1/appScreenshotSets/${set.id}/appScreenshots`)
      : [];
    const result = { displayType, id: set?.id, assets: [] };
    for (const fileName of files) {
      const bytes = await readFile(new URL(fileName, directory));
      if (
        bytes.toString("hex", 0, 8) !== "89504e470d0a1a0a" ||
        bytes.readUInt32BE(16) !== group.size[0] ||
        bytes.readUInt32BE(20) !== group.size[1] ||
        bytes[25] !== 2
      )
        throw new Error(
          `Expected exact-size RGB native capture: ${group.directory}/${fileName}`,
        );
      const checksum = createHash("md5").update(bytes).digest("hex");
      let asset = existing.find((a) => a.attributes.fileName === fileName);
      if (
        asset?.attributes.sourceFileChecksum &&
        asset.attributes.sourceFileChecksum !== checksum
      )
        throw new Error(
          `Existing screenshot differs: ${fileName}; review a replacement before deleting it`,
        );
      if (apply && asset?.attributes.assetDeliveryState?.state !== "COMPLETE") {
        if (!asset)
          asset = (
            await api("POST", "/v1/appScreenshots", {
              data: {
                type: "appScreenshots",
                attributes: { fileName, fileSize: bytes.length },
                relationships: {
                  appScreenshotSet: {
                    data: { type: "appScreenshotSets", id: set.id },
                  },
                },
              },
            })
          ).data;
        for (const op of asset.attributes.uploadOperations || []) {
          if (new URL(op.url).protocol !== "https:")
            throw new Error("Non-HTTPS screenshot destination rejected");
          const response = await fetch(op.url, {
            method: op.method,
            redirect: "error",
            headers: Object.fromEntries(
              op.requestHeaders.map((h) => [h.name, h.value]),
            ),
            body: bytes.subarray(op.offset, op.offset + op.length),
            signal: AbortSignal.timeout(30_000),
          });
          if (!response.ok)
            throw new Error(
              `Apple screenshot transfer failed: HTTP ${response.status}`,
            );
        }
        await api("PATCH", `/v1/appScreenshots/${asset.id}`, {
          data: {
            type: "appScreenshots",
            id: asset.id,
            attributes: { uploaded: true, sourceFileChecksum: checksum },
          },
        });
      }
      const state = asset
        ? (await api("GET", `/v1/appScreenshots/${asset.id}`)).data.attributes
            .assetDeliveryState
        : null;
      result.assets.push({ fileName, id: asset?.id, checksum, state });
    }
    report.sets.push(result);
  }
}
if (apply && removeLegacy) {
  if (
    !report.sets.every((s) =>
      s.assets.every((a) => a.state?.state === "COMPLETE"),
    )
  )
    throw new Error(
      "New screenshot processing must finish before removing legacy draft assets",
    );
  const publishedVersions = (
    await all(`/v1/apps/${APP_ID}/appStoreVersions?limit=50`)
  ).filter(
    (v) =>
      v.id !== version.id &&
      ["READY_FOR_SALE", "READY_FOR_DISTRIBUTION"].includes(
        v.attributes.appStoreState,
      ),
  );
  const protectedSets = new Set(),
    protectedAssets = new Set();
  for (const published of publishedVersions) {
    for (const publishedLocale of await all(
      `/v1/appStoreVersions/${published.id}/appStoreVersionLocalizations`,
    )) {
      for (const publishedSet of await all(
        `/v1/appStoreVersionLocalizations/${publishedLocale.id}/appScreenshotSets`,
      )) {
        protectedSets.add(publishedSet.id);
        for (const asset of await all(
          `/v1/appScreenshotSets/${publishedSet.id}/appScreenshots`,
        ))
          protectedAssets.add(asset.id);
      }
    }
  }
  const currentTypes = new Set(groups.flatMap((g) => g.types));
  for (const set of sets.filter(
    (s) => !currentTypes.has(s.attributes.screenshotDisplayType),
  )) {
    // This list comes only from the unsubmitted version's localization, not 1.1.
    if (protectedSets.has(set.id))
      throw new Error("Refusing to change a published screenshot set");
    for (const asset of await all(
      `/v1/appScreenshotSets/${set.id}/appScreenshots`,
    )) {
      if (protectedAssets.has(asset.id))
        throw new Error("Refusing to remove a published screenshot");
      await api("DELETE", `/v1/appScreenshots/${asset.id}`);
    }
  }
  report.legacyDraftAssetsRemoved = true;
}
if (apply) {
  await mkdir("build/release", { recursive: true });
  await writeFile(
    "build/release/screenshot-upload-readback.json",
    JSON.stringify(report, null, 2),
  );
}
console.log(JSON.stringify(report, null, 2));
