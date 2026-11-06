"""Compare flow-studio.json/flow-studio.jpg with the captured HTML reference."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

output = Path(__file__).resolve().parents[1] / "build" / "visual"
browser = json.loads((output / "flow-browser.json").read_text())
studio = json.loads((output / "flow-studio.json").read_text())
lookup = {(node["Pane"], node["Id"]): node["Rect"] for node in studio["Records"]}
results = []
for node in browser:
    # A Br retains a native zero-width host; its effect is measured by subsequent lines.
    if node["Id"] == "Break":
        continue
    actual = lookup[(node["Pane"], node["Id"])]
    delta = {key: round(actual[key] - value, 4) for key, value in node["Rect"].items()}
    results.append({"Pane": node["Pane"], "Id": node["Id"], "Delta": delta})
boxes = [node for node in results if node["Id"] in ("Flow", "Copy", "Atomic", "Badge", "FirstBlock", "SecondBlock")]
maximum = max(abs(value) for node in boxes for value in node["Delta"].values())
assert len(boxes) == 12 and maximum <= 1, boxes
(output / "flow-comparison.json").write_text(json.dumps(results, indent=2))

capture = Image.open(output / "flow-studio.jpg").convert("RGB")
scale_x = capture.width / studio["Viewport"]["X"]
scale_y = capture.height / studio["Viewport"]["Y"]
cropped = capture.crop((0, 0, round(772 * scale_x), round(484 * scale_y)))
cropped = cropped.resize((772, 484), Image.Resampling.LANCZOS)
reference = Image.open(output / "flow-browser.png").convert("RGB").resize((772, 484), Image.Resampling.LANCZOS)
comparison = Image.new("RGB", (1544, 514), "white")
draw = ImageDraw.Draw(comparison)
draw.text((24, 8), "Browser / Chromium", fill="black")
draw.text((796, 8), "Roblox Studio", fill="black")
comparison.paste(reference, (0, 30))
comparison.paste(cropped, (772, 30))
comparison.save(output / "flow-comparison.png")
print(f"12 block/inline-block rectangles match within {maximum:.3f}px at two widths.")
print("Inline text-root differences are recorded separately in flow-comparison.json.")
