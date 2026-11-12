#!/usr/bin/env python3
"""Validate, index and package the multilingual store deliverables."""
import csv
import hashlib
import io
import json
import pathlib
import subprocess
import sys
import zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT=pathlib.Path(__file__).resolve().parents[2]
BASE=ROOT/'docs/store-assets/2026-11-11'
UPLOAD=BASE/'upload'
SKILL=pathlib.Path.home()/'.codex/skills/ui-design-crafter'
COPY=json.loads((ROOT/'scripts/store/copy.json').read_text())
LANGUAGES={'zh-CN':'简体中文','zh-TW':'繁體中文','en-US':'English','es-ES':'Español','fr-FR':'Français','de-DE':'Deutsch'}
FONT='/System/Library/AssetsV2/com_apple_MobileAsset_Font8/86ba2c91f017a3749571a82f2c6d890ac7ffb2fb.asset/AssetData/PingFang.ttc'
rows=[];checks=[];gallery=[]
feature_checked=False
for path in sorted(UPLOAD.rglob('manifest.store.json')):
    m=json.loads(path.read_text());t=m['target'];outputs=m['outputs']
    expected=1 if t['device_group']=='feature graphic' else 4 if 'ipad' in t['device_group'] or 'tablet' in t['device_group'] else 8
    assert len(outputs)==expected,(path,len(outputs))
    report=BASE/'qa'/('-'.join(path.relative_to(UPLOAD).parts[:-1])+'.json')
    cmd=[sys.executable,str(SKILL/'scripts/check_store_assets.py'),'--manifest',str(path),
        '--platform',t['platform'],'--width',str(t['width']),'--height',str(t['height']),
        '--min-count',str(expected),'--strict','--json','--out',str(report)]
    if t['platform']=='google-play': cmd.append('--require-alt-text')
    is_feature=t['device_group']=='feature graphic'
    if is_feature:
        # The skill checker applies a two-screenshot minimum to every Play set,
        # even a standalone feature graphic. Validate all six localized graphics
        # as one set so the real size/alpha/copy/alt checks remain fully enforced.
        report=BASE/'qa/feature-graphics-all-locales.json'
        cmd=[sys.executable,str(SKILL/'scripts/check_store_assets.py'),
            '--platform','google-play','--width','1024','--height','500',
            '--min-count','6','--strict','--require-alt-text','--json','--out',str(report)]
        for locale in COPY:
            cmd+=['--manifest',str(UPLOAD/locale/'google-play/feature/manifest.store.json')]
    if not is_feature or not feature_checked:
        result=subprocess.run(cmd,capture_output=True,text=True)
        if result.returncode:
            print(result.stdout);print(result.stderr);raise SystemExit('Store QA failed: '+str(path))
        checks.append(json.loads(report.read_text())['summary'])
        if is_feature: feature_checked=True
    for item in outputs:
        file=pathlib.Path(item['png_path']);im=Image.open(file)
        assert im.mode=='RGB',(file,im.mode)
        assert im.size==(t['width'],t['height'])
        assert len(item['alt_text'])<=140
        item['sha256']=hashlib.sha256(file.read_bytes()).hexdigest()
        relative=str(file.relative_to(BASE))
        rows.append({'locale':t['locale'],'platform':t['platform'],'device':t['device_group'],
            'order':item['id'].split('-')[0],'file':str(file.relative_to(UPLOAD)),
            'width':item['width'],'height':item['height'],
            'caption':item['caption'].replace('\n',' / '),'subtitle':item.get('subtitle',''),
            'alt_text':item['alt_text'],'sha256':item['sha256']})
        gallery.append({'locale':t['locale'],'group':t['device_group'],'path':relative,
            'caption':item['caption'],'size':f'{im.width} × {im.height}','id':item['id']})
    path.write_text(json.dumps(m,ensure_ascii=False,indent=2))
assert len(gallery)==150,len(gallery)

