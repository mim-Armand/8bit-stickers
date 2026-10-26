#!/usr/bin/env node
// Selects a processed candidate in the editable draft; never submits for review.
import { readFile, mkdir, writeFile } from "node:fs/promises";
import { api, all, APP_ID } from "./appstore-connect.mjs";
const metadata = JSON.parse(
  await readFile(
    new URL("../Config/AppStoreMetadata.json", import.meta.url),
    "utf8",
  ),
);
const apply = process.argv.includes("--apply");
const app = (await api("GET", `/v1/apps/${APP_ID}`)).data;
if (
  app.attributes.bundleId !== "eu.armand.--bit-art" ||
  metadata.appId !== APP_ID
)
  throw new Error("App identity mismatch");
const version = (
  await all(`/v1/apps/${APP_ID}/appStoreVersions?limit=50`)
).find(
  (v) =>
    v.attributes.versionString === metadata.version &&
    v.attributes.platform === "IOS",
);
if (!version || version.attributes.appStoreState !== "PREPARE_FOR_SUBMISSION")
  throw new Error("Only an unsubmitted draft may be changed");
const builds = await all(
  `/v1/builds?filter[app]=${APP_ID}&filter[version]=${encodeURIComponent(metadata.build)}&include=preReleaseVersion&limit=100`,
);
const build = builds.find((b) => b.attributes.processingState === "VALID");
if (!build) throw new Error(`Build ${metadata.build} is not VALID`);
const prerelease = (
  await api("GET", `/v1/builds/${build.id}/preReleaseVersion`)
).data;
if (
  prerelease.attributes.version !== metadata.version ||
  prerelease.attributes.platform !== "IOS"
)
  throw new Error("Build belongs to a different version or platform");
if (apply)
  await api("PATCH", `/v1/appStoreVersions/${version.id}/relationships/build`, {
    data: { type: "builds", id: build.id },
  });
const selected = (await api("GET", `/v1/appStoreVersions/${version.id}/build`))
  .data;
const beta = (await api("GET", `/v1/builds/${build.id}/buildBetaDetail`)).data;
const report = {
  versionId: version.id,
  version: metadata.version,
  apply,
  candidateBuildId: build.id,
  selected: selected?.id === build.id,
  build: selected,
  beta,
};
if (apply) {
  await mkdir("build/release", { recursive: true });
  await writeFile(
    "build/release/selected-build.json",
    JSON.stringify(report, null, 2),
  );
}
console.log(
  JSON.stringify(
    {
      version: metadata.version,
      build: metadata.build,
      id: build.id,
      state: build.attributes.processingState,
      selected: report.selected,
      apply,
    },
    null,
    2,
  ),
);
