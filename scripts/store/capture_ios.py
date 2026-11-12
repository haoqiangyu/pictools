#!/usr/bin/env python3
"""Capture production Flutter UI on an installed iOS Simulator (Mac/Xcode)."""
import argparse
import json
import pathlib
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--device', required=True)
parser.add_argument('--out', type=pathlib.Path, required=True)
parser.add_argument('--flutter', default='flutter')
parser.add_argument('--landscape', action='store_true')
parser.add_argument('--only-imports', action='store_true')
args = parser.parse_args()

def run(*argv):
    return subprocess.check_output(argv, cwd=ROOT, text=True).strip()

# Bootstrap using the existing simulator build so fixture data can be installed.
run('xcrun', 'simctl', 'install', args.device,
    str(ROOT / 'build/ios/iphonesimulator/Runner.app'))
container = pathlib.Path(run('xcrun', 'simctl', 'get_app_container',
                            args.device, 'com.annuo.pictools', 'data'))
fixtures = container / 'Documents/store-fixtures'
fixtures.mkdir(parents=True, exist_ok=True)
for name, destination in [('coast-study.png', 'coast.png'),
                          ('still-life-study.png', 'still-life.png')]:
    shutil.copy2(ROOT / 'design-system/assets' / name, fixtures / destination)
command = [args.flutter, 'test', 'integration_test/store_capture_test.dart',
           '-d', args.device, '--no-uninstall', '--no-pub', '--reporter', 'expanded']
if args.landscape:
    command.append('--dart-define=STORE_LANDSCAPE=true')
if args.only_imports:
    command.append('--dart-define=STORE_ONLY_IMPORT=true')
subprocess.run(command, cwd=ROOT, check=True)
container = pathlib.Path(run('xcrun', 'simctl', 'get_app_container',
                            args.device, 'com.annuo.pictools', 'data'))
args.out.mkdir(parents=True, exist_ok=True)
capture_folder = 'store-import-captures' if args.only_imports else 'store-captures'
for path in (container / 'Documents' / capture_folder).iterdir():

    if path.is_dir():
        if args.landscape:
            device = json.loads((path / 'device.json').read_text())
            if device['width'] <= device['height']:
                raise RuntimeError('Rotate the iPad Simulator to landscape before capturing.')
        if args.only_imports:
            target=args.out / path.name;target.mkdir(parents=True,exist_ok=True)
            shutil.copy2(path/'import.png',target/'import.png')
            shutil.copy2(path/'device.json',target/'import-device.json')
        else:
            shutil.copytree(path, args.out / path.name, dirs_exist_ok=True)
    else:
        shutil.copy2(path, args.out / path.name)
print(f'Captured to {args.out}')