# Capture inventory includes all native captures, including optional home/resize
# screens not used in the 4-image tablet sequences.
captures=[]
for profile in ['ios-phone','ios-ipad','android-phone','android-tablet']:
    for locale in COPY:
        folder=BASE/'raw'/profile/locale
        d=json.loads((folder/'device.json').read_text())
        for file in sorted(folder.glob('*.png')):
            size=Image.open(file).size
            metadata=d
            if file.stem=='import' and (folder/'import-device.json').exists():
                metadata=json.loads((folder/'import-device.json').read_text())
            captures.append({'id':f'{profile}-{locale}-{file.stem}',
              'path':str(file.relative_to(BASE)), 'source':'ios-mac-xcode' if profile.startswith('ios') else 'android-emulator',
              'screen_name':file.stem,'platform':d['platform'],'device':profile,
              'viewport':{'width':size[0],'height':size[1],'pixelRatio':d['pixelRatio']},
              'orientation':'portrait' if size[1]>size[0] else 'landscape',
              'locale':locale,'theme':'dark' if file.stem=='dark' else 'light','timestamp':metadata['timestamp'],
              'status_bar':'native app-window capture; no carrier or notification overlays',
              'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
(BASE/'manifest.raw.json').write_text(json.dumps({'version':1,'project':'Pictools','captures':captures},ensure_ascii=False,indent=2))
assert len(captures)==216,len(captures)

csv_path=UPLOAD/'captions-and-alt-text.csv'
with csv_path.open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
(BASE/'qa/validation-summary.json').write_text(json.dumps({'sets':len(checks),'screenshot_count':144,
    'feature_graphic_count':6,'locales':list(COPY),'raw_captures':len(captures),'reports':checks},indent=2))

def contact(paths, destination, columns, thumb_width=220, label=True):
    font=ImageFont.truetype(FONT,20)
    cell_height=round(thumb_width*2556/1179)+52
    sheet=Image.new('RGB',(columns*(thumb_width+24)+24,((len(paths)+columns-1)//columns)*cell_height+24),'#E6E4DC')
    draw=ImageDraw.Draw(sheet)
    for i,(file,title) in enumerate(paths):
        im=Image.open(file).convert('RGB');im.thumbnail((thumb_width,cell_height-52),Image.Resampling.LANCZOS)
        x=24+(i%columns)*(thumb_width+24);y=24+(i//columns)*cell_height
        if label: draw.text((x,y),title,font=font,fill='#202522')
        sheet.paste(im,(x,y+32))
    sheet.save(destination)
contact([(UPLOAD/locale/'app-store/iphone-dynamic-island-medium/01-crop.png',label) for locale,label in LANGUAGES.items()],BASE/'preview-locales.jpg',6,220)
for locale in COPY:
    paths=[(p,p.stem.split('-')[0]) for p in sorted((UPLOAD/locale/'app-store/iphone-dynamic-island-medium').glob('*.png'))]
    contact(paths,BASE/f'preview-{locale}.jpg',4,320)

# Small local gallery: no server or network required.
gallery_json=json.dumps(gallery,ensure_ascii=False)
options=''.join(f'<option value="{k}">{v}</option>' for k,v in LANGUAGES.items())
(BASE/'index.html').write_text('''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Pictools · 商店素材预览</title><style>
*{box-sizing:border-box}body{margin:0;background:#F7F6F2;color:#202522;font-family:system-ui,"PingFang SC",sans-serif;padding:36px}
header{max-width:1600px;margin:auto}h1{font-size:30px;font-weight:600;margin:0 0 12px}p{color:#626B65}
nav{display:flex;gap:12px;flex-wrap:wrap;margin:24px 0}select{font:inherit;background:white;border:1px solid #DADDD5;padding:12px;border-radius:8px}
main{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;max-width:1600px;margin:auto}figure{margin:0}img{width:100%;border-radius:8px;display:block}figcaption{font-size:14px;line-height:1.6;padding:10px 0}a{color:inherit;text-decoration:none}
</style><header><h1>Pictools · 商店素材</h1><p>6 种语言 · 原生界面采集 · 144 张截图 + 6 张横版宣传图。点击图片可查看完整尺寸。</p><nav>
<select id="locale" aria-label="语言">'''+options+'''</select><select id="group" aria-label="平台和设备">
<option value="ios-phone">App Store · iPhone</option><option value="ios-ipad">App Store · iPad</option><option value="android-phone">Google Play · 手机</option><option value="android-tablet">Google Play · 平板</option><option value="feature graphic">Google Play · 宣传图</option>
</select></nav></header><main id="gallery"></main><script>
const assets='''+gallery_json+''';const loc=document.querySelector('#locale'),group=document.querySelector('#group'),main=document.querySelector('main');
function render(){main.replaceChildren(...assets.filter(a=>a.locale===loc.value&&a.group===group.value).map(a=>{const f=document.createElement('figure'),link=document.createElement('a'),img=document.createElement('img'),c=document.createElement('figcaption');link.href=a.path;link.target='_blank';img.src=a.path;img.alt=a.caption;img.loading='lazy';link.append(img);c.textContent=a.id+' · '+a.size;f.append(link,c);return f}));}loc.onchange=group.onchange=render;render();</script></html>''')

readme=BASE/'README.md'
for platform in ['app-store','google-play','all']:
    target=BASE/f'Pictools-{platform}-6-languages.zip'
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=5) as z:
        for file in UPLOAD.rglob('*.png'):
            rel=file.relative_to(UPLOAD)
            if platform=='all' or platform in rel.parts or ('shared-icons' in rel.parts and platform in file.name):
                z.write(file,str(rel))
        metadata=io.StringIO()
        writer=csv.DictWriter(metadata,fieldnames=rows[0].keys());writer.writeheader()
        writer.writerows(r for r in rows if platform=='all' or r['platform']==platform)
        z.writestr('captions-and-alt-text.csv','\ufeff'+metadata.getvalue())
        if readme.exists():z.write(readme,'README.md')
    print(target.name,round(target.stat().st_size/1024/1024,1),'MB')
print('PASS: 144 screenshots, 6 feature graphics, 216 native source captures, 6 locales.')
