#!/usr/bin/env node
// Applies the owner's recorded 175-territory approval only. Never submits review.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {api,all,APP_ID} from './appstore-connect.mjs';
const flags=new Set(process.argv.slice(2));
if([...flags].some(x=>x!=='--apply'))throw new Error('Unknown option');
const apply=flags.has('--apply');
const path=new URL('../release/studio-1.4/availability-plan.json',import.meta.url);
const plan=JSON.parse(await readFile(path,'utf8'));
const ids=[...new Set(plan.proposedTerritories)].sort();
if(plan.appId!==APP_ID||plan.productId!=='6827336076'||ids.length!==175||plan.availableInNewTerritories!==false||plan.ownerApproval?.granted!==true)throw new Error('Exact recorded owner approval is required');
const product=(await api('GET',`/v2/inAppPurchases/${plan.productId}`)).data;
if(product.attributes.productId!=='eu.armand.bitart.studio.unlock'||product.attributes.inAppPurchaseType!=='NON_CONSUMABLE'||product.attributes.familySharable)throw new Error('Product identity/type/Family Sharing differs');
const app=(await api('GET',`/v1/apps/${APP_ID}`)).data;
if(app.attributes.bundleId!=='eu.armand.--bit-art')throw new Error('Unexpected app');
const appAvailability=(await api('GET',`/v1/apps/${APP_ID}/appAvailabilityV2`)).data;
const live=(await all(`/v2/appAvailabilities/${appAvailability.id}/territoryAvailabilities?include=territory&limit=200`)).filter(x=>x.attributes.available).map(x=>x.relationships.territory.data.id).sort();
if(JSON.stringify(live)!==JSON.stringify(ids))throw new Error('Live app territories differ from the approved proposal; no automatic expansion');
const price=await api('GET',`/v1/inAppPurchasePriceSchedules/${product.id}/manualPrices?include=inAppPurchasePricePoint,territory&filter[territory]=USA`);
if(!price.included.some(x=>x.type==='inAppPurchasePricePoints'&&Number(x.attributes.customerPrice)===1))throw new Error('USA price is not the verified $1.00');
let availability;
try{availability=(await api('GET',`/v2/inAppPurchases/${product.id}/inAppPurchaseAvailability`)).data;}catch(e){if(e.status!==404)throw e;}
let created=false;
if(!availability&&apply){
 availability=(await api('POST','/v1/inAppPurchaseAvailabilities',{data:{type:'inAppPurchaseAvailabilities',attributes:{availableInNewTerritories:false},relationships:{inAppPurchase:{data:{type:'inAppPurchases',id:product.id}},availableTerritories:{data:ids.map(id=>({type:'territories',id}))}}}})).data;
 created=true;
}
let actual=[];
if(availability){
 const a=(await api('GET',`/v2/inAppPurchases/${product.id}/inAppPurchaseAvailability`)).data;
 actual=(await all(`/v1/inAppPurchaseAvailabilities/${a.id}/availableTerritories?limit=200`)).map(x=>x.id).sort();
 if(a.attributes.availableInNewTerritories!==false||JSON.stringify(actual)!==JSON.stringify(ids))throw new Error('Saved availability differs from the approved exact list');
 availability=a;
}
const report={verifiedAtUTC:new Date().toISOString(),appId:APP_ID,productId:product.id,apply,created,availabilityId:availability?.id??null,territoryCount:actual.length,expectedTerritoryCount:175,exactMatch:JSON.stringify(actual)===JSON.stringify(ids),availableInNewTerritories:availability?.attributes.availableInNewTerritories??false,usaPrice:'1.00',reviewSubmitted:false};
await mkdir('build/studio-release',{recursive:true});
await writeFile('build/studio-release/availability-readback.json',JSON.stringify({report,availability,territories:actual,price},null,2));
if(apply){
 if(!report.exactMatch)throw new Error('Availability was not applied');
 plan.applied=true;plan.requiresOwnerApproval=false;plan.availabilityId=availability.id;plan.verifiedAtUTC=report.verifiedAtUTC;plan.appliedTerritoryCount=actual.length;
 await writeFile(path,JSON.stringify(plan,null,2)+'\n');
}
console.log(JSON.stringify(report,null,2));
