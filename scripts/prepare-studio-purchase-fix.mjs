#!/usr/bin/env node
// Prepare the 1.4.1 correction. Even --stage-review only assembles a draft;
// this script deliberately has no operation that submits it to Apple.
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { api, all, APP_ID } from './appstore-connect.mjs';

const flags = new Set(process.argv.slice(2));
for (const flag of flags) if (!['--apply', '--stage-review'].includes(flag)) throw new Error(`Unknown option: ${flag}`);
const apply = flags.has('--apply');
const stage = flags.has('--stage-review');
if (stage && !apply) throw new Error('--stage-review requires --apply');
const m = JSON.parse(await readFile(new URL('../Config/StudioAppStoreMetadata.json', import.meta.url), 'utf8'));
const IAP_VERSION = '45b42e0b-bc8a-4835-8bc8-4d766e48bda1';
if (APP_ID !== '1366485724' || m.appId !== APP_ID || m.version !== '1.4.1' || m.build !== '11' ||
    m.commerce.appleId !== '6827336076' || m.commerce.productId !== 'eu.armand.bitart.studio.unlock' ||
    m.releaseType !== 'AFTER_APPROVAL' || !m.preparationOnly) throw new Error('Unexpected correction identity');
for (const [key, max] of Object.entries({ description: 4000, keywords: 100, promotionalText: 170, whatsNew: 4000, reviewNotes: 4000 }))
  if (!m[key] || m[key].length > max) throw new Error(`Invalid ${key}`);

const report = { verifiedAtUTC: new Date().toISOString(), appID: APP_ID, version: m.version, build: m.build, apply, stage,
  reviewSubmittedByThisRun: false };
