#!/usr/bin/env python3
"""Produce localized Google Play feature-graphic sources and current icons."""
import html
import json
import pathlib
from PIL import Image

ROOT=pathlib.Path(__file__).resolve().parents[2]
BASE=ROOT/'docs/store-assets/2026-11-11'
copies=json.loads((ROOT/'scripts/store/copy.json').read_text())
for locale,copy in copies.items():
    source=BASE/'source'/locale/'feature'
    source.mkdir(parents=True,exist_ok=True)
    out=BASE/'upload'/locale/'google-play/feature'
    out.mkdir(parents=True,exist_ok=True)
    raw=BASE/'raw/android-phone'/locale/'crop.png'
    if not raw.exists():
        continue
    im=Image.open(raw)
    im.crop((105,278,970,879)).convert('RGB').save(source/'crop-detail.png')
    page=f'''<!doctype html><html lang="{locale}"><meta charset="utf-8"><style>
*{{box-sizing:border-box}}html,body{{margin:0;width:1024px;height:500px;overflow:hidden}}
body{{background:#C84725;color:white;font-family:"PingFang SC","Helvetica Neue",Arial,sans-serif}}
.brand{{position:absolute;left:84px;top:91px;font-size:31px;font-weight:500;line-height:1.2}}
h1{{position:absolute;left:84px;top:158px;width:423px;margin:0;font-size:58px;line-height:1.17;font-weight:600;white-space:pre-line}}
.shot{{position:absolute;left:540px;top:98px;width:403px;height:280px;margin:0;overflow:hidden;border-radius:12px;box-shadow:0 12px 24px #692b1b33}}
.shot img{{display:block;width:100%;height:100%;object-fit:contain}}
</style><body><div class="brand">Pictools</div><h1>{html.escape(copy['feature'])}</h1>
<figure class="shot"><img src="crop-detail.png" alt="{html.escape(copy['screens'][0][2],quote=True)}"></figure></body></html>'''
    path=source/'feature.html';path.write_text(page)
    manifest={'version':1,'generator':'scripts/store/feature_graphics.py',
      'target':{'platform':'google-play','device_group':'feature graphic','preset':'google-play-feature-graphic',
        'width':1024,'height':500,'orientation':'landscape','locale':locale,
        'source_url':'https://support.google.com/googleplay/android-developer/answer/9866151','last_checked':'2026-11-11'},
      'outputs':[{'id':'feature-graphic','screen_name':'crop','style':'split-caption',
        'width':1024,'height':500,'platform':'google-play','preset':'google-play-feature-graphic','locale':locale,
        'caption':copy['feature'],'alt_text':copy['screens'][0][2],'source':'android-emulator',
        'source_path':str(raw),'html_path':str(path),'png_path':str(out/'feature-graphic.png'),
        'caption_area_percent':18,'render_status':'not-rendered','status':'html-ready'}]}
    (out/'manifest.store.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
icons=BASE/'upload/shared-icons';icons.mkdir(parents=True,exist_ok=True)
icon=Image.open(ROOT/'design-system/assets/app-icon-1024.png')
icon.convert('RGB').save(icons/'app-store-1024.png')
icon.resize((512,512),Image.Resampling.LANCZOS).convert('RGBA').save(icons/'google-play-512.png')
print('Feature graphic sources and shared icons prepared.')
