"""Generates every MAZL app icon from one vector: the « m » of Geist 700 and
the tekhelet dot (icon track B « Le point », approved on 2026-10-24).

Nothing here depends on an installed font: the glyph outline is read from
assets/fonts/Geist-700.ttf and drawn as paths. Geometry, on a 1024 grid:
« m » at 620 px, tracking -30, centred on x = 452 (60 px left of the axis,
optical centre), baseline 690; dot r = 62 centred on (812, 638), 10 px below
the baseline (round overshoot).

Run from mobile/ with a Python that has fontTools, skia-pathops and Pillow:
    python tool/app_icon/make_app_icon.py
"""

from __future__ import annotations

import json
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

import pathops
from fontTools.pens.basePen import BasePen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from PIL import Image, ImageChops, ImageDraw

MOBILE = Path(__file__).resolve().parents[2]
FONT = MOBILE / "assets/fonts/Geist-700.ttf"
GRID = 1024
FONT_SIZE = 620
TRACKING = -30
LETTER_CENTRE_X = 452
BASELINE = 690
DOT_CENTRE = (812, 638)
DOT_RADIUS = 62
SUPERSAMPLE = 4

INK = "#0B0B0F"
WHITE = "#FFFFFF"
TEKHELET = "#2747F5"
TEKHELET_DARK = "#5B78FF"

# Android: the 1024 grid maps onto the 72 dp visible area of the 108 dp
# adaptive layer; the motif is reduced to 80 % to sit inside the 66 dp safe zone.
ADAPTIVE_LAYER_DP = 108
ADAPTIVE_VISIBLE_DP = 72
ANDROID_MOTIF_SCALE = 0.8

Point = tuple[float, float]
Transform = Callable[[Point], Point]


@dataclass(frozen=True)
class Palette:
    background: str
    letter: str
    dot: str


DEFAULT = Palette(INK, WHITE, TEKHELET)
DARK = Palette(INK, WHITE, TEKHELET_DARK)
TINTED = Palette("#1C1C22", "#A1A1AA", "#F4F4F5")


class _FlattenPen(BasePen):
    """Collects each contour as a polygon, curves flattened into segments."""

    def __init__(self, glyph_set: object, steps: int = 24) -> None:
        super().__init__(glyph_set)
        self.contours: list[list[Point]] = []
        self._current: list[Point] = []
        self._steps = steps

    def _moveTo(self, pt: Point) -> None:
        self._current = [pt]

    def _lineTo(self, pt: Point) -> None:
        self._current.append(pt)

    def _curveToOne(self, p1: Point, p2: Point, p3: Point) -> None:
        p0 = self._getCurrentPoint()
        for i in range(1, self._steps + 1):
            t = i / self._steps
            u = 1 - t
            self._current.append((
                u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1],
            ))

    def _qCurveToOne(self, p1: Point, p2: Point) -> None:
        p0 = self._getCurrentPoint()
        for i in range(1, self._steps + 1):
            t = i / self._steps
            u = 1 - t
            self._current.append((
                u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
                u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1],
            ))

    def _closePath(self) -> None:
        if self._current:
            self.contours.append(self._current)
        self._current = []

    _endPath = _closePath


def _letter_affine() -> tuple[float, float, float, float, float, float]:
    """Font units (y up) to the 1024 grid (y down), as an affine matrix."""
    font = TTFont(FONT)
    upm = font["head"].unitsPerEm
    glyph_name = font.getBestCmap()[ord("m")]
    advance = font["hmtx"][glyph_name][0]
    scale = FONT_SIZE / upm
    origin_x = LETTER_CENTRE_X - (advance * scale + TRACKING) / 2
    return (scale, 0, 0, -scale, origin_x, BASELINE)


def _draw_letter(pen: object) -> None:
    """Draws the « m », its self-overlapping contour merged into a clean outline.

    Geist ships the static weights with overlapping contours (from its variable
    source); an even-odd fill would punch notches where the shoulders meet the
    stems, so the outline is unioned first.
    """
    font = TTFont(FONT)
    outline = pathops.Path()
    font.getGlyphSet()[font.getBestCmap()[ord("m")]].draw(outline.getPen())
    outline.simplify(fix_winding=True)
    outline.draw(TransformPen(pen, _letter_affine()))


def letter_contours() -> list[list[Point]]:
    """The « m » as polygons on the 1024 grid."""
    pen = _FlattenPen(None)
    _draw_letter(pen)
    return pen.contours


