#!/usr/bin/env python3
"""Capture the multilingual release UI via the integration capture APK."""
import argparse
import json
import pathlib
import subprocess
import time

ROOT = pathlib.Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--adb', default='adb')
p.add_argument('--only-imports',action='store_true')
p.add_argument('--apk', type=pathlib.Path, default=ROOT/'build/app/outputs/apk/debug/app-debug.apk')
p.add_argument('--out', type=pathlib.Path, default=ROOT/'docs/store-assets/2026-11-11')
args = p.parse_args()
package = 'com.annuo.pictools'

def adb(*cmd, binary=False):
    return subprocess.check_output([args.adb, *cmd], text=not binary)

adb('install','-r',str(args.apk))
adb('shell','run-as',package,'mkdir','-p','app_flutter/store-fixtures')
for src, name in [('coast-study.png','coast.png'),('still-life-study.png','still-life.png')]:
    adb('push',str(ROOT/'design-system/assets'/src),f'/data/local/tmp/{name}')
    adb('shell','run-as',package,'cp',f'/data/local/tmp/{name}',f'app_flutter/store-fixtures/{name}')
locales = list(json.loads((ROOT/'scripts/store/copy.json').read_text()))
try:
    for profile,size,density in [('phone','1080x1920','420'),('tablet','1920x1080','240')]:
        adb('shell','am','force-stop',package)
        adb('shell','wm','size',size)
        adb('shell','wm','density',density)
        time.sleep(3)
        adb('shell','am','start','-n',package+'/.MainActivity')
        time.sleep(2)
        pid=adb('shell','pidof',package).strip()
        deadline=time.monotonic()+300
        while time.monotonic()<deadline:
            log=adb('logcat','-d','--pid='+pid,'-s','flutter')
            if 'Some tests failed' in log:
                raise RuntimeError(log[-8000:])
            if 'All tests passed!' in log: break
            time.sleep(3)
        else: raise RuntimeError('Timed out capturing '+profile)
        kind='imports' if args.only_imports else 'capture'
        (args.out/'qa'/f'android-{profile}-{kind}.log').write_text(log)
        for locale in locales:
            out=args.out/'raw'/f'android-{profile}'/locale
            out.mkdir(parents=True,exist_ok=True)
            capture_folder='store-import-captures' if args.only_imports else 'store-captures'
            folder=f'app_flutter/{capture_folder}/{locale}'
            for file in adb('shell','run-as',package,'ls',folder).split():
                (out/('import-device.json' if args.only_imports and file=='device.json' else file)).write_bytes(adb('exec-out','run-as',package,'cat',folder+'/'+file,binary=True))
        print(f'Captured {profile}: {len(locales)} locales',flush=True)
finally:
    adb('shell','am','force-stop',package)
    adb('shell','wm','size','reset')
    adb('shell','wm','density','reset')
