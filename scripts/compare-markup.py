"""Compare the markup, table, and hand-authored React boards with browser HTML."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

output = Path(__file__).resolve().parents[1] / "build" / "visual"
browser = json.loads((output / "markup-browser.json").read_text())
studio = json.loads((output / "markup-studio.json").read_text())
lookup = {(node["Pane"], node["Id"]): node["Rect"] for node in studio["Records"]}
results = []
for node in browser:
    actual = lookup[(node["Pane"], node["Id"])]
    delta = {key: round(actual[key] - value, 4) for key, value in node["Rect"].items()}
    results.append({"Pane": node["Pane"], "Id": node["Id"], "Delta": delta})
(output / "markup-comparison.json").write_text(json.dumps(results, indent=2))

capture = Image.open(output / "markup-studio.jpg").convert("RGB")
scale_x = capture.width / studio["Viewport"]["X"]
scale_y = capture.height / studio["Viewport"]["Y"]
cropped = capture.crop((0, 0, round(1008 * scale_x), round(744 * scale_y)))
cropped = cropped.resize((1008, 744), Image.Resampling.LANCZOS)
reference = Image.open(output / "markup-browser.png").convert("RGB").resize((1008, 744), Image.Resampling.LANCZOS)
comparison = Image.new("RGB", (2016, 774), "white")
draw = ImageDraw.Draw(comparison)
draw.text((20, 8), "Browser / Chromium", fill="black")
draw.text((1028, 8), "Roblox Studio", fill="black")
comparison.paste(reference, (0, 30))
comparison.paste(cropped, (1008, 30))
comparison.save(output / "markup-comparison.png")

boxes = [node for node in results if node["Id"] in ("Card", "Copy", "Boxes", "Badge", "Sized")]
maximum = max(abs(value) for node in boxes for key, value in node["Delta"].items() if key != "X")
horizontal = max(abs(node["Delta"]["X"]) for node in boxes)
# Atomic boxes follow measured text advances, which differ slightly between engines.
assert len(boxes) == 30 and maximum <= 1 and horizontal <= 3, boxes
print(f"30 boxes match size/vertical position within {maximum:.3f}px; horizontal difference <= {horizontal:.3f}px.")
print("Inline text-root differences are recorded separately in markup-comparison.json.")
