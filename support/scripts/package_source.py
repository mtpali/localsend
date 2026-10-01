from pathlib import Path
import subprocess
import zipfile

root = Path(__file__).resolve().parents[2]
paths = subprocess.check_output(["git", "ls-files"], cwd=root).decode().splitlines()
output = root / "build/LocalSend-OLED-source.zip"
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    for name in paths:
        file = root / name
        if file.is_file():
            archive.write(file, name)
    # Build generators may add new output files.
    tracked = set(paths)
    for folder in ["app/lib/gen", "app/test", "packages/localsend_isolates/lib"]:
        for file in (root / folder).rglob("*.dart"):
            name = str(file.relative_to(root))
            if name not in tracked:
                archive.write(file, name)
print(output)
