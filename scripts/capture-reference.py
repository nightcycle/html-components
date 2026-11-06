"""Capture the generated HTML reference with Chromium and matching Studio fonts.

Requires: pip install playwright; python -m playwright install chromium
Usage: python scripts/capture-reference.py --font-directory PATH_TO_STUDIO_FONTS
"""
import argparse
import json
from pathlib import Path
import shutil

from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument("--font-directory", type=Path, required=True)
args = parser.parse_args()
output = Path(__file__).resolve().parents[1] / "build" / "visual"
(output / "fonts").mkdir(parents=True, exist_ok=True)
for name in ("Regular", "Bold", "Semibold"):
    font = f"SourceSansPro-{name}.ttf"
    shutil.copyfile(args.font_directory / font, output / "fonts" / font)
with sync_playwright() as playwright:
    browser = playwright.chromium.launch()
    page = browser.new_page(viewport={"width": 1008, "height": 744}, device_scale_factor=1)
    page.goto((output / "index.html").as_uri())
    page.evaluate("document.fonts.ready")
    page.screenshot(path=str(output / "browser.png"))
    bounds = page.locator("[data-sample]").evaluate_all("""nodes => nodes.map(node => {
        const r = node.getBoundingClientRect();
        return {Id: node.id, X: r.x, Y: r.y, Width: r.width, Height: r.height};
    })""")
    (output / "browser-bounds.json").write_text(json.dumps(bounds, indent=2))
    browser.close()
print(f"Saved {output / 'browser.png'} and {len(bounds)} DOM rectangles.")
