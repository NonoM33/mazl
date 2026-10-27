"""Every theme of docs/storefront/themes.json has its alternate icon set, its
glyph (in the app and in the console) and its Xcode registration.

Run from mobile/:  python -m unittest discover -s tool/app_icon -p "test_*.py"
(needs Pillow). Written from the contract (CONTRACT.md §2), not from the generator.
"""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

from PIL import Image

MOBILE = Path(__file__).resolve().parents[2]
REPO = MOBILE.parent
THEMES = json.loads((REPO / "docs/storefront/themes.json").read_text())["themes"]
CATALOG = MOBILE / "ios/Runner/Assets.xcassets"
PBXPROJ = MOBILE / "ios/Runner.xcodeproj/project.pbxproj"
VARIANTS = ("1024", "1024-dark", "1024-tinted")


class ThemeIconsTest(unittest.TestCase):
    def test_each_theme_has_three_opaque_1024_images(self) -> None:
        for theme in THEMES:
            name = f"AppIcon-{theme['id']}"
            folder = CATALOG / f"{name}.appiconset"
            contents = json.loads((folder / "Contents.json").read_text())
            self.assertEqual(len(contents["images"]), 3, name)
            for variant in VARIANTS:
                path = folder / f"{name}-{variant}.png"
                with Image.open(path) as image:
                    self.assertEqual(image.size, (1024, 1024), path.name)
                    self.assertEqual(image.mode, "RGB", f"{path.name} must have no alpha")
                self.assertIn(path.name, [i["filename"] for i in contents["images"]])

    def test_each_theme_glyph_exists_in_app_and_console_identically(self) -> None:
        for theme in THEMES:
            app = MOBILE / f"assets/storefront/glyphs/{theme['glyph']}.svg"
            console = REPO / f"console/src/storefront/glyphs/{theme['glyph']}.svg"
            self.assertIn("currentColor", app.read_text(), app.name)
            self.assertEqual(app.read_bytes(), console.read_bytes(), theme["glyph"])

    def test_xcode_lists_exactly_the_themes_on_every_runner_configuration(self) -> None:
        expected = {f"AppIcon-{t['id']}" for t in THEMES}
        listings = re.findall(r'ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "([^"]*)";', PBXPROJ.read_text())
        self.assertEqual(len(listings), 3, "Debug, Release and Profile of the Runner target")
        for listing in listings:
            self.assertEqual(set(listing.split()), expected)

    def test_default_icon_is_untouched_by_the_alternates(self) -> None:
        self.assertTrue((CATALOG / "AppIcon.appiconset/AppIcon-1024.png").exists())


if __name__ == "__main__":
    unittest.main()
