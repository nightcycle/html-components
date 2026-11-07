"""Compare matched document rectangles and create a browser/Studio contact sheet."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw

parser = argparse.ArgumentParser()
parser.add_argument("directory", type=Path)
args = parser.parse_args()
directory = args.directory
browser = json.loads((directory / "browser-bounds.json").read_text())
studio = json.loads((directory / "studio-bounds.json").read_text())
by_name = {item["Name"]: item for item in studio["Records"]}
comparisons = []
for expected in browser:
    actual = by_name.get(expected["Name"])
    if not actual or not actual["Visible"] or expected["Width"] <= 0 or expected["Height"] <= 0:
        continue
    errors = {key: actual[key] - expected[key] for key in ("X", "Y", "Width", "Height")}
    comparisons.append({"Name": expected["Name"], "Tag": expected["Tag"], "Browser": expected,
                        "Studio": actual, "Errors": errors, "MaximumError": max(map(abs, errors.values()))})
(directory / "geometry-comparison.json").write_text(json.dumps(comparisons, indent=2))
reference = Image.open(directory / "browser.png").convert("RGB")
capture = Image.open(directory / "studio.jpg").convert("RGB")
scale_x, scale_y = capture.width / studio["Viewport"]["X"], capture.height / studio["Viewport"]["Y"]
frame = studio["Frame"]
rect = (round(frame["X"] * scale_x), round(frame["Y"] * scale_y),
        round((frame["X"] + frame["Width"]) * scale_x), round((frame["Y"] + frame["Height"]) * scale_y))
native = capture.crop(rect).resize(reference.size, Image.Resampling.LANCZOS)
native.save(directory / "studio-normalized.png")
sheet = Image.new("RGB", (reference.width * 2, reference.height + 40), "#172033")
draw = ImageDraw.Draw(sheet)
draw.text((16, 12), "Chromium reference", fill="white")
draw.text((reference.width + 16, 12), "React Luau / Studio", fill="white")
sheet.paste(reference, (0, 40))
sheet.paste(native, (reference.width, 40))
sheet.save(directory / "comparison.png")
landmarks = [item for item in comparisons if item["Tag"] in ("header", "h1", "h2")]
for item in landmarks:
    print(item["Tag"], item["Name"], {key: round(value, 2) for key, value in item["Errors"].items()})
print(f"Compared {len(comparisons)} visible elements. Full per-element errors retained in geometry-comparison.json.")
