#!/usr/bin/env node
// Prepares editable Studio metadata/IAP only. Never submits a review or releases.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {api,all,APP_ID} from './appstore-connect.mjs';
const apply=process.argv.includes('--apply');
const m=JSON.parse(await readFile(new URL('../Config/StudioAppStoreMetadata.json',import.meta.url),'utf8'));
if(m.appId!==APP_ID||m.version!=='1.4'||m.build!=='10'||!m.preparationOnly)throw new Error('Unexpected Studio release identity');
for(const[k,max]of Object.entries({name:30,subtitle:30,promotionalText:170,keywords:100,description:4000,whatsNew:4000,reviewNotes:4000}))if(m[k].length>max)throw new Error(`Metadata ${k} exceeds ${max}`);
const catalog=JSON.parse(await readFile(new URL('../NativeStudio/Resources/NativeCatalog.json',import.meta.url),'utf8'));
if(catalog.length!==67||catalog.filter(x=>'template'in x).length!==45||catalog.some(x=>/wine/i.test(x.id)))throw new Error('Studio art manifest mismatch');
const versions=await all(`/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200`);
const version=versions.find(x=>x.attributes.versionString===m.version);
if(!version||version.attributes.appStoreState!=='PREPARE_FOR_SUBMISSION')throw new Error('An editable unsubmitted Studio1.4 draft is required');
const locales=await all(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`);
const locale=locales.find(x=>x.attributes.locale===m.locale);
const infos=await all(`/v1/apps/${APP_ID}/appInfos?limit=50`);
const info=infos.find(x=>x.attributes.appStoreState==='PREPARE_FOR_SUBMISSION');
if(!locale||!info)throw new Error('Editable locale/appInfo missing');
const infoLocale=(await all(`/v1/appInfos/${info.id}/appInfoLocalizations`)).find(x=>x.attributes.locale===m.locale);
const review=(await api('GET',`/v1/appStoreVersions/${version.id}/appStoreReviewDetail`)).data;
const product=(await api('GET',`/v2/inAppPurchases/${m.commerce.appleId}`)).data;
if(product.attributes.productId!==m.commerce.productId||product.attributes.inAppPurchaseType!=='NON_CONSUMABLE')throw new Error('Registered IAP mismatch');
const prices=await api('GET',`/v1/inAppPurchasePriceSchedules/${product.id}/manualPrices?include=inAppPurchasePricePoint,territory&filter[territory]=USA`);
if(!prices.included.some(x=>x.type==='inAppPurchasePricePoints'&&x.id===m.commerce.usaPricePointId&&Number(x.attributes.customerPrice)===1))throw new Error('ExactUS$1 schedule differs');
const availability=(await api('GET',`/v1/apps/${APP_ID}/appAvailabilityV2`)).data;
const territories=await all(`/v2/appAvailabilities/${availability.id}/territoryAvailabilities?include=territory&limit=200`);
const available=territories.filter(x=>x.attributes.available).map(x=>x.relationships.territory.data.id).sort();
await mkdir('release/studio-1.4',{recursive:true});
await writeFile('release/studio-1.4/availability-plan.json',JSON.stringify({appId:APP_ID,productId:product.id,proposedTerritories:available,territoryCount:available.length,source:'Existing app availability',availableInNewTerritories:false,applied:false,requiresOwnerApproval:true},null,2)+'\n');
const report={appId:APP_ID,version:m.version,build:m.build,versionId:version.id,localeId:locale.id,appInfoId:info.id,productId:product.id,releaseType:m.releaseType,proposedTerritoryCount:available.length,availabilityChangesApplied:false,apply,reviewSubmitted:false};
if(apply){
 await api('PATCH',`/v1/appStoreVersions/${version.id}`,{data:{type:'appStoreVersions',id:version.id,attributes:{copyright:m.copyright,releaseType:m.releaseType}}});
 await api('PATCH',`/v1/appStoreVersionLocalizations/${locale.id}`,{data:{type:'appStoreVersionLocalizations',id:locale.id,attributes:Object.fromEntries(['description','keywords','marketingUrl','promotionalText','supportUrl','whatsNew'].map(k=>[k,m[k]]))}});
 await api('PATCH',`/v1/appInfoLocalizations/${infoLocale.id}`,{data:{type:'appInfoLocalizations',id:infoLocale.id,attributes:{name:m.name,subtitle:m.subtitle,privacyPolicyUrl:m.privacyPolicyUrl}}});
 await api('PATCH',`/v1/appStoreReviewDetails/${review.id}`,{data:{type:'appStoreReviewDetails',id:review.id,attributes:{notes:m.reviewNotes,demoAccountRequired:false}}});
 await api('PATCH',`/v2/inAppPurchases/${product.id}`,{data:{type:'inAppPurchases',id:product.id,attributes:{reviewNote:m.reviewNotes}}});
 // Sales availability is deliberately unchanged; it requires separate owner approval.
 await mkdir('build/studio-release',{recursive:true});
 const readback={...report,verifiedAtUTC:new Date().toISOString(),version:await api('GET',`/v1/appStoreVersions/${version.id}`),locale:await api('GET',`/v1/appStoreVersionLocalizations/${locale.id}`),iap:await api('GET',`/v2/inAppPurchases/${product.id}`),availabilityChangesApplied:false};
 await writeFile('build/studio-release/prepared-metadata-readback.json',JSON.stringify(readback,null,2));
}
console.log(JSON.stringify(report,null,2));
