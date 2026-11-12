#!/usr/bin/env python3
"""Create editable, brand-specific store artwork from native app captures.

Uses UI Design Crafter's composer for the asset/manifest contract, then renders
the custom HTML with render.mjs. No app controls or processing results are drawn
by this script. Only system-bar margins are trimmed from the original captures.
"""
import argparse
import datetime
import html
import json
import pathlib
import subprocess
import sys
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SKILL = pathlib.Path.home() / '.codex/skills/ui-design-crafter'
APPLE = 'https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications'
GOOGLE = 'https://support.google.com/googleplay/android-developer/answer/9866151'
SCREENS = [
    ('crop', '每一张，\n都刚刚好', '裁剪 · 对比 · 提亮 · 转换',
     'Pictools 裁剪界面展示海岸照片，可选择比例并拖动裁剪框，底部提供导出图片操作。', '#C84725', '#FFFFFF', '#FFE3D6'),
    ('compare', '差别，\n一眼看清', '滑块 · 并排 · 叠加',
     '图片对比界面，用滑块查看同一张海岸照片处理前后的差异，并可切换并排和叠加模式。', '#F2EFE6', '#202522', '#626B65'),
    ('batch', '一次选多张\n一起换格式', 'PNG、JPG、WebP 等 6 种格式',
     '格式转换界面，三张图片已转换为 JPG，提供输出格式、质量设置和保存已完成结果按钮。', '#DCE4DB', '#202522', '#4B5D50'),
    ('enhance', '让暗处，\n亮起来', '一键提亮 · 前后对照',
     '亮度增强界面，展示应用实际处理的海岸照片及原图与增强结果对照，可导出增强图片。', '#F4DFCC', '#202522', '#79634F'),
    ('resize', '想要的尺寸\n精确到像素', '锁定比例，调整宽高',
     '尺寸调整界面，海岸照片设置为宽 1200 像素，提供高度、锁定比例和导出操作。', '#F2EFE6', '#202522', '#626B65'),
    ('import', '相册、文件\n都能轻松导入', '按需要选择图片来源',
     '导入来源选择弹窗，分别提供从相册导入和从文件导入两个入口。', '#E9DDD0', '#202522', '#79634F'),
    ('export', '保存去哪\n由你决定', '相册或文件，保留原图',
     '导出图片弹窗，可设置文件名与格式，分别选择保存到相册或保存到文件，导出会生成新副本。', '#E5E9E0', '#202522', '#52604E'),
    ('dark', '白天与夜晚\n都看得舒服', '浅色 · 深色 · 跟随系统',
     '深色模式的裁剪界面，海岸照片与编辑控件在深色背景中显示，支持导出图片。', '#202B24', '#F5F5EF', '#C2CFC5'),
]

LOGO = '<svg viewBox="0 0 128 128" aria-hidden="true"><path d="M31 57V36a5 5 0 0 1 5-5h21M71 97h21a5 5 0 0 0 5-5V71" fill="none" stroke="currentColor" stroke-width="10" stroke-linecap="round"/><path d="M38 87V73l16-16 18 18 15-15v27H38Z" fill="currentColor"/><circle cx="84" cy="44" r="8" fill="currentColor"/></svg>'

