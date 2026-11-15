#!/usr/bin/env python3
"""Run all extension suites with pinned GdUnit4 and retain JUnit/HTML reports.

Suites that mount Package surfaces through tests/world_theme.gd run once per UI
Kit theme. The first selected theme also runs every other suite, so rules and
theme-independent suites run once.
"""
import argparse
import os
from pathlib import Path
import subprocess
import uuid
import xml.etree.ElementTree as ET

THEMES = ["silkbound-ledger", "fantasy", "cyberpunk"]

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default="/Applications/Godot_mono.app/Contents/MacOS/Godot")
parser.add_argument("--theme", action="append", choices=THEMES,
                    help="World theme to mount Package surfaces under; repeat for several. Default: every theme.")
args = parser.parse_args()
project = Path(__file__).resolve().parents[1]
runner = project / "addons/gdUnit4/bin/GdUnitCmdTool.gd"
if not runner.is_file() or 'version="6.2.1"' not in (project / "addons/gdUnit4/plugin.cfg").read_text():
    parser.error("Install pinned development dependencies with: godot --headless --script plug.gd install")
subprocess.run([args.godot, "--headless", "--editor", "--recovery-mode", "--path", str(project), "--import"],
               check=True, timeout=90)
(project / "reports").mkdir(exist_ok=True)
(project / "reports/.gdignore").touch()
themed = sorted("res://tests/" + suite.name for suite in (project / "tests").glob("*.gd")
                if "res://tests/world_theme.gd" in suite.read_text())


def run(theme: str, suites: list[str]) -> tuple[int, list[str], Path]:
    report = "reports/" + uuid.uuid4().hex
    (project / report).mkdir(parents=True)
    selection = [part for suite in suites for part in ("-a", suite)]
    result = subprocess.run([args.godot, "--headless", "--path", str(project),
        "--script", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd", "--ignoreHeadlessMode",
        *selection, "-c", "-rd", report], timeout=600, env={**os.environ, "ROOKFRAME_WORLD_THEME": theme})
    reports = list((project / report).glob("report_*/results.xml"))
    if len(reports) != 1:
        raise SystemExit("GdUnit4 produced no unique fresh JUnit report")
    root = ET.parse(reports[0]).getroot()
    cases = [(suite.get("name"), case) for suite in root.iter("testsuite") for case in suite.findall("testcase")]
    failed = [f"{suite} > {case.get('name')}" for suite, case in cases
              if any(case.find(tag) is not None for tag in ("error", "failure", "skipped"))]
    if not cases or (result.returncode and not failed):
        failed.append(f"GdUnit4 exited with {result.returncode}")
    return len(cases), failed, reports[0]


results = []
for index, theme in enumerate(args.theme or THEMES):
    results.append((theme, *run(theme, ["res://tests"] if index == 0 else themed)))
for theme, cases, failed, report in results:
    print(f"{theme}: {cases - len(failed)} of {cases} cases passed; {report}")
    for case in failed:
        print(f"  failed: {case}")
if any(failed for _, _, failed, _ in results):
    raise SystemExit("GdUnit4 did not pass every discovered test")
