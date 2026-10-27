#!/usr/bin/env node
// Dry run by default. Changes only the editable 1.4 draft and its first IAP review
// image; never submits, changes availability, or mutates another version's assets.
import { createHash } from "node:crypto";
import { readFile, realpath, mkdir, writeFile } from "node:fs/promises";
import { basename, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { api, all, APP_ID } from "./appstore-connect.mjs";

const ROOT = fileURLToPath(new URL("../", import.meta.url));
const SHOTS = resolve(ROOT, "release/studio-1.4/screenshots");
const REPORT = resolve(ROOT, "build/studio-release/screenshots-upload-readback.json");
const IAP_ID = "6827336076";
const PRODUCT_ID = "eu.armand.bitart.studio.unlock";
const flags = new Set(process.argv.slice(2));
for (const flag of flags)
  if (!["--apply", "--retire-inherited"].includes(flag))
    throw new Error(`Unknown option: ${flag}`);
const apply = flags.has("--apply");
const retireInherited = flags.has("--retire-inherited");
const groups = [
  { family: "iphone-6.1", size: [1179, 2556], types: ["APP_IPHONE_61", "IMESSAGE_APP_IPHONE_61"] },
  { family: "ipad-13", size: [2064, 2752], types: ["APP_IPAD_PRO_3GEN_129", "IMESSAGE_APP_IPAD_PRO_3GEN_129"] },
];
const report = { startedAtUTC: new Date().toISOString(), appID: APP_ID, version: "1.4", build: "10", apply, retireInherited, sets: [], iapReview: null };
let version, locale, protectedSets, protectedAssets;

const json = async (path) => JSON.parse(await readFile(path, "utf8"));
const deliveryState = (asset) => asset?.attributes?.assetDeliveryState?.state ?? null;
const digest = (algorithm, bytes) => createHash(algorithm).update(bytes).digest("hex");
const fileSummary = ({ bytes, ...file }) => file;
const signature = (asset) => {
  const { fileName, sourceFileChecksum } = asset.attributes;
  return sourceFileChecksum ? `${fileName}\n${sourceFileChecksum.toLowerCase()}` : null;
};
async function save() {
  report.finishedAtUTC = new Date().toISOString();
  await mkdir(resolve(ROOT, "build/studio-release"), { recursive: true });
  await writeFile(REPORT, `${JSON.stringify(report, null, 2)}\n`);
}
async function readImage(asset, size, directory) {
  if (!asset || asset.mode !== "RGB" || !/^[a-f0-9]{64}$/i.test(asset.sha256 ?? ""))
    throw new Error("Capture manifest must supply RGB images and SHA-256 checksums");
  const path = await realpath(resolve(ROOT, asset.path));
  const allowed = await realpath(directory);
  if (!path.startsWith(`${allowed}${sep}`) || !path.endsWith(".png"))
    throw new Error(`Capture is outside its expected screenshot directory: ${asset.path}`);
  const bytes = await readFile(path);
  if (bytes.length < 33 || bytes.toString("hex", 0, 8) !== "89504e470d0a1a0a" ||
      bytes.toString("ascii", 12, 16) !== "IHDR" || bytes[24] !== 8 || bytes[25] !== 2 ||
      bytes.readUInt32BE(16) !== size[0] || bytes.readUInt32BE(20) !== size[1] ||
      JSON.stringify(asset.size) !== JSON.stringify(size))
    throw new Error(`Expected exact-size 8-bit RGB PNG: ${asset.path}`);
  const sha256 = digest("sha256", bytes);
  if (sha256 !== asset.sha256.toLowerCase())
    throw new Error(`Capture differs from its reviewed manifest: ${asset.path}`);
  return { path: relative(ROOT, path), fileName: basename(path), size, bytes, fileSize: bytes.length, checksum: digest("md5", bytes), sha256 };
}
async function assertEditable() {
  const current = (await api("GET", `/v1/appStoreVersions/${version.id}`)).data;
  if (current.attributes.platform !== "IOS" || current.attributes.versionString !== "1.4" ||
      current.attributes.appStoreState !== "PREPARE_FOR_SUBMISSION")
    throw new Error("Only the unsubmitted, editable iOS 1.4 draft may receive screenshots");
}
function assertUnprotected(setID, assetID) {
  if (setID && protectedSets.has(setID))
    throw new Error(`Refusing to mutate a screenshot set used by another version: ${setID}`);
  if (assetID && protectedAssets.has(assetID))
    throw new Error(`Refusing to mutate an image used by another version: ${assetID}`);
}
function assertSameFile(asset, file) {
  // Apple canonicalizes the single IAP review image's filename to SOURCE.
  // Its exact byte count and checksum still identify the reviewed image; ordinary
  // App Store screenshots retain strict filename matching below.
  const canonicalIAP = asset.type === "inAppPurchaseAppStoreReviewScreenshots" &&
    asset.attributes.fileName?.toUpperCase() === "SOURCE";
  if ((!canonicalIAP && asset.attributes.fileName !== file.fileName) || asset.attributes.fileSize !== file.fileSize)
    throw new Error(`Existing image differs from the intended file: ${file.fileName}`);
  const checksum = asset.attributes.sourceFileChecksum;
  if (checksum && checksum.toLowerCase() !== file.checksum)
    throw new Error(`Existing image checksum differs: ${file.fileName}; no replacement/deletion attempted`);
  if (deliveryState(asset) === "COMPLETE" && !checksum)
    throw new Error(`Cannot verify the completed image's checksum: ${file.fileName}`);
}
async function transfer(file, asset, endpoint, type, setID) {
  assertSameFile(asset, file);
  if (["COMPLETE", "UPLOAD_COMPLETE", "PROCESSING"].includes(deliveryState(asset))) return asset;
  if (deliveryState(asset) === "FAILED")
    throw new Error(`Apple processing failed for ${file.fileName}; inspect the saved readback before replacing it`);
  assertUnprotected(setID, type === "appScreenshots" ? asset.id : null);
  await assertEditable();
  const operations = asset.attributes.uploadOperations ?? [];
  if (!operations.length) throw new Error(`No resumable upload operations for ${file.fileName}`);
  for (const operation of operations) {
    const url = new URL(operation.url);
    const appleHost = ["apple.com", "icloud.com", "icloud-content.com", "mzstatic.com"]
      .some((domain) => url.hostname === domain || url.hostname.endsWith(`.${domain}`));
    if (url.protocol !== "https:" || !appleHost || operation.method !== "PUT" ||
        !Number.isSafeInteger(operation.offset) || !Number.isSafeInteger(operation.length) ||
        operation.offset < 0 || operation.length <= 0 || operation.offset + operation.length > file.bytes.length)
      throw new Error(`Invalid Apple upload operation for ${file.fileName}`);
    const response = await fetch(url, {
      method: operation.method,
      headers: Object.fromEntries((operation.requestHeaders ?? []).map(({ name, value }) => [name, value])),
      body: file.bytes.subarray(operation.offset, operation.offset + operation.length),
      redirect: "error", signal: AbortSignal.timeout(30_000),
    });
    if (!response.ok) throw new Error(`Apple image transfer failed: ${file.fileName}, HTTP ${response.status}`);
  }
  await assertEditable();
  await api("PATCH", `${endpoint}/${asset.id}`, {
    data: { type, id: asset.id, attributes: { uploaded: true, sourceFileChecksum: file.checksum } },
  });
  return (await api("GET", `${endpoint}/${asset.id}`)).data;
}
async function uploadAppImage(file, set, existing) {
  let asset = existing.find((item) => item.attributes.fileName === file.fileName);
  if (asset) assertSameFile(asset, file);
  if (apply && !asset) {
    assertUnprotected(set.id);
    await assertEditable();
    asset = (await api("POST", "/v1/appScreenshots", {
      data: { type: "appScreenshots", attributes: { fileName: file.fileName, fileSize: file.fileSize },
        relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: set.id } } } },
    })).data;
  }
  if (apply && asset) asset = await transfer(file, asset, "/v1/appScreenshots", "appScreenshots", set.id);
  return { file: fileSummary(file), id: asset?.id ?? null, state: deliveryState(asset), resource: asset ?? null };
}
async function main() {
  const metadata = await json(resolve(ROOT, "Config/StudioAppStoreMetadata.json"));
  const manifest = await json(resolve(SHOTS, "manifest.json"));
  if (APP_ID !== "1366485724" || metadata.appId !== APP_ID || metadata.version !== "1.4" || String(metadata.build) !== "10" ||
      metadata.commerce?.appleId !== IAP_ID || metadata.commerce.productId !== PRODUCT_ID ||
      manifest.appID !== APP_ID || manifest.version !== "1.4" || String(manifest.build) !== "10")
    throw new Error("Studio app, product, version or build identity mismatch");
  if (!Array.isArray(manifest.families) || manifest.families.length !== 2)
    throw new Error("Both reviewed iPhone and iPad capture families are required");
  const seenFamilies = new Set();
  let iapFile;
  for (const group of groups) {
    const family = manifest.families.find((entry) => entry.deviceFamily === group.family);
    if (!family || seenFamilies.has(family.deviceFamily) || family.appID !== APP_ID ||
        family.version !== "1.4" || String(family.build) !== "10" || family.publicUICopy !== true ||
        family.configuration !== "Screenshots" || family.stickerCount !== 67 || family.templates !== 45 ||
        family.wineExcluded !== true)
      throw new Error(`Unexpected capture identity/provenance for ${group.family}`);
    seenFamilies.add(family.deviceFamily);
    const assets = family.assets.filter((asset) => asset.purpose === "app-store");
    if (assets.length < 1 || assets.length > 10) throw new Error(`Expected 1–10 App Store images for ${group.family}`);
    group.files = (await Promise.all(assets.map((asset) => readImage(asset, group.size, resolve(SHOTS, group.family)))))
      .sort((a, b) => a.fileName.localeCompare(b.fileName));
    if (new Set(group.files.map((file) => file.fileName)).size !== group.files.length)
      throw new Error(`Duplicate screenshot filenames for ${group.family}`);
    if (group.family === "iphone-6.1") {
      const reviews = family.assets.filter((asset) => asset.purpose === "iap-review" && basename(asset.path) === "iap-review-iphone-6.1.png");
      if (reviews.length !== 1) throw new Error("Exactly one reviewed phone IAP image is required");
      iapFile = await readImage(reviews[0], group.size, SHOTS);
      if (iapFile.path !== "release/studio-1.4/screenshots/iap-review-iphone-6.1.png")
        throw new Error("Unexpected IAP review image path");
    }
  }
  report.manifest = relative(ROOT, resolve(SHOTS, "manifest.json"));
  const [app, versions, products] = await Promise.all([
    api("GET", `/v1/apps/${APP_ID}`), all(`/v1/apps/${APP_ID}/appStoreVersions?limit=200`),
    all(`/v1/apps/${APP_ID}/inAppPurchasesV2?limit=200`),
  ]);
  if (app.data.attributes.bundleId !== "eu.armand.--bit-art") throw new Error("Unexpected published bundle ID");
  const product = products.find((entry) => entry.id === IAP_ID && entry.attributes.productId === PRODUCT_ID && entry.attributes.inAppPurchaseType === "NON_CONSUMABLE");
  if (!product) throw new Error("The registered non-consumable does not belong to this app");
  version = versions.find((entry) => entry.attributes.platform === "IOS" && entry.attributes.versionString === "1.4");
  if (!version) throw new Error("The editable 1.4 draft does not exist");
  await assertEditable();
  locale = (await all(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`))
    .find((entry) => entry.attributes.locale === metadata.locale);
  if (!locale) throw new Error("Studio release localization is missing");
  report.versionID = version.id;
  report.localizationID = locale.id;
  protectedSets = new Set(); protectedAssets = new Set();
  const inheritedSignatures = new Set();
  // Protect every other version, including both published versions and any drafts.
  for (const other of versions.filter((entry) => entry.id !== version.id)) {
    for (const otherLocale of await all(`/v1/appStoreVersions/${other.id}/appStoreVersionLocalizations?limit=200`)) {
      for (const set of await all(`/v1/appStoreVersionLocalizations/${otherLocale.id}/appScreenshotSets?limit=200`)) {
        protectedSets.add(set.id);
        for (const asset of await all(`/v1/appScreenshotSets/${set.id}/appScreenshots?limit=200`)) {
          protectedAssets.add(asset.id);
          if (other.attributes.versionString === "1.2" && signature(asset)) inheritedSignatures.add(signature(asset));
        }
      }
    }
  }
  report.protected = { setIDs: [...protectedSets], assetIDs: [...protectedAssets], inherited12Signatures: [...inheritedSignatures] };
  const sets = await all(`/v1/appStoreVersionLocalizations/${locale.id}/appScreenshotSets?limit=200`);
  for (const group of groups) for (const displayType of group.types) {
    let set = sets.find((entry) => entry.attributes.screenshotDisplayType === displayType);
    const existing = set ? await all(`/v1/appScreenshotSets/${set.id}/appScreenshots?limit=200`) : [];
    const missing = group.files.filter((file) => !existing.some((asset) => asset.attributes.fileName === file.fileName));
    if (existing.length + missing.length > 10) throw new Error(`Safe upload would exceed ten images in ${displayType}; no inherited images were removed`);
    if (apply && !set) {
      await assertEditable();
      set = (await api("POST", "/v1/appScreenshotSets", { data: { type: "appScreenshotSets", attributes: { screenshotDisplayType: displayType },
        relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: locale.id } } } } })).data;
      sets.push(set);
    }
    const result = { displayType, id: set?.id ?? null, assets: [], existing };
    report.sets.push(result);
    if (apply && set) assertUnprotected(set.id);
    for (const file of group.files) result.assets.push(await uploadAppImage(file, set, existing));
  }
  let review;
  try { review = (await api("GET", `/v2/inAppPurchases/${IAP_ID}/appStoreReviewScreenshot`)).data; }
  catch (error) { if (error.status !== 404) throw error; }
  if (review) assertSameFile(review, iapFile);
  if (apply && (!review || !["COMPLETE", "UPLOAD_COMPLETE", "PROCESSING"].includes(deliveryState(review)))) {
    if (!["MISSING_METADATA", "WAITING_FOR_UPLOAD", "READY_TO_SUBMIT"].includes(product.attributes.state))
      throw new Error("The IAP is not an unsubmitted draft; no review-image mutation attempted");
    await assertEditable();
    if (!review) review = (await api("POST", "/v1/inAppPurchaseAppStoreReviewScreenshots", { data: {
      type: "inAppPurchaseAppStoreReviewScreenshots", attributes: { fileName: iapFile.fileName, fileSize: iapFile.fileSize },
      relationships: { inAppPurchaseV2: { data: { type: "inAppPurchases", id: IAP_ID } } },
    } })).data;
    review = await transfer(iapFile, review, "/v1/inAppPurchaseAppStoreReviewScreenshots", "inAppPurchaseAppStoreReviewScreenshots");
  }
  report.iapReview = { productID: PRODUCT_ID, appleID: IAP_ID, file: fileSummary(iapFile), id: review?.id ?? null, state: deliveryState(review), resource: review ?? null };
  // Refresh processing after the upload batch; rerunning safely resumes pending work.
  for (const set of report.sets) for (const asset of set.assets) if (asset.id) {
    asset.resource = (await api("GET", `/v1/appScreenshots/${asset.id}`)).data;
    assertSameFile(asset.resource, asset.file);
    asset.state = deliveryState(asset.resource);
  }
  if (review) {
    report.iapReview.resource = (await api("GET", `/v1/inAppPurchaseAppStoreReviewScreenshots/${review.id}`)).data;
    assertSameFile(report.iapReview.resource, iapFile);
    report.iapReview.state = deliveryState(report.iapReview.resource);
  }
  report.allDesiredComplete = report.sets.every((set) => set.assets.every((asset) => asset.state === "COMPLETE")) && report.iapReview.state === "COMPLETE";
  report.retirement = { candidates: [], retainedUnknown: [], deleted: [], status: retireInherited ? "planned" : "not-requested" };
  for (const set of sets) {
    const desired = new Set(report.sets.find((entry) => entry.id === set.id)?.assets.map((asset) => asset.id) ?? []);
    for (const asset of await all(`/v1/appScreenshotSets/${set.id}/appScreenshots?limit=200`)) {
      if (desired.has(asset.id)) continue;
      const item = { setID: set.id, id: asset.id, fileName: asset.attributes.fileName, checksum: asset.attributes.sourceFileChecksum ?? null };
      if (signature(asset) && inheritedSignatures.has(signature(asset))) report.retirement.candidates.push(item);
      else report.retirement.retainedUnknown.push(item);
    }
  }
  if (apply && retireInherited) {
    if (!report.allDesiredComplete) report.retirement.status = "awaiting-new-image-processing";
    else {
      for (const asset of report.retirement.candidates) {
        assertUnprotected(asset.setID, asset.id);
        await assertEditable();
        await api("DELETE", `/v1/appScreenshots/${asset.id}`);
        report.retirement.deleted.push(asset);
      }
      report.retirement.status = "complete";
    }
  }
  report.complete = apply && report.allDesiredComplete && (!retireInherited || report.retirement.status === "complete");
  if (apply && !report.complete) process.exitCode = 2;
}
try {
  await main();
  await save();
  console.log(JSON.stringify({ appID: APP_ID, version: "1.4", build: "10", apply, complete: report.complete,
    sets: report.sets.map(({ displayType, assets }) => ({ displayType, assets: assets.map(({ id, state, file }) => ({ id, fileName: file.fileName, checksum: file.checksum, state })) })),
    iapReview: report.iapReview && { id: report.iapReview.id, state: report.iapReview.state }, retirement: report.retirement,
    privateReadback: relative(ROOT, REPORT) }, null, 2));
} catch (error) {
  report.error = { message: error.message, status: error.status, details: error.details };
  await save();
  console.error(JSON.stringify({ error: error.message, details: error.details, privateReadback: relative(ROOT, REPORT) }, null, 2));
  process.exitCode = 1;
}
