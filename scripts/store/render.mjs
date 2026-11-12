// Local HTML artifact renderer. No web accounts or remote UI are accessed.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {createRequire} from 'node:module';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(process.argv[2] || 'docs/store-assets/2026-11-11');
function manifests(dir) {
  return fs.readdirSync(dir, {withFileTypes:true}).flatMap(e =>
    e.isDirectory() ? manifests(path.join(dir,e.name)) :
      e.name === 'manifest.store.json' ? [path.join(dir,e.name)] : []);
}
const browser = await chromium.launch({headless:true,channel:'chrome'});
const metricsPath=path.join(root,'qa','composition-metrics.json');
const metrics=fs.existsSync(metricsPath)?JSON.parse(fs.readFileSync(metricsPath,'utf8')):[];
const active=new Set();
for (const file of manifests(path.join(root,'upload'))) {
  const manifest=JSON.parse(fs.readFileSync(file,'utf8'));
  for (const item of manifest.outputs) {
    if (item.style==='no-caption/raw-compliant') continue;
    active.add(`${manifest.target.locale}/${manifest.target.device_group}/${item.id}`);
    if (item.render_status==='rendered' && fs.existsSync(item.png_path)) continue;
    const page=await browser.newPage({viewport:{width:item.width,height:item.height},deviceScaleFactor:1});
    await page.goto(pathToFileURL(item.html_path).href);
    await page.evaluate(async()=>{await document.fonts.ready;await Promise.all([...document.images].map(i=>i.decode()));});
    // Fit deliberate localized line breaks without squeezing or distorting text.
    const fonts=await page.evaluate(()=>{
      const canvas=document.createElement('canvas'),ctx=canvas.getContext('2d');
      return [...document.querySelectorAll('h1,.note')].map(el=>{
        const s=getComputedStyle(el),base=parseFloat(s.fontSize),available=el.clientWidth;
        ctx.font=`${s.fontWeight} ${base}px ${s.fontFamily}`;
        const measured=Math.max(...el.innerText.split('\n').map(t=>ctx.measureText(t).width));
        const size=Math.min(base,Math.floor(base*available/(measured+2)));
        if(size < base*.64) throw new Error('Localized copy needs rewriting: '+el.innerText);
        el.style.fontSize=size+'px';return {text:el.innerText,size,base};
      });
    });
    const m=await page.evaluate(()=>({
      width:innerWidth,height:innerHeight,
      horizontalOverflow:document.documentElement.scrollWidth>innerWidth,
      missingImages:[...document.images].filter(i=>!i.complete||!i.naturalWidth).length,
      text:[...document.querySelectorAll('h1,.note,.brand')].map(e=>{
        const r=e.getBoundingClientRect(), s=getComputedStyle(e);return {text:e.innerText,x:r.x,y:r.y,width:r.width,height:r.height,
          clipped:(s.overflowX!=='visible'&&e.scrollWidth>e.clientWidth+1)||(s.overflowY!=='visible'&&e.scrollHeight>e.clientHeight+1),
          offscreen:r.left<0||r.right>innerWidth||r.top<0||r.bottom>innerHeight};}),
      screen:(()=>{const r=document.querySelector('.shot').getBoundingClientRect();
        return {x:r.x,y:r.y,width:r.width,height:r.height,bottom:r.bottom};})()
    }));
    if(m.missingImages || m.horizontalOverflow || m.text.some(t=>t.clipped||t.offscreen))
      throw new Error(`Visual layout check failed: ${item.id} ${JSON.stringify(m)}`);
    await page.screenshot({path:item.png_path,omitBackground:false});
    fs.writeFileSync(item.html_path,await page.content());
    item.render_status='rendered';item.status='png-ready';
    metrics.push({id:item.id,locale:manifest.target.locale,platform:manifest.target.device_group,fonts,...m});
    await page.close();
  }
  fs.writeFileSync(file,JSON.stringify(manifest,null,2));
}
await browser.close();
const distinct=new Map(metrics.map(m=>[`${m.locale}/${m.platform}/${m.id}`,m]).filter(([key])=>active.has(key)));
fs.writeFileSync(metricsPath,JSON.stringify([...distinct.values()],null,2));
console.log(`Rendered and checked ${distinct.size} composed store assets.`);
