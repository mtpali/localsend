"""Retain public SDK tools and build evidence; private signing keys stay outside CI."""

import os
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(__file__).resolve().parents[2]
versions = sorted(
    (path for path in (Path(os.environ["ANDROID_HOME"]) / "build-tools").iterdir() if re.fullmatch(r"\d+\.\d+\.\d+", path.name)),
    key=lambda path: tuple(map(int, path.name.split("."))),
    reverse=True,
)
sdk = next(path for path in versions if all((path / name).is_file() for name in ["zipalign", "aapt", "lib/apksigner.jar"]))
required_tools = [sdk / "zipalign", sdk / "aapt", sdk / "lib/apksigner.jar"]
assert all(path.is_file() for path in required_tools), "Android SDK signing tools are missing"

output = root / "build/Android-signing-and-validation.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(output, "w", ZIP_DEFLATED, compresslevel=9) as archive:
    for path in required_tools + sorted((sdk / "lib64").rglob("*")):
        if path.is_file():
            archive.write(path, Path("tools") / path.relative_to(sdk))
    for pattern in [
        "build/android-gallery-tests.json",
        "build/apk-size-report.json",
        "app/build/app/test-results/testReleaseUnitTest/TEST-*.xml",
    ]:
        for path in sorted(root.glob(pattern)):
            if path.is_file():
                archive.write(path, Path("evidence") / path.relative_to(root))
print(f"Packaged public signing tools and validation evidence: {output.name} ({output.stat().st_size} bytes)")
