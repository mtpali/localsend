from pathlib import Path
import zipfile
import json

root = Path(__file__).resolve().parents[2]
folder = root / "app/build/app/outputs/flutter-apk"
expected = {"armeabi-v7a": "app-armeabi-v7a-release.apk", "arm64-v8a": "app-arm64-v8a-release.apk"}
report = {}
for abi, filename in expected.items():
    file = folder / filename
    assert file.is_file(), filename
    with zipfile.ZipFile(file) as archive:
        names = archive.namelist()
        architectures = {name.split("/")[1] for name in names if name.startswith("lib/") and name.endswith(".so")}
        assert architectures == {abi}, architectures
        assert not any("CHANGELOG" in name for name in names)
        assert not any("logo-512" in name or "logo-256" in name or "logo-128" in name for name in names)
        assert not any("assets/i18n/" in name for name in names)
        assert any(name.endswith("/libapp.so") for name in names)
        assert any(name.endswith("/librust_lib_localsend_app.so") for name in names)
        assert all(entry.compress_type == zipfile.ZIP_DEFLATED for entry in archive.infolist() if entry.filename.endswith(".so")), "Native libraries must be compressed in standalone APKs"
    report[abi] = {"bytes": file.stat().st_size, "file": filename}
mapping = root / "app/build/app/outputs/mapping/release/mapping.txt"
assert mapping.is_file() and mapping.stat().st_size > 0, "R8 mapping was not emitted"
report_file = root / "build/apk-size-report.json"
report_file.parent.mkdir(parents=True, exist_ok=True)
report_file.write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
