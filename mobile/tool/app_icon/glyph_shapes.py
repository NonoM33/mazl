"""Seasonal glyphs of the MAZL icons, drawn ONCE as solid vector shapes.

Every glyph lives in a 24 x 24 box (y down). A glyph is a list of
(operation, svg path data): "+" unions the shape, "-" cuts it out of what has
been built so far. The result is a single clean outline (pathops), centred in
the box, which feeds both the 24 x 24 SVG files and the app icons, so the two
can never drift apart. Plain fills only: no gradient, no hairline, so the glyph
stays readable at 60 px.
"""

from __future__ import annotations

import math
from collections.abc import Callable

import pathops
from fontTools.pens.basePen import BasePen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path

BOX = 24
Shape = list[tuple[str, str]]


def _f(v: float) -> str:
    return f"{v:.3f}".rstrip("0").rstrip(".")


def circle(cx: float, cy: float, r: float) -> str:
    return (
        f"M{_f(cx - r)} {_f(cy)}A{_f(r)} {_f(r)} 0 1 0 {_f(cx + r)} {_f(cy)}"
        f"A{_f(r)} {_f(r)} 0 1 0 {_f(cx - r)} {_f(cy)}Z"
    )


def ellipse(cx: float, cy: float, rx: float, ry: float) -> str:
    return (
        f"M{_f(cx - rx)} {_f(cy)}A{_f(rx)} {_f(ry)} 0 1 0 {_f(cx + rx)} {_f(cy)}"
        f"A{_f(rx)} {_f(ry)} 0 1 0 {_f(cx - rx)} {_f(cy)}Z"
    )


def polygon(points: list[tuple[float, float]]) -> str:
    head, *tail = points
    return f"M{_f(head[0])} {_f(head[1])}" + "".join(f"L{_f(x)} {_f(y)}" for x, y in tail) + "Z"


def heart(cx: float, cy: float, scale: float) -> str:
    """A heart whose bounding box is centred on (cx, cy); scale 1 is 18 wide."""

    def p(x: float, y: float) -> str:
        return f"{_f(cx + (x - 12) * scale)} {_f(cy + (y - 12.25) * scale)}"

    return (
        f"M{p(12, 21)}C{p(12, 21)} {p(3, 15.4)} {p(3, 8.9)}"
        f"C{p(3, 5.6)} {p(5.4, 3.5)} {p(8, 3.5)}"
        f"C{p(9.7, 3.5)} {p(11.2, 4.4)} {p(12, 5.9)}"
        f"C{p(12.8, 4.4)} {p(14.3, 3.5)} {p(16, 3.5)}"
        f"C{p(18.6, 3.5)} {p(21, 5.6)} {p(21, 8.9)}"
        f"C{p(21, 15.4)} {p(12, 21)} {p(12, 21)}Z"
    )


def _petals() -> Shape:
    parts: Shape = []
    for k in range(5):
        angle = math.radians(-90 + 72 * k)
        parts.append(("+", circle(12 + 5.6 * math.cos(angle), 12 + 5.6 * math.sin(angle), 4.3)))
    parts.append(("-", circle(12, 12, 1.9)))
    return parts


def _sun() -> Shape:
    parts: Shape = [("+", circle(12, 12, 5.2))]
    for k in range(8):
        angle = math.radians(45 * k)
        ux, uy = math.cos(angle), math.sin(angle)
        nx, ny = -uy, ux
        near, far, half = 7.6, 10.8, 1.5
        parts.append((
            "+",
            polygon([
                (12 + ux * near + nx * half, 12 + uy * near + ny * half),
                (12 + ux * far + nx * half, 12 + uy * far + ny * half),
                (12 + ux * far - nx * half, 12 + uy * far - ny * half),
                (12 + ux * near - nx * half, 12 + uy * near - ny * half),
            ]),
        ))
    return parts


