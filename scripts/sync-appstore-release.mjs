#!/usr/bin/env node
// Dry run by default. Applies draft metadata only; never submits or releases.
import { readFile, mkdir, writeFile } from "node:fs/promises";
import { api, APP_ID } from "./appstore-connect.mjs";
const metadata = JSON.parse(
  await readFile(
    new URL("../Config/AppStoreMetadata.json", import.meta.url),
    "utf8",
  ),
);
const apply = process.argv.includes("--apply");
if (!["MANUAL", "AFTER_APPROVAL"].includes(metadata.releaseType))
  throw new Error("Release type must be MANUAL or AFTER_APPROVAL");
const catalog = JSON.parse(
  await readFile(
    new URL(
      "../8%20bit%20art%20StickerPackExtension/Stickers.xcstickers/Sticker%20Pack.stickerpack/Contents.json",
      import.meta.url,
    ),
    "utf8",
  ),
);
if (metadata.stickerCount !== catalog.stickers.length)
  throw new Error(
    "Release metadata sticker count differs from the native catalog",
  );
const wineIncluded = catalog.stickers.some(
  (s) => s.filename === "wine_01.sticker",
);
if (metadata.appId !== APP_ID) throw new Error("App identity mismatch");
if (
  metadata.name.length > 30 ||
  metadata.subtitle.length > 30 ||
  metadata.promotionalText.length > 170 ||
  metadata.keywords.length > 100 ||
  metadata.description.length > 4000
)
  throw new Error("App Store metadata exceeds field limits");
const app = (await api("GET", `/v1/apps/${APP_ID}`)).data;
if (app.attributes.bundleId !== "eu.armand.--bit-art")
  throw new Error("Unexpected bundle ID");
const version = (
  await api("GET", `/v1/apps/${APP_ID}/appStoreVersions?limit=50`)
).data.find(
  (v) =>
    v.attributes.platform === "IOS" &&
    v.attributes.versionString === metadata.version,
);
if (!version || version.attributes.appStoreState !== "PREPARE_FOR_SUBMISSION")
  throw new Error("Expected an editable 1.2 draft");
const info = (
  await api("GET", `/v1/apps/${APP_ID}/appInfos?limit=10`)
).data.find((i) => i.attributes.appStoreState === "PREPARE_FOR_SUBMISSION");
if (!info) throw new Error("No editable app information");
const localization = (
  await api(
    "GET",
    `/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`,
  )
).data.find((l) => l.attributes.locale === metadata.locale);
const infoLocalization = (
  await api("GET", `/v1/appInfos/${info.id}/appInfoLocalizations`)
).data.find((l) => l.attributes.locale === metadata.locale);
const age = (await api("GET", `/v1/appInfos/${info.id}/ageRatingDeclaration`))
  .data;
const review = (
  await api("GET", `/v1/appStoreVersions/${version.id}/appStoreReviewDetail`)
).data;
console.log(
  JSON.stringify(
    {
      appId: APP_ID,
      versionId: version.id,
      version: metadata.version,
      build: metadata.build,
      releaseType: metadata.releaseType,
      apply,
      websites: [
        metadata.marketingUrl,
        metadata.supportUrl,
        metadata.privacyPolicyUrl,
      ],
    },
    null,
    2,
  ),
);
if (apply) {
  for (const url of [
    metadata.marketingUrl,
    metadata.supportUrl,
    metadata.privacyPolicyUrl,
  ]) {
    const r = await fetch(url, {
      method: "GET",
      signal: AbortSignal.timeout(30_000),
    });
    if (!r.ok || !r.headers.get("content-type")?.includes("text/html"))
      throw new Error(`Public app page unavailable: ${url}`);
  }
  await api("PATCH", `/v1/appStoreVersions/${version.id}`, {
    data: {
      type: "appStoreVersions",
      id: version.id,
      attributes: {
        copyright: metadata.copyright,
        releaseType: metadata.releaseType,
      },
    },
  });
  const versionAttributes = Object.fromEntries(
    [
      "description",
      "keywords",
      "marketingUrl",
      "promotionalText",
      "supportUrl",
      "whatsNew",
    ].map((k) => [k, metadata[k]]),
  );
  await api("PATCH", `/v1/appStoreVersionLocalizations/${localization.id}`, {
    data: {
      type: "appStoreVersionLocalizations",
      id: localization.id,
      attributes: versionAttributes,
    },
  });
  await api("PATCH", `/v1/appInfoLocalizations/${infoLocalization.id}`, {
    data: {
      type: "appInfoLocalizations",
      id: infoLocalization.id,
      attributes: {
        name: metadata.name,
        subtitle: metadata.subtitle,
        privacyPolicyUrl: metadata.privacyPolicyUrl,
      },
    },
  });
  // This catalog supplies predefined art. Host Messages owns chat/UGC features.
  // Derive the alcohol answer from shipped art, not the recovered source archive.
  const ageAttributes = {
    advertising: false,
    alcoholTobaccoOrDrugUseOrReferences: wineIncluded ? "INFREQUENT" : "NONE",
    contests: "NONE",
    gambling: false,
    gamblingSimulated: "NONE",
    gunsOrOtherWeapons: "NONE",
    healthOrWellnessTopics: false,
    lootBox: false,
    medicalOrTreatmentInformation: "NONE",
    messagingAndChat: false,
    parentalControls: false,
    profanityOrCrudeHumor: "NONE",
    ageAssurance: false,
    sexualContentGraphicAndNudity: "NONE",
    sexualContentOrNudity: "NONE",
    socialMedia: false,
    socialMediaAgeRestricted: false,
    horrorOrFearThemes: "NONE",
    matureOrSuggestiveThemes: "NONE",
    unrestrictedWebAccess: false,
    userGeneratedContent: false,
    violenceCartoonOrFantasy: "NONE",
    violenceRealisticProlongedGraphicOrSadistic: "NONE",
    violenceRealistic: "NONE",
    ageRatingOverrideV2: "NONE",
  };
  await api("PATCH", `/v1/ageRatingDeclarations/${age.id}`, {
    data: {
      type: "ageRatingDeclarations",
      id: age.id,
      attributes: ageAttributes,
    },
  });
  await api("PATCH", `/v1/appStoreReviewDetails/${review.id}`, {
    data: {
      type: "appStoreReviewDetails",
      id: review.id,
      attributes: { demoAccountRequired: false, notes: metadata.reviewNotes },
    },
  });
  const verified = {
    checkedAt: new Date().toISOString(),
    appId: APP_ID,
    version: (await api("GET", `/v1/appStoreVersions/${version.id}`)).data,
    localization: (
      await api("GET", `/v1/appStoreVersionLocalizations/${localization.id}`)
    ).data,
    appInfo: (await api("GET", `/v1/appInfos/${info.id}`)).data,
    infoLocalization: (
      await api("GET", `/v1/appInfoLocalizations/${infoLocalization.id}`)
    ).data,
    age: (await api("GET", `/v1/appInfos/${info.id}/ageRatingDeclaration`))
      .data,
    reviewContactPreserved: true,
  };
  await mkdir("build/release", { recursive: true });
  await writeFile(
    "build/release/draft-metadata-readback.json",
    JSON.stringify(verified, null, 2),
  );
  console.log(
    JSON.stringify({
      saved: true,
      version: verified.version.attributes.versionString,
      state: verified.version.attributes.appStoreState,
      releaseType: verified.version.attributes.releaseType,
      ageRating: verified.appInfo.attributes.appStoreAgeRating,
      privacyPolicyUrl: verified.infoLocalization.attributes.privacyPolicyUrl,
    }),
  );
}
