#!/usr/bin/env python3
"""Generate density-specific Android icons by fitting the entire supplied PNG."""
from pathlib import Path
from PIL import Image, ImageOps
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
res = root / "app/android/app/src/main/res"
source = Image.open(args.source).convert("RGBA")

def fit(side, scale=1.0, transparent=False):
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0 if transparent else 255))
    image = ImageOps.contain(source, (round(side * scale), round(side * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(image, ((side - image.width) // 2, (side - image.height) // 2))
    return canvas

for density, factor in [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2), ("xxhdpi", 3), ("xxxhdpi", 4)]:
    folder = res / ("mipmap-" + density)
    folder.mkdir(parents=True, exist_ok=True)
    legacy = fit(round(48 * factor), 0.975)
    legacy.save(folder / "ic_launcher.png", optimize=True)
    legacy.save(folder / "ic_launcher_round.png", optimize=True)
    # Android displays only the middle 72dp of a 108dp adaptive layer.
    # Match the 48dp legacy icon's apparent size and leave ample black padding.
    foreground = fit(round(108 * factor), 0.65)
    foreground.save(folder / "ic_launcher_foreground.png", optimize=True)
    alpha = foreground.convert("L")
    mono = Image.new("RGBA", foreground.size, (255, 255, 255, 0))
    mono.putalpha(alpha)
    mono.save(folder / "ic_launcher_monochrome.png", optimize=True)
    quick = fit(round(24 * factor))
    white = Image.new("RGBA", quick.size, (255, 255, 255, 0))
    white.putalpha(quick.convert("L"))
    white.save(folder / "ic_launcher_quicktile_foreground.png", optimize=True)
print("Generated uncropped launcher, adaptive, monochrome and quick tile icons.")
