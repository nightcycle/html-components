"""Compare captured DOM/Studio geometry and assemble a review image (requires Pillow)."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

output = Path(__file__).resolve().parents[1] / "build" / "visual"
reference = json.loads((output / "browser-bounds.json").read_text())
studio = json.loads((output / "studio-bounds.json").read_text(encoding="utf-8-sig"))
actual = {rect["Id"]: rect for rect in studio["Bounds"]}
deltas = []
for expected in reference:
    found = actual[expected["Id"]]
    delta = max(abs(expected[key] - found[key]) for key in ("X", "Y", "Width", "Height"))
    deltas.append({"Id": expected["Id"], "MaxDelta": delta})
report = {"Elements": len(deltas), "MaxDelta": max(row["MaxDelta"] for row in deltas), "Deltas": deltas}
(output / "geometry-report.json").write_text(json.dumps(report, indent=2))
assert report["MaxDelta"] <= 1, report

browser = Image.open(output / "browser.png").convert("RGB")
capture_metadata = json.loads((output / "browser-capture.json").read_text())
browser = browser.resize((capture_metadata["Width"], capture_metadata["Height"]), Image.Resampling.LANCZOS)
capture = Image.open(output / "studio-after.jpg")
board, viewport = studio["Board"], studio["Viewport"]
sx, sy = capture.width / viewport["X"], capture.height / viewport["Y"]
box = tuple(round(value) for value in (board["X"] * sx, board["Y"] * sy,
    (board["X"] + board["Width"]) * sx, (board["Y"] + board["Height"]) * sy))
cropped = capture.crop(box).resize(browser.size, Image.Resampling.LANCZOS)
cropped.save(output / "studio-board.png")
comparison = Image.new("RGB", (browser.width * 2, browser.height + 36), "#ffffff")
draw = ImageDraw.Draw(comparison)
draw.text((20, 12), "Chromium HTML reference", fill="#182033")
draw.text((browser.width + 20, 12), "Roblox Studio screen_capture", fill="#182033")
comparison.paste(browser, (0, 36))
comparison.paste(cropped, (browser.width, 36))
comparison.save(output / "comparison.png")
print(f"{report['Elements']} element rectangles matched; maximum delta {report['MaxDelta']:.4f}px.")