def letter_svg_path(transform: Transform | None = None, digits: int = 1) -> str:
    """The « m » as an SVG / Android pathData string, optionally re-mapped."""
    pen = SVGPathPen(None, ntos=lambda v: f"{round(v, digits):g}")
    target: object = pen
    if transform is not None:
        target = _PointMapPen(pen, transform)
    _draw_letter(target)
    return pen.getCommands()


class _PointMapPen(BasePen):
    """Forwards a path to another pen, mapping every point (non-affine-safe)."""

    def __init__(self, out: SVGPathPen, transform: Transform) -> None:
        super().__init__(None)
        self._out = out
        self._map = transform

    def _moveTo(self, pt: Point) -> None:
        self._out.moveTo(self._map(pt))

    def _lineTo(self, pt: Point) -> None:
        self._out.lineTo(self._map(pt))

    def _curveToOne(self, p1: Point, p2: Point, p3: Point) -> None:
        self._out.curveTo(self._map(p1), self._map(p2), self._map(p3))

    def _qCurveToOne(self, p1: Point, p2: Point) -> None:
        self._out.qCurveTo(self._map(p1), self._map(p2))

    def _closePath(self) -> None:
        self._out.closePath()

    def _endPath(self) -> None:
        self._out.endPath()


def scaled_about_centre(factor: float) -> Transform:
    centre = GRID / 2
    return lambda p: (centre + (p[0] - centre) * factor, centre + (p[1] - centre) * factor)


def _hex(colour: str) -> tuple[int, int, int]:
    return tuple(int(colour[i : i + 2], 16) for i in (1, 3, 5))  # type: ignore[return-value]


def _motif_mask(size: int, motif: Transform, dot_radius: float) -> tuple[Image.Image, Image.Image]:
    """Anti-aliased letter and dot masks, motif mapped from the 1024 grid."""
    big = size * SUPERSAMPLE
    ratio = big / GRID
    letter = Image.new("L", (big, big), 0)
    for contour in letter_contours():
        layer = Image.new("L", (big, big), 0)
        ImageDraw.Draw(layer).polygon(
            [(x * ratio, y * ratio) for x, y in (motif(p) for p in contour)], fill=255
        )
        letter = ImageChops.logical_xor(letter.convert("1"), layer.convert("1")).convert("L")
    dot = Image.new("L", (big, big), 0)
    cx, cy = motif(DOT_CENTRE)
    r = dot_radius * ratio * (motif((1, 0))[0] - motif((0, 0))[0])
    ImageDraw.Draw(dot).ellipse((cx * ratio - r, cy * ratio - r, cx * ratio + r, cy * ratio + r), fill=255)
    return (
        letter.resize((size, size), Image.Resampling.LANCZOS),
        dot.resize((size, size), Image.Resampling.LANCZOS),
    )


def render_square(size: int, palette: Palette, dot_radius: float = DOT_RADIUS) -> Image.Image:
    """Full-bleed square, no alpha: what iOS masks itself."""
    image = Image.new("RGB", (size, size), _hex(palette.background))
    letter, dot = _motif_mask(size, lambda p: p, dot_radius)
    image.paste(_hex(palette.letter), (0, 0), letter)
    image.paste(_hex(palette.dot), (0, 0), dot)
    return image


def render_legacy_android(size: int, round_shape: bool) -> Image.Image:
    """Pre-API 26 launcher icon: rounded square or circle, transparent outside."""
    big = size * SUPERSAMPLE
    shape = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(shape)
    if round_shape:
        draw.ellipse((0, 0, big - 1, big - 1), fill=255)
    else:
        draw.rounded_rectangle((0, 0, big - 1, big - 1), radius=big * 0.225, fill=255)
    shape = shape.resize((size, size), Image.Resampling.LANCZOS)
    image = Image.new("RGBA", (size, size), (*_hex(INK), 0))
    image.paste((*_hex(INK), 255), (0, 0), shape)
    scale = ANDROID_MOTIF_SCALE if round_shape else 1.0
    letter, dot = _motif_mask(size, scaled_about_centre(scale), DOT_RADIUS)
    image.paste((*_hex(WHITE), 255), (0, 0), letter)
    image.paste((*_hex(TEKHELET), 255), (0, 0), dot)
    return image


