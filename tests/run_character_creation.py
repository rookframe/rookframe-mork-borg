#!/usr/bin/env python3
"""Run all extension suites with pinned GdUnit4 and retain JUnit/HTML reports."""
import argparse
from pathlib import Path
import subprocess
import uuid
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default="/Applications/Godot_mono.app/Contents/MacOS/Godot")
args = parser.parse_args()
project = Path(__file__).resolve().parents[1]
runner = project / "addons/gdUnit4/bin/GdUnitCmdTool.gd"
if not runner.is_file() or 'version="6.2.1"' not in (project / "addons/gdUnit4/plugin.cfg").read_text():
    parser.error("Install pinned development dependencies with: godot --headless --script plug.gd install")
subprocess.run([args.godot, "--headless", "--editor", "--recovery-mode", "--path", str(project), "--import"],
               check=True, timeout=90)
report = "reports/" + uuid.uuid4().hex
(project / report).mkdir(parents=True)
(project / "reports/.gdignore").touch()
result = subprocess.run([args.godot, "--headless", "--path", str(project),
    "--script", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd", "--ignoreHeadlessMode",
    "-a", "res://tests", "-c", "-rd", report], timeout=180)
if result.returncode:
    raise SystemExit(result.returncode)
reports = list((project / report).glob("report_*/results.xml"))
if len(reports) != 1:
    raise SystemExit("GdUnit4 produced no unique fresh JUnit report")
root = ET.parse(reports[0]).getroot()
cases = root.findall(".//testcase")
if not cases or any(int(suite.get(key, "0")) for suite in root.iter("testsuite")
                    for key in ("errors", "failures", "skipped", "flaky")) or any(
        case.find(tag) is not None for case in cases for tag in ("error", "failure", "skipped")):
    raise SystemExit("GdUnit4 did not pass every discovered test")
print(f"{len(cases)} cases passed; {reports[0]}")
