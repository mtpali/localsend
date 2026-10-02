"""Require completed gallery cases and expose exact native test counts in CI."""
from pathlib import Path
import json
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[2]
reports = root / "app/build/app/test-results/testReleaseUnitTest"
cases = []
for file in reports.glob("TEST-*.xml"):
    suite = ET.parse(file).getroot()
    for case in suite.findall("testcase"):
        if case.get("classname") == "org.localsend.localsend_app.GalleryMediaStoreTest":
            assert case.find("failure") is None and case.find("error") is None, case.get("name")
            assert case.find("skipped") is None, case.get("name")
            cases.append(case.get("name"))
assert len(cases) == 13, f"Expected 13 native gallery cases on SDK 28/29/34; got {len(cases)}"
summary = {"passed": len(cases), "failed": 0, "skipped": 0, "cases": cases}
output = root / "build/android-gallery-tests.json"
output.parent.mkdir(exist_ok=True)
output.write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
