"""Contact sheet of every app icon (default + one per theme), light and dark,
at 180 px and 60 px, to judge legibility and balance by eye.

Run from mobile/:  python tool/app_icon/contact_sheet.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

import make_app_icon as icons

OUT = Path(__file__).resolve().parent / "preview" / "contact_sheet.png"
SIZES = (180, 60)
PAD = 24
LABEL_W = 150


def rounded(image: Image.Image, size: int) -> Image.Image:
    icon = image.resize((size, size), Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size * 4 - 1, size * 4 - 1), radius=size * 4 * 0.225, fill=255)
    icon.putalpha(mask.resize((size, size), Image.Resampling.LANCZOS))
    return icon


def rows() -> list[tuple[str, Image.Image, Image.Image]]:
    default = (icons.render_square(icons.GRID, icons.DEFAULT), icons.render_square(icons.GRID, icons.DARK))
    result = [("default", *default)]
    for theme in icons.load_themes():
        light, dark, _ = icons.theme_palettes(str(theme["accent"]), str(theme["id"]))
        glyph = str(theme["glyph"])
        result.append((str(theme["id"]), icons.render_themed_square(glyph, light), icons.render_themed_square(glyph, dark)))
    return result


def main() -> None:
    data = rows()
    cell_row = max(SIZES) + PAD
    width = LABEL_W + PAD + (SIZES[0] + PAD) * 2 + (SIZES[1] + PAD) * 2
    sheet = Image.new("RGB", (width, PAD + cell_row * len(data)), (214, 214, 220))
    draw = ImageDraw.Draw(sheet)
    for index, (name, light, dark) in enumerate(data):
        y = PAD + index * cell_row
        draw.text((PAD, y + SIZES[0] // 2), name, fill=(20, 20, 24))
        x = LABEL_W + PAD
        for size in SIZES:
            for image in (light, dark):
                icon = rounded(image, size)
                sheet.paste(icon, (x, y + (SIZES[0] - size) // 2), icon)
                x += size + PAD
    OUT.parent.mkdir(exist_ok=True)
    sheet.save(OUT, optimize=True)


if __name__ == "__main__":
    main()
