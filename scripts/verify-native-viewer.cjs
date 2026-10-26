/* Optional local-only viewer check. Start scripts/run-native-viewer.sh first. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
(async () => {
  const browser = await chromium.launch({headless:true, channel:process.env.PLAYWRIGHT_CHANNEL || 'chrome'});
  const page = await browser.newPage({viewport:{width:1360,height:1000}});
  const errors=[];
  page.on('pageerror', e=>errors.push(e.message));
  try {
    await page.goto('http://127.0.0.1:8792/');
    await page.locator('#status[data-state="ready"]').waitFor({timeout:30000});
    assert(await page.locator('#native-screen').evaluate(el=>el.naturalWidth>1000 && el.naturalHeight>2000));
    const before=Buffer.from(await (await page.request.get('http://127.0.0.1:8792/screenshot')).body());
    const box=await page.locator('#native-screen').boundingBox();
    await page.mouse.click(box.x+box.width*.75,box.y+box.height*.17);
    await page.locator('#status[data-state="working"]').waitFor({timeout:5000});
    await page.locator('#status[data-state="ready"]').waitFor({timeout:30000});
    const after=Buffer.from(await (await page.request.get('http://127.0.0.1:8792/screenshot')).body());
    assert(!before.equals(after),'A browser tap must change the actual native screen');
    // Return to Stickers, select native search, and type through the viewer.
    await page.mouse.click(box.x+box.width*.25,box.y+box.height*.17);
    await page.locator('#status[data-state="working"]').waitFor({timeout:5000});
    await page.locator('#status[data-state="ready"]').waitFor({timeout:30000});
    await page.mouse.click(box.x+box.width*.35,box.y+box.height*.23);
    await page.locator('#status[data-state="working"]').waitFor({timeout:5000});
    await page.locator('#status[data-state="ready"]').waitFor({timeout:30000});
    await page.locator('#entry-text').fill('67');
    const typing=page.waitForResponse(r=>r.url().endsWith('/action') && r.request().postData()?.includes('"type":"text"'));
    await page.locator('#entry-submit').click();
    assert.equal((await typing).status(),200,'Typing should reach the selected native field');
    await page.locator('#status[data-state="ready"]').waitFor({timeout:30000});
    await page.screenshot({path:'build/native-viewer-desktop.png',fullPage:true});
    await page.setViewportSize({width:390,height:844});
    assert(!(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth)));
    await page.screenshot({path:'build/native-viewer-mobile.png',fullPage:true});
    const rejected=await page.request.post('http://127.0.0.1:8792/action',{headers:{Origin:'https://example.com'},data:{type:'tap',x:.5,y:.5}});
    assert.equal(rejected.status(),403);
    const invalid=await page.request.post('http://127.0.0.1:8792/action',{headers:{Origin:'http://127.0.0.1:8792'},data:{type:'tap',x:2,y:.5}});
    assert.equal(invalid.status(),400);
    assert.deepEqual(errors,[]);
    console.log('PASS: live native screenshot, browser-to-native tap and native text entry, desktop/mobile layout, origin and coordinate validation; no purchase made');
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
