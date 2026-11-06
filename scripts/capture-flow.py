"""Capture the shared inline layout fixtures using Studio's bundled fonts."""
import argparse
import json
from pathlib import Path
import shutil

from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument("--font-directory", type=Path, required=True)
parser.add_argument("--device-scale", type=float, default=1.75)
args = parser.parse_args()
output = Path(__file__).resolve().parents[1] / "build" / "visual"
(output / "fonts").mkdir(exist_ok=True, parents=True)
for name in ("Regular", "Bold", "It"):
    filename = f"SourceSansPro-{name}.ttf"
    shutil.copyfile(args.font_directory / filename, output / "fonts" / filename)

with sync_playwright() as playwright:
    browser = playwright.chromium.launch(timeout=30000)
    page = browser.new_page(viewport={"width": 772, "height": 484}, device_scale_factor=args.device_scale)
    page.goto((output / "flow.html").as_uri())
    page.evaluate("document.fonts.ready")
    page.screenshot(path=str(output / "flow-browser.png"))
    records = page.locator(".Pane [id]").evaluate_all("""nodes => nodes.map(node => {
        const rect = r => ({X:r.x, Y:r.y, Width:r.width, Height:r.height});
        return {Pane:node.closest('.Pane').id, Id:node.id,
            Rect:rect(node.getBoundingClientRect()), Fragments:[...node.getClientRects()].map(rect)};
    })""")
    (output / "flow-browser.json").write_text(json.dumps(records, indent=2))
    browser.close()
print("Captured flow-browser.png and flow-browser.json")