async function save() {
  await mkdir('build/purchase-investigation', { recursive: true });
  await writeFile('build/purchase-investigation/prepared-correction.json', JSON.stringify(report, null, 2) + '\n');
}
async function editable(version) {
  const current = (await api('GET', `/v1/appStoreVersions/${version.id}`)).data;
  if (current.attributes.versionString !== m.version || current.attributes.platform !== 'IOS' ||
      !['PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW'].includes(current.attributes.appStoreState))
    throw new Error('Correction is no longer an editable/unsubmitted draft');
  return current;
}
try {
  const app = (await api('GET', `/v1/apps/${APP_ID}`)).data;
  if (app.attributes.bundleId !== 'eu.armand.--bit-art') throw new Error('Wrong app bundle');
  const product = (await api('GET', `/v2/inAppPurchases/${m.commerce.appleId}`)).data;
  if (product.attributes.productId !== m.commerce.productId || product.attributes.inAppPurchaseType !== 'NON_CONSUMABLE' ||
      product.attributes.familySharable !== false || !['READY_TO_SUBMIT', 'WAITING_FOR_REVIEW'].includes(product.attributes.state))
    throw new Error('Purchase identity or review state differs; inspect before editing');
  const iapVersions = await all(`/v2/inAppPurchases/${product.id}/versions`);
  if (!iapVersions.some(x => x.id === IAP_VERSION && ['PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW'].includes(x.attributes.state)))
    throw new Error('Existing first IAP metadata version is no longer editable');
  const prices = await api('GET', `/v1/inAppPurchasePriceSchedules/${product.id}/manualPrices?include=inAppPurchasePricePoint,territory&filter[territory]=USA`);
  if (!prices.data.some(x => x.attributes.startDate === null && x.attributes.endDate === null &&
      x.relationships.territory.data.id === 'USA' && x.relationships.inAppPurchasePricePoint.data.id === m.commerce.usaPricePointId) ||
      !prices.included.some(x => x.type === 'inAppPurchasePricePoints' && x.id === m.commerce.usaPricePointId && Number(x.attributes.customerPrice) === 1))
    throw new Error('Exact ongoing US$1.00 purchase price differs');
  const availability = (await api('GET', `/v2/inAppPurchases/${product.id}/inAppPurchaseAvailability`)).data;
  const territories = (await all(`/v1/inAppPurchaseAvailabilities/${availability.id}/availableTerritories?limit=200`)).map(x => x.id).sort();
  const approved = JSON.parse(await readFile(new URL('../release/studio-1.4/availability-plan.json', import.meta.url), 'utf8'));
  if (!approved.ownerApproval?.granted || availability.attributes.availableInNewTerritories !== false ||
      JSON.stringify(territories) !== JSON.stringify([...approved.proposedTerritories].sort())) throw new Error('Approved purchase availability differs');
  report.purchase = { id: product.id, productID: product.attributes.productId, state: product.attributes.state,
    metadataVersionID: IAP_VERSION, usaPrice: '1.00', familySharing: false, territoryCount: territories.length };
  const versions = await all(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200`);
  const previous = versions.find(x => x.attributes.versionString === '1.4');
  if (previous?.attributes.appStoreState !== 'READY_FOR_SALE') throw new Error('Expected released 1.4 is missing');
  let version = versions.find(x => x.attributes.versionString === m.version);
  if (!version && apply) version = (await api('POST', '/v1/appStoreVersions', { data: { type: 'appStoreVersions',
    attributes: { platform: 'IOS', versionString: m.version, copyright: m.copyright, releaseType: m.releaseType },
    relationships: { app: { data: { type: 'apps', id: APP_ID } } } } })).data;
  report.versionID = version?.id ?? null;
  if (!version) { report.nextAction = 'Create 1.4.1 draft'; await save(); console.log(JSON.stringify(report, null, 2)); process.exit(0); }
  await editable(version);
  const locale = (await all(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`)).find(x => x.attributes.locale === m.locale);
  if (!locale) throw new Error('Expected inherited en-US localization');
  report.localizationID = locale.id;
  if (apply) {
    await api('PATCH', `/v1/appStoreVersions/${version.id}`, { data: { type: 'appStoreVersions', id: version.id,
      attributes: { releaseType: m.releaseType, copyright: m.copyright } } });
    await api('PATCH', `/v1/appStoreVersionLocalizations/${locale.id}`, { data: { type: 'appStoreVersionLocalizations', id: locale.id,
      attributes: Object.fromEntries(['description', 'keywords', 'marketingUrl', 'promotionalText', 'supportUrl', 'whatsNew'].map(k => [k, m[k]])) } });
    const review = (await api('GET', `/v1/appStoreVersions/${version.id}/appStoreReviewDetail`)).data;
    await api('PATCH', `/v1/appStoreReviewDetails/${review.id}`, { data: { type: 'appStoreReviewDetails', id: review.id,
      attributes: { notes: m.reviewNotes, demoAccountRequired: false } } });
    await api('PATCH', `/v2/inAppPurchases/${product.id}`, { data: { type: 'inAppPurchases', id: product.id,
      attributes: { reviewNote: m.reviewNotes } } });
  }
  report.screenshots = [];
  for (const set of await all(`/v1/appStoreVersionLocalizations/${locale.id}/appScreenshotSets?limit=200`)) {
    const images = await all(`/v1/appScreenshotSets/${set.id}/appScreenshots?limit=200`);
    report.screenshots.push({ id: set.id, type: set.attributes.screenshotDisplayType,
      images: images.map(x => ({ id: x.id, state: x.attributes.assetDeliveryState?.state })) });
  }
  const builds = await all(`/v1/builds?filter[app]=${APP_ID}&filter[version]=${m.build}&include=preReleaseVersion&limit=200`);
  let build;
  for (const candidate of builds) {
    const prerelease = (await api('GET', `/v1/builds/${candidate.id}/preReleaseVersion`)).data;
    if (prerelease.attributes.version === m.version) build = candidate;
  }
  report.buildID = build?.id ?? null;
  report.processingState = build?.attributes.processingState ?? null;
  if (build?.attributes.processingState === 'VALID' && build.attributes.buildAudienceType === 'APP_STORE_ELIGIBLE' && apply) {
    await editable(version);
    await api('PATCH', `/v1/appStoreVersions/${version.id}/relationships/build`, { data: { type: 'builds', id: build.id } });
  }
  report.selectedBuildID = (await api('GET', `/v1/appStoreVersions/${version.id}/build`)).data?.id ?? null;
  if (stage) {
    if (!build || report.selectedBuildID !== build.id || build.attributes.processingState !== 'VALID' || build.attributes.buildAudienceType !== 'APP_STORE_ELIGIBLE')
      throw new Error('A selected VALID App Store eligible build 11 is required before staging');
    for (const type of ['APP_IPHONE_61', 'IMESSAGE_APP_IPHONE_61', 'APP_IPAD_PRO_3GEN_129', 'IMESSAGE_APP_IPAD_PRO_3GEN_129'])
      if (!report.screenshots.some(s => s.type === type && s.images.length === 4 && s.images.every(x => x.state === 'COMPLETE')))
        throw new Error(`Inherited screenshots not ready: ${type}`);
    const image = (await api('GET', `/v2/inAppPurchases/${product.id}/appStoreReviewScreenshot`)).data;
    if (image.attributes.assetDeliveryState?.state !== 'COMPLETE') throw new Error('IAP review image not ready');
    const submissions = await all(`/v1/apps/${APP_ID}/reviewSubmissions?limit=200`);
    if (submissions.some(x => !['COMPLETE', 'READY_FOR_REVIEW'].includes(x.attributes.state))) throw new Error('Active review already exists');
    let submission = submissions.find(x => x.attributes.state === 'READY_FOR_REVIEW' && x.attributes.platform === 'IOS');
    if (!submission) submission = (await api('POST', '/v1/reviewSubmissions', { data: { type: 'reviewSubmissions', attributes: { platform: 'IOS' },
      relationships: { app: { data: { type: 'apps', id: APP_ID } } } } })).data;
    report.submissionID = submission.id;
    await save();
    let items = await all(`/v1/reviewSubmissions/${submission.id}/items?include=appStoreVersion,inAppPurchaseVersion`);
    for (const item of items.filter(x => x.attributes.state !== 'REMOVED')) {
      const rel = item.relationships;
      if (!(rel?.appStoreVersion?.data?.id === version.id || rel?.inAppPurchaseVersion?.data?.id === IAP_VERSION))
        throw new Error('Unrelated item in existing draft; no submission attempted');
    }
    for (const [relationship, type, id] of [['appStoreVersion', 'appStoreVersions', version.id], ['inAppPurchaseVersion', 'inAppPurchaseVersions', IAP_VERSION]])
      if (!items.some(x => x.attributes.state !== 'REMOVED' && x.relationships?.[relationship]?.data?.id === id))
        await api('POST', '/v1/reviewSubmissionItems', { data: { type: 'reviewSubmissionItems', relationships: {
          reviewSubmission: { data: { type: 'reviewSubmissions', id: submission.id } }, [relationship]: { data: { type, id } } } } });
    items = await all(`/v1/reviewSubmissions/${submission.id}/items?include=appStoreVersion,inAppPurchaseVersion`);
    report.reviewItems = items.map(x => ({ id: x.id, state: x.attributes.state, appStoreVersionID: x.relationships?.appStoreVersion?.data?.id,
      inAppPurchaseVersionID: x.relationships?.inAppPurchaseVersion?.data?.id }));
    if (!report.reviewItems.some(x => x.appStoreVersionID === version.id) || !report.reviewItems.some(x => x.inAppPurchaseVersionID === IAP_VERSION))
      throw new Error('Both required review items must be present');
    const final = (await api('GET', `/v1/reviewSubmissions/${submission.id}`)).data;
    if (final.attributes.state !== 'READY_FOR_REVIEW' || final.attributes.submittedDate) throw new Error('Unexpected submitted review');
    report.submissionState = final.attributes.state;
  }
  report.appState = (await api('GET', `/v1/appStoreVersions/${version.id}`)).data.attributes.appStoreState;
  report.iapVersionState = (await api('GET', `/v1/inAppPurchaseVersions/${IAP_VERSION}`)).data.attributes.state;
  await save();
  console.log(JSON.stringify(report, null, 2));
} catch (error) { report.error = { message: error.message, details: error.details }; await save(); throw error; }
