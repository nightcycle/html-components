"""Capture the generated HTML reference with Chromium and matching Studio fonts.

Requires: pip install playwright; python -m playwright install chromium
Usage: python scripts/capture-reference.py --font-directory PATH_TO_STUDIO_FONTS
"""
import argparse
import json
from pathlib import Path
import shutil

from playwright.sync_api import sync_playwright


def check_meter_fill(page):
    """Check the painted shadow-DOM bar, not only the outer meter rectangle."""
    session = page.context.new_cdp_session(page)
    session.send("DOM.enable")
    document = session.send("DOM.getDocument", {"depth": -1, "pierce": True})["root"]

    def descendants(node):
        yield node
        for key in ("children", "shadowRoots"):
            for child in node.get(key, []):
                yield from descendants(child)

    meter = next(node for node in descendants(document) if node.get("nodeName") == "METER")
    parts = {}
    for node in descendants(meter):
        attributes = node.get("attributes", [])
        attributes = dict(zip(attributes[::2], attributes[1::2]))
        name = attributes.get("pseudo", "Host" if node is meter else None)
        if not name:
            continue
        model = session.send("DOM.getBoxModel", {"nodeId": node["nodeId"]})["model"]
        quad = model["border"]
        parts[name] = {"X": quad[0], "Y": quad[1], "Width": quad[2] - quad[0], "Height": quad[5] - quad[1]}
    host, bar, fill = (parts[key] for key in ("Host", "-webkit-meter-bar", "-webkit-meter-optimum-value"))
    for part in (bar, fill):
        assert abs(part["Y"] - host["Y"]) < 0.01 and abs(part["Height"] - host["Height"]) < 0.01, parts
    value = page.locator("#meter").evaluate("node => (node.value - node.min) / (node.max - node.min)")
    assert abs(fill["Width"] - host["Width"] * value) < 0.01, parts
    session.detach()
    return parts


parser = argparse.ArgumentParser()
parser.add_argument("--font-directory", type=Path, required=True)
parser.add_argument("--device-scale", type=float, default=1)
args = parser.parse_args()
output = Path(__file__).resolve().parents[1] / "build" / "visual"
(output / "fonts").mkdir(parents=True, exist_ok=True)
for name in ("Regular", "Bold", "Semibold"):
    font = f"SourceSansPro-{name}.ttf"
    shutil.copyfile(args.font_directory / font, output / "fonts" / font)
with sync_playwright() as playwright:
    browser = playwright.chromium.launch()
    page = browser.new_page(viewport={"width": 1008, "height": 744}, device_scale_factor=args.device_scale)
    page.goto((output / "index.html").as_uri())
    page.evaluate("document.fonts.ready")
    meter_parts = check_meter_fill(page)
    (output / "browser-meter.json").write_text(json.dumps(meter_parts, indent=2))
    page.screenshot(path=str(output / "browser.png"))
    text_metrics = page.locator("#heading, #copy, .case > header").evaluate_all("""nodes => nodes.map(node => {
        const style = getComputedStyle(node);
        const range = document.createRange();
        range.selectNodeContents(node);
        const rect = range.getBoundingClientRect();
        return {Text: node.textContent, FontSize: style.fontSize, FontWeight: style.fontWeight,
            Width: rect.width, Height: rect.height};
    })""")
    (output / "browser-text.json").write_text(json.dumps(text_metrics, indent=2))
    (output / "browser-capture.json").write_text(json.dumps({"DeviceScale": args.device_scale,
        "Width": 1008, "Height": 744}, indent=2))
    bounds = page.locator("[data-sample]").evaluate_all("""nodes => nodes.map(node => {
        const r = node.getBoundingClientRect();
        return {Id: node.id, X: r.x, Y: r.y, Width: r.width, Height: r.height};
    })""")
    (output / "browser-bounds.json").write_text(json.dumps(bounds, indent=2))
    browser.close()
print(f"Saved {output / 'browser.png'} and {len(bounds)} DOM rectangles.")
