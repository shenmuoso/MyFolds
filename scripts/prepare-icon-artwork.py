#!/usr/bin/env python3
"""Recover transparent, aligned artwork from the two supplied screenshots.

Requires Pillow and NumPy only for regenerating the committed PNG masters.
Normal app builds consume those masters and do not require Python packages.
"""

from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
ARTWORK = ROOT / "resources/IconArtwork"
PREVIEW = ROOT / "outputs/myfolds-icon-2026-11-22"
CANVAS = 1024
ART_WIDTH = 832


def recover_artwork(path):
    image = Image.open(path).convert("RGB")
    pixels = np.asarray(image).astype(np.float32)
    background = np.median(pixels[0], axis=0)
    difference = np.max(np.abs(pixels - background), axis=2)

    # Flood from outside. Identically colored pixels *inside* the frosted
    # folder remain part of the artwork, rather than becoming holes.
    silhouette = Image.fromarray(np.where(difference > 1, 255, 0).astype("uint8")).copy()
    ImageDraw.floodfill(silhouette, (0, 0), 128, thresh=0)
    inside = np.asarray(silhouette) != 128
    silhouette = Image.fromarray((inside * 255).astype("uint8"))
    boundary = inside & (np.asarray(silhouette.filter(ImageFilter.MinFilter(3))) == 0)

    # Estimate edge coverage from nearby pixels on the same side of the
    # screenshot matte. Remove the matte only along the exterior AA boundary.
    delta = pixels.mean(axis=2) - background.mean()
    positive = Image.fromarray(np.maximum(delta, 0).astype("float32"))
    negative = Image.fromarray(np.maximum(-delta, 0).astype("float32"))
    positive = np.asarray(positive.convert("L").filter(ImageFilter.MaxFilter(3))).astype(float)
    negative = np.asarray(negative.convert("L").filter(ImageFilter.MaxFilter(3))).astype(float)
    reference = np.where(delta >= 0, positive, negative)
    coverage = np.divide(np.abs(delta), reference, out=np.ones_like(delta), where=reference > 0)
    alpha = inside.astype(np.float32)
    alpha[boundary] = np.clip(coverage[boundary], 0, 1)
    corrected = background + (pixels - background) / np.maximum(alpha[..., None], 1 / 255)
    corrected[~inside] = 0
    rgba = np.dstack((np.clip(corrected, 0, 255), alpha * 255)).round().astype("uint8")
    cutout = Image.fromarray(rgba)
    bounds = Image.fromarray((difference > 0).astype("uint8") * 255).getbbox()
    crop = cutout.crop(bounds)
    height = round(crop.height * ART_WIDTH / crop.width)
    crop = crop.resize((ART_WIDTH, height), Image.Resampling.LANCZOS)
    result = Image.new("RGBA", (CANVAS, CANVAS))
    position = ((CANVAS - crop.width) // 2, (CANVAS - crop.height) // 2)
    result.alpha_composite(crop, position)
    return result, {"source_bounds": bounds, "artwork_size": crop.size, "position": position}


def preview(icons, *, system=False):
    board = Image.new("RGB", (1200, 780), "#f0efed")
    draw = ImageDraw.Draw(board)
    font_path = "/System/Library/Fonts/SFNS.ttf"
    title = ImageFont.truetype(font_path, 29)
    caption = ImageFont.truetype(font_path, 17)
    draw.text((48, 34), "MyFolds", fill="#282828", font=title)
    subtitle = "macOS app icons · light and dark" if system else "Screenshot artwork · aligned, transparent masters"
    draw.text((48, 77), subtitle, fill="#6c6b69", font=caption)
    for column, (name, icon) in enumerate(icons.items()):
        left = 36 + column * 582
        color = "#e2e1de" if name == "light" else "#252526"
        draw.rounded_rectangle((left, 132, left + 546, 731), radius=26, fill=color)
        text_color = "#4b4b4b" if name == "light" else "#d9d9da"
        draw.text((left + 26, 156), name.capitalize(), fill=text_color, font=caption)
        large = icon.resize((360, 360), Image.Resampling.LANCZOS)
        board.paste(large, (left + 93, 218), large)
        x = left + 125
        for size in (32, 64, 96):
            small = icon.resize((size, size), Image.Resampling.LANCZOS)
            board.paste(small, (x, 650 - size // 2), small)
            x += size + 35
    name = "MyFolds-app-icons.png" if system else "MyFolds-light-dark-preview.png"
    board.save(PREVIEW / name)


def main():
    PREVIEW.mkdir(parents=True, exist_ok=True)
    icons, measurements = {}, {}
    for name in ("light", "dark"):
        icons[name], measurements[name] = recover_artwork(ARTWORK / "source" / f"{name}-screenshot.png")
        icons[name].save(ARTWORK / f"myfolds-{name}-1024.png")
        icons[name].save(ROOT / "resources/MyFoldsFolder.icon/Assets" / f"myfolds-{name}-1024.png")
    (ARTWORK / "processing.json").write_text(json.dumps(measurements, indent=2) + "\n")
    preview(icons)
    print(json.dumps(measurements, indent=2))


if __name__ == "__main__":
    main()
