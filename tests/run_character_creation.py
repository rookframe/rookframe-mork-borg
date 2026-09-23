"""Run the focused scene suite; Godot script errors must also fail CI."""
import argparse
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='/Applications/Godot_mono.app/Contents/MacOS/Godot')
args = parser.parse_args()
passed = True
for suite in ("character_creation", "character_inventory"):
    result = subprocess.run(
        [args.godot, '--headless', '--path', str(Path(__file__).resolve().parents[1]),
         '--script', f'tests/{suite}.gd'],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90,
    )
    print(result.stdout, end='')
    passed &= (result.returncode == 0 and f'{suite.upper()} PASS' in result.stdout
               and 'ERROR:' not in result.stdout)
raise SystemExit(0 if passed else 1)
