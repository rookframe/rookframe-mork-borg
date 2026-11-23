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
import sys
import tempfile
import uuid
import xml.etree.ElementTree as ET

THEMES = ["silkbound-ledger", "fantasy", "cyberpunk"]

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default="/Applications/Godot_mono.app/Contents/MacOS/Godot")
parser.add_argument("--graphical", action="store_true", help="Run the tests with a Godot display.")
parser.add_argument("--theme", action="append", choices=THEMES,
                    help="World theme to mount Package surfaces under; repeat for several. Default: every theme.")
parser.add_argument("--development-plugin", type=Path,
                    help="Standalone Development Plugin addon directory with the Package data compiler.")
parser.add_argument("--report-dir", type=Path,
                    default=Path(tempfile.gettempdir()) / "rookframe-mork-borg-reports")
parser.add_argument("--suite", action="append",
                    help="A test suite filename, such as character_creation.gd. Default: every suite.")
args = parser.parse_args()
project = Path(__file__).resolve().parents[1]
runner = project / "addons/gdUnit4/bin/GdUnitCmdTool.gd"
if not runner.is_file() or 'version="6.2.1"' not in (project / "addons/gdUnit4/plugin.cfg").read_text():
    parser.error("Install pinned development dependencies with: godot --headless --script plug.gd install")
plugin = (args.development_plugin or project / "addons/rookframe_development").resolve()
if not (plugin / "rookframe_package_data.py").is_file():
    parser.error("Select the standalone Development Plugin addon with --development-plugin.")
sys.path.insert(0, str(plugin))
from rookframe_package_data import compile_data, package_root, runtime_sources

subprocess.run([args.godot, "--headless", "--editor", "--recovery-mode", "--path", str(project), "--import"],
               check=True, timeout=90)
report_root = args.report_dir.resolve()
engine = subprocess.check_output([args.godot, "--version"], text=True, timeout=30).strip()
source = package_root(project, "0404eb56-ef27-4b1a-8385-27e4e3ec907e")
themed = sorted("res://tests/" + suite.name for suite in (project / "tests").glob("*.gd")
                if "res://tests/world_theme.gd" in suite.read_text(encoding="utf-8"))
selected = ["res://tests/" + suite for suite in args.suite] if args.suite else ["res://tests"]
if args.suite:
    if any(Path(name).name != name or not (project / "tests" / name).is_file()
           for name in args.suite):
        parser.error("Use the filename of an existing GDScript test suite.")
    themed = [suite for suite in themed if suite in selected]


def run(theme: str, suites: list[str], data: Path) -> tuple[int, list[str], Path]:
    report = report_root / uuid.uuid4().hex
    report.mkdir(parents=True)
    report_argument = report.as_posix() if os.name == "nt" else os.path.relpath(report, project)
    selection = [part for suite in suites for part in ("-a", suite)]
    display = [] if args.graphical else ["--headless", "--ignoreHeadlessMode"]
    result = subprocess.run([args.godot, "--path", str(project),
        "--script", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd", *display,
        *selection, "-c", "-rd", report_argument], timeout=600, cwd=project,
        env={**os.environ, "ROOKFRAME_WORLD_THEME": theme, "ROOKFRAME_TEST_PACKAGE_DATA": str(data)})
    reports = list(report.glob("report_*/results.xml"))
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
with tempfile.TemporaryDirectory(prefix="rookframe-test-package-data-") as folder:
    data = Path(folder)
    compile_data(Path(args.godot), engine, runtime_sources(source), data)
    for index, theme in enumerate(args.theme or THEMES):
        suites = selected if index == 0 else themed
        if suites:
            results.append((theme, *run(theme, suites, data)))
for theme, cases, failed, report in results:
    print(f"{theme}: {cases - len(failed)} of {cases} cases passed; {report}")
    for case in failed:
        print(f"  failed: {case}")
if any(failed for _, _, failed, _ in results):
    raise SystemExit("GdUnit4 did not pass every discovered test")