def master_svg() -> str:
    cx, cy = DOT_CENTRE
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {GRID} {GRID}" '
        f'width="{GRID}" height="{GRID}">\n'
        f'  <rect width="{GRID}" height="{GRID}" fill="{INK}"/>\n'
        f'  <path d="{letter_svg_path()}" fill="{WHITE}"/>\n'
        f'  <circle cx="{cx}" cy="{cy}" r="{DOT_RADIUS}" fill="{TEKHELET}"/>\n'
        "</svg>\n"
    )


def _to_adaptive_dp(p: Point) -> Point:
    inset = (ADAPTIVE_LAYER_DP - ADAPTIVE_VISIBLE_DP) / 2
    sx, sy = scaled_about_centre(ANDROID_MOTIF_SCALE)(p)
    unit = ADAPTIVE_VISIBLE_DP / GRID
    return (inset + sx * unit, inset + sy * unit)


def adaptive_foreground_xml() -> str:
    cx, cy = _to_adaptive_dp(DOT_CENTRE)
    r = DOT_RADIUS * ANDROID_MOTIF_SCALE * ADAPTIVE_VISIBLE_DP / GRID
    dot = f"M{cx - r:.2f},{cy:.2f}a{r:.2f},{r:.2f} 0 1,0 {2 * r:.2f},0a{r:.2f},{r:.2f} 0 1,0 {-2 * r:.2f},0Z"
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated by tool/app_icon/make_app_icon.py: do not edit by hand. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        f'    android:width="{ADAPTIVE_LAYER_DP}dp"\n'
        f'    android:height="{ADAPTIVE_LAYER_DP}dp"\n'
        f'    android:viewportWidth="{ADAPTIVE_LAYER_DP}"\n'
        f'    android:viewportHeight="{ADAPTIVE_LAYER_DP}">\n'
        "    <path\n"
        f'        android:fillColor="{WHITE}"\n'
        f'        android:pathData="{letter_svg_path(_to_adaptive_dp, digits=3)}" />\n'
        "    <path\n"
        f'        android:fillColor="{TEKHELET}"\n'
        f'        android:pathData="{dot}" />\n'
        "</vector>\n"
    )


ADAPTIVE_ICON_XML = (
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background" />\n'
    '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
    '    <monochrome android:drawable="@drawable/ic_launcher_foreground" />\n'
    "</adaptive-icon>\n"
)

BACKGROUND_COLOUR_XML = (
    '<?xml version="1.0" encoding="utf-8"?>\n'
    "<resources>\n"
    f'    <color name="ic_launcher_background">{INK}</color>\n'
    "</resources>\n"
)

IOS_ICONS = {
    "AppIcon-1024.png": DEFAULT,
    "AppIcon-1024-dark.png": DARK,
    "AppIcon-1024-tinted.png": TINTED,
}

LEGACY_DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def ios_contents_json() -> str:
    def entry(filename: str, appearance: str | None) -> dict[str, object]:
        item: dict[str, object] = {"filename": filename, "idiom": "universal", "platform": "ios", "size": "1024x1024"}
        if appearance is not None:
            item["appearances"] = [{"appearance": "luminosity", "value": appearance}]
        return item

    contents = {
        "images": [
            entry("AppIcon-1024.png", None),
            entry("AppIcon-1024-dark.png", "dark"),
            entry("AppIcon-1024-tinted.png", "tinted"),
        ],
        "info": {"author": "xcode", "version": 1},
    }
    return json.dumps(contents, indent=2) + "\n"


def main() -> None:
    tool = MOBILE / "tool/app_icon"
    (tool / "mazl_icon.svg").write_text(master_svg())

    appiconset = MOBILE / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for old in appiconset.glob("*.png"):
        old.unlink()
    for filename, palette in IOS_ICONS.items():
        render_square(GRID, palette).save(appiconset / filename, optimize=True)
    (appiconset / "Contents.json").write_text(ios_contents_json())

    res = MOBILE / "android/app/src/main/res"
    (res / "drawable/ic_launcher_foreground.xml").write_text(adaptive_foreground_xml())
    (res / "values/ic_launcher_background.xml").write_text(BACKGROUND_COLOUR_XML)
    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
        (anydpi / name).write_text(ADAPTIVE_ICON_XML)
    for density, size in LEGACY_DENSITIES.items():
        folder = res / f"mipmap-{density}"
        render_legacy_android(size, round_shape=False).save(folder / "ic_launcher.png", optimize=True)
        render_legacy_android(size, round_shape=True).save(folder / "ic_launcher_round.png", optimize=True)


if __name__ == "__main__":
    main()
