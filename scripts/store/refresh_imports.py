#!/usr/bin/env python3
"""Refresh only the import artwork after its native animation-safe recapture."""
import json
import pathlib
from PIL import Image

ROOT=pathlib.Path(__file__).resolve().parents[2]
BASE=ROOT/'docs/store-assets/2026-11-11'
locales=json.loads((ROOT/'scripts/store/copy.json').read_text())
for locale in locales:
    for profile,folder,top,bottom in [
        ('ios-phone','app-store/iphone-dynamic-island-medium',189,102),
        ('android-phone','google-play/phone',124,63),
    ]:
        raw=BASE/'raw'/profile/locale
        assert (raw/'import-device.json').exists(),f'Missing retake: {raw}'
        im=Image.open(raw/'import.png').convert('RGB')
        im.crop((0,top,im.width,im.height-bottom)).save(BASE/'source'/locale/profile/'import-content.png')
        path=BASE/'upload'/locale/folder/'manifest.store.json'
        m=json.loads(path.read_text())
        for output in m['outputs']:
            if output['screen_name']=='import':
                output['render_status']='not-rendered'
                output['status']='html-ready'
                output.pop('sha256',None)
        path.write_text(json.dumps(m,ensure_ascii=False,indent=2))
print('Updated 12 localized import sources. Run render.mjs, then package.py.')