def template(width, height, source_size, platform, tablet, screen, locale):
    name, caption, note, alt, bg, fg, muted = screen
    if tablet:
        x, brand_y, brand_size = 150, 83, 48
        title_y, title_size, note_y, note_size = 171, 116, 332, 45
        image_top, margin, bottom = 460, 160, 90
        caption = caption.replace('\n', '' if locale.startswith('zh') else ' ')
    elif platform == 'google-play':
        x, brand_y, brand_size = 76, 39, 34
        title_y, title_size, note_y, note_size = 111, 78, 299, 30
        image_top, margin, bottom = 391, 73, 65
    else:
        x, brand_y, brand_size = 98, 68, 45
        title_y, title_size, note_y, note_size = 195, 112, 479, 41
        image_top, margin, bottom = 636, 90, 85
    if not locale.startswith('zh'):
        note_size = round(note_size * .79)
    sw, sh = source_size
    scale = min((width - 2 * margin) / sw, (height - image_top - bottom) / sh)
    iw, ih = round(sw * scale, 2), round(sh * scale, 2)
    left = round((width - iw) / 2, 2)
    # Editorial crop marks echo the app icon without implying device hardware.
    marks = f'<i class="corner one"></i><i class="corner two"></i>'
    return f'''<!doctype html>
<html lang="{locale}"><head><meta charset="utf-8"><title>{{{{title}}}}</title>
<style>
* {{box-sizing:border-box}} html,body {{margin:0;width:{width}px;height:{height}px;overflow:hidden}}
body {{background:{bg};color:{fg};font-family:"PingFang SC","Noto Sans CJK SC",sans-serif;-webkit-font-smoothing:antialiased}}
.canvas {{position:relative;width:100%;height:100%;overflow:hidden}}
.brand {{position:absolute;left:{x}px;top:{brand_y}px;display:flex;align-items:center;gap:14px;font-family:"Helvetica Neue",sans-serif;font-size:{brand_size}px;font-weight:500;line-height:1.2}}
.brand svg {{width:{brand_size+18}px;height:{brand_size+18}px;margin-left:-11px}}
.copy {{position:absolute;left:{x}px;top:{title_y}px;right:{x}px}}
h1 {{font-size:{title_size}px;font-weight:600;line-height:1.16;letter-spacing:-1px;white-space:pre-line;margin:0}}
.note {{position:absolute;left:{x}px;top:{note_y}px;right:{x}px;margin:0;color:{muted};font-size:{note_size}px;font-weight:400;line-height:1.4}}
.shot {{position:absolute;margin:0;left:{left}px;top:{image_top}px;width:{iw}px;height:{ih}px;border-radius:{26 if tablet else 32}px;overflow:hidden;box-shadow:0 16px 36px rgba(32,37,34,.13);background:#F7F6F2;outline:2px solid rgba(32,37,34,.07)}}
.shot img {{width:100%;height:100%;display:block;object-fit:contain}}
.corner {{position:absolute;width:80px;height:80px;border-color:{fg};opacity:.18;border-style:solid;border-width:0}}
.one {{left:{max(24,left-44)}px;top:{image_top-45}px;border-top-width:3px;border-left-width:3px}}
.two {{right:{max(24,left-44)}px;bottom:{max(22,height-image_top-ih-42)}px;border-right-width:3px;border-bottom-width:3px}}
</style></head><body><main class="canvas" role="img" aria-label="{{{{aria_label}}}}">
<div class="brand">{LOGO}<span>Pictools</span></div>
<header class="copy"><h1>{html.escape(caption)}</h1></header>
<p class="note">{html.escape(note)}</p>{marks}
<figure class="shot"><img src="{{{{image_uri}}}}" alt="{{{{image_alt}}}}"></figure>
</main></body></html>'''

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=pathlib.Path, default=ROOT / 'docs/store-assets/2026-11-11')
    parser.add_argument('--pack', choices=['all','ios-phone','ios-ipad','android-phone','android-tablet'], default='all')
    args = parser.parse_args()
    base = args.root.resolve()
    timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    captures = []
    jobs = [
        ('ios-phone', 'app-store/iphone-dynamic-island-medium', 1179, 2556, 'app-store', False, 189, 102),
        ('ios-ipad', 'app-store/ipad-13', 2752, 2064, 'app-store', True, 48, 42),
        ('android-phone', 'google-play/phone', 1080, 1920, 'google-play', False, 124, 63),
        ('android-tablet', 'google-play/tablet', 1920, 1080, 'google-play', True, 0, 0),
    ]
    copies = json.loads((ROOT/'scripts/store/copy.json').read_text())
    for locale, copy in copies.items():
        for raw_name, destination, w, h, platform, tablet, top, bottom in jobs:
            if args.pack != 'all' and args.pack != raw_name:
                continue
            raw = base / 'raw' / raw_name / locale
            if not (raw / 'crop.png').exists():
                print(f'Skip missing capture set {raw_name}')
                continue
            out = base / 'upload' / locale / destination
            out.mkdir(parents=True, exist_ok=True)
            # Reordering creates new filenames; remove previous generated PNGs
            # so obsolete positions cannot be uploaded alongside the new set.
            for previous in out.glob('*.png'):
                previous.unlink()
            source_dir = base / 'source' / locale / raw_name
            source_dir.mkdir(parents=True, exist_ok=True)
            output_rows = []
            overrides = copy.get('platform_overrides', {}).get(platform, {})
            localized = []
            for index, original in enumerate(SCREENS):
                title, note, alt = copy['screens'][index]
                override = overrides.get(original[0], {})
                localized.append((original[0], override.get('caption', title),
                    override.get('subtitle', note), override.get('alt_text', alt), *original[4:]))
            order = ['batch','crop','compare','resize','enhance','import','export','dark'] if platform == 'google-play' else [s[0] for s in SCREENS]
            selected = sorted([s for s in localized if not tablet or s[0] in ['crop','compare','batch','export']], key=lambda s: order.index(s[0]))
            device = json.loads((raw/'device.json').read_text()) if (raw/'device.json').exists() else {}
            for i, screen in enumerate(selected,1):
                name, caption, note, alt, bg, fg, muted = screen
                source = raw / f'{name}.png'
                im = Image.open(source).convert('RGB')
                original_size = im.size
                if top or bottom:
                    im = im.crop((0, top, im.width, im.height-bottom))
                prepared = source_dir / f'{name}-content.png'
                im.save(prepared)
                row = {
                    'id':f'{raw_name}-{locale}-{name}', 'path':str(source.relative_to(base)),
                    'source':'ios-mac-xcode' if platform=='app-store' else 'android-emulator',
                    'screen_name':name, 'platform':'ios' if platform=='app-store' else 'android',
                    'device':raw_name, 'viewport':{'width':original_size[0], 'height':original_size[1],
                        'pixelRatio': device.get('pixelRatio')},
                    'orientation':'landscape' if tablet else 'portrait',
                    'locale':locale, 'theme':'dark' if name=='dark' else 'light',
                    'timestamp':device.get('timestamp',timestamp),
                    'status_bar':'native app-window capture; blank system margin excluded in composition',
                    'composition_crop':{'top':top,'bottom':bottom},
                    'notes':'Production PictoolsApp; native codecs and processing. Test seeds local fixtures only.'}
                captures.append(row)
                tpl = source_dir / f'{name}.template.html'
                tpl.write_text(template(w,h,im.size,platform,tablet,screen,locale))
                scratch = source_dir / f'{i:02d}-{name}'
                raw_compliant = tablet and platform == 'google-play'
                cmd = [sys.executable, str(SKILL/'scripts/export_store_screenshots.py'),
                    '--input',str(source if raw_compliant else prepared), '--out',str(scratch),
                    '--width',str(w),'--height',str(h),'--platform',platform,
                    '--device',raw_name,'--orientation','landscape' if tablet else 'portrait',
                    '--locale',locale,'--caption','' if raw_compliant else caption,
                    '--alt-text',alt,'--style','no-caption/raw-compliant' if raw_compliant else 'top-caption',
                    '--bg',bg,'--fg',fg,'--muted',muted,
                    '--render','pillow' if raw_compliant else 'html-only']
                if not raw_compliant:
                    cmd += ['--template',str(tpl)]
                subprocess.run(cmd,check=True,capture_output=True,text=True)
                manifest = json.loads((scratch/'manifest.store.json').read_text())
                item = manifest['outputs'][0]
                rendered_path = item['png_path']
                html_file = pathlib.Path(item['html_path'])
                html_target = source_dir / f'{i:02d}-{name}.html'
                html_target.write_text(html_file.read_text().replace(prepared.as_uri(), prepared.name))
                item.update(id=f'{i:02d}-{name}', screen_name=name,
                    html_path=str(html_target),png_path=str(out/f'{i:02d}-{name}.png'),
                    source=row['source'],source_path=str(source),source_capture_id=row['id'],
                    source_crop=row['composition_crop'],subtitle=note,
                    caption_area_percent=0 if raw_compliant else (14 if tablet else 18.5),
                    status='png-ready' if raw_compliant else 'html-ready',
                    render_status='rendered' if raw_compliant else 'not-rendered')
                if raw_compliant:
                    Image.open(pathlib.Path(rendered_path)).convert('RGB').save(item['png_path'])
                output_rows.append(item)
            result = {'version':1,'created_at':timestamp,'generator':'scripts/store/compose.py + UI Design Crafter',
                'target':{'platform':platform,'device_group':raw_name,'width':w,'height':h,
                    'orientation':'landscape' if tablet else 'portrait','locale':locale,
                    'source_url':APPLE if platform=='app-store' else GOOGLE,'last_checked':'2026-11-11'},
                'outputs':output_rows}
            (out/'manifest.store.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
            print(f'Prepared {len(output_rows)} {raw_name} {locale} compositions')
    raw_manifest = base/'manifest.raw.json'
    existing=json.loads(raw_manifest.read_text()).get('captures',[]) if raw_manifest.exists() else []
    replaced={c['id'] for c in captures}
    captures=[c for c in existing if c['id'] not in replaced]+captures
    raw_manifest.write_text(json.dumps({'version':1,'created_at':timestamp,'project':'Pictools',
        'target_store':['app-store','google-play'],'captures':captures},ensure_ascii=False,indent=2))

if __name__=='__main__': main()