GLYPHS: dict[str, Shape] = {
    "heart": [("+", heart(12, 12, 1.0))],
    "two_hearts": [
        ("+", heart(12, 12, 1.0)),
        ("-", heart(12, 11.4, 0.6)),
        ("+", heart(12, 11.0, 0.27)),
    ],
    "pomegranate": [
        ("+", circle(12, 14, 7.6)),
        ("+", polygon([(8.2, 7.6), (8.4, 2.8), (10.4, 5.0), (12, 2.0), (13.6, 5.0), (15.6, 2.8), (15.8, 7.6)])),
    ],
    "flame": [
        (
            "+",
            "M12 2C12 2 5.5 8.2 5.5 14.6C5.5 18.8 8.4 22 12 22C15.6 22 18.5 18.8 18.5 14.8"
            "C18.5 11.8 16.9 9.8 15.4 8.4C15.3 10.4 14.4 11.6 13.3 11.9C13.9 8.2 12.4 4.8 12 2Z",
        ),
        (
            "-",
            "M12 14.6C12 14.6 9.6 16.8 9.6 18.4C9.6 19.8 10.7 20.8 12 20.8C13.3 20.8 14.4 19.8 14.4 18.4"
            "C14.4 16.8 12 14.6 12 14.6Z",
        ),
    ],
    "fir": [
        ("+", polygon([(12, 2), (17, 9.4), (7, 9.4)])),
        ("+", polygon([(12, 6.2), (19, 15), (5, 15)])),
        ("+", polygon([(12, 10.6), (21, 20), (3, 20)])),
        ("+", polygon([(10.3, 19.5), (13.7, 19.5), (13.7, 22.6), (10.3, 22.6)])),
    ],
    "sparkle": [
        (
            "+",
            "M12 1.5C12.9 8 16 11.1 22.5 12C16 12.9 12.9 16 12 22.5C11.1 16 8 12.9 1.5 12C8 11.1 11.1 8 12 1.5Z",
        ),
    ],
    "mask": [
        (
            "+",
            "M2.5 9.2C2.5 7.2 4 6 6 6L18 6C20 6 21.5 7.2 21.5 9.2C21.5 13.4 19 17 16 17"
            "C14 17 13 14.8 12 14.8C11 14.8 10 17 8 17C5 17 2.5 13.4 2.5 9.2Z",
        ),
        ("-", ellipse(7.6, 10.6, 2.5, 1.7)),
        ("-", ellipse(16.4, 10.6, 2.5, 1.7)),
    ],
    "matzah": (
        [
            (
                "+",
                "M5.5 2.5H18.5A3 3 0 0 1 21.5 5.5V18.5A3 3 0 0 1 18.5 21.5H5.5A3 3 0 0 1 2.5 18.5V5.5A3 3 0 0 1 5.5 2.5Z",
            )
        ]
        + [("-", circle(x, y, 1.15)) for y in (7.8, 12, 16.2) for x in (7.8, 12, 16.2)]
    ),
    "flower": _petals(),
    "sun": _sun(),
    "bolt": [("+", "M13.8 1.8L4.2 13.4H10.6L9.4 22.2L19.8 9.8H13.2Z")],
}


def _to_path(d: str) -> pathops.Path:
    path = pathops.Path()
    parse_path(d, path.getPen())
    return path


def build(glyph: str) -> pathops.Path:
    """The glyph as one outline, its bounding box centred in the 24 x 24 box."""
    result: pathops.Path | None = None
    for operation, d in GLYPHS[glyph]:
        shape = _to_path(d)
        if result is None:
            result = shape
            continue
        kind = pathops.PathOp.UNION if operation == "+" else pathops.PathOp.DIFFERENCE
        result = pathops.op(result, shape, kind, fix_winding=True)
    assert result is not None
    result.simplify(fix_winding=True)
    left, top, right, bottom = result.bounds
    moved = pathops.Path()
    shift = TransformPen(moved.getPen(), (1, 0, 0, 1, BOX / 2 - (left + right) / 2, BOX / 2 - (top + bottom) / 2))
    result.draw(shift)
    return moved


def svg_path_data(glyph: str) -> str:
    pen = SVGPathPen(None, ntos=lambda v: f"{round(v, 2):g}")
    build(glyph).draw(pen)
    return pen.getCommands()


def svg(glyph: str) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {BOX} {BOX}" fill="currentColor">'
        f'<path fill-rule="evenodd" d="{svg_path_data(glyph)}"/></svg>\n'
    )


class _Flatten(BasePen):
    def __init__(self, steps: int = 24) -> None:
        super().__init__(None)
        self.contours: list[list[tuple[float, float]]] = []
        self._cur: list[tuple[float, float]] = []
        self._steps = steps

    def _moveTo(self, pt: tuple[float, float]) -> None:
        self._cur = [pt]

    def _lineTo(self, pt: tuple[float, float]) -> None:
        self._cur.append(pt)

    def _curveToOne(self, p1: tuple[float, float], p2: tuple[float, float], p3: tuple[float, float]) -> None:
        p0 = self._getCurrentPoint()
        for i in range(1, self._steps + 1):
            t = i / self._steps
            u = 1 - t
            self._cur.append((
                u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1],
            ))

    def _qCurveToOne(self, p1: tuple[float, float], p2: tuple[float, float]) -> None:
        p0 = self._getCurrentPoint()
        for i in range(1, self._steps + 1):
            t = i / self._steps
            u = 1 - t
            self._cur.append((
                u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
                u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1],
            ))

    def _closePath(self) -> None:
        if self._cur:
            self.contours.append(self._cur)
        self._cur = []

    _endPath = _closePath


def contours(glyph: str, place: Callable[[tuple[float, float]], tuple[float, float]]) -> list[list[tuple[float, float]]]:
    """The glyph as polygons, every point mapped by `place` (24 box to target)."""
    pen = _Flatten()
    build(glyph).draw(pen)
    return [[place(p) for p in contour] for contour in pen.contours]


def height(glyph: str) -> float:
    """Height of the centred glyph in the 24 box."""
    _, top, _, bottom = build(glyph).bounds
    return bottom - top
