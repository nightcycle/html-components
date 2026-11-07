"""Capture a local document oracle and prepare local-only graphics for Studio.

The browser supplies comparison geometry and rasterizes graphics only. Its layout
and computed styles are never used as renderer input.
"""
import argparse
import io
import json
from pathlib import Path

from PIL import Image
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--width", type=int, default=1440)
parser.add_argument("--height", type=int, default=1000)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
assets = {}
with sync_playwright() as playwright:
    browser = playwright.chromium.launch()
    context = browser.new_context(viewport={"width": args.width, "height": args.height}, color_scheme="light", java_script_enabled=False)
    context.set_default_timeout(10000)
    context.route("**/*", lambda route: route.continue_() if route.request.url.startswith("file:") and route.request.resource_type != "script" else route.abort())
    page = context.new_page()
    page.goto(args.source.resolve().as_uri())
    page.wait_for_function("document.fonts.status === 'loaded'", timeout=10000, polling=100)
    records = page.evaluate("""() => {
      const path = n => n.parentNode ? path(n.parentNode).concat([...n.parentNode.childNodes].indexOf(n)+1) : [];
      return [...document.querySelectorAll('*')].map(n => {
        const s=getComputedStyle(n), r=n.getBoundingClientRect(), p=path(n).join('.');
        const record={Path:p, Name:n.id||'HTML_'+p, Tag:n.localName, ClassName:n.getAttribute('class'),
          Text:n.textContent.slice(0,100), X:r.x,Y:r.y,Width:r.width,Height:r.height,
          Display:s.display, FontSize:s.fontSize, FontWeight:s.fontWeight, FontFamily:s.fontFamily,
          Color:s.color, BackgroundColor:s.backgroundColor, LineHeight:s.lineHeight};
        if(n.localName==='img') record.Src=n.src;
        if(n.localName==='svg') {
          const clone=n.cloneNode(true);
          const originals=[n,...n.querySelectorAll('*')], copies=[clone,...clone.querySelectorAll('*')];
          originals.forEach((item,i)=>{
            const computed=getComputedStyle(item);
            for(const key of ['fill','stroke','stroke-width','fill-rule','clip-rule','opacity']) copies[i].setAttribute(key,computed.getPropertyValue(key));
            copies[i].removeAttribute('class');
          });
          const view=n.viewBox.baseVal;
          record.AssetWidth=r.width||view.width||24;record.AssetHeight=r.height||view.height||24;
          clone.setAttribute('xmlns','http://www.w3.org/2000/svg');
          clone.setAttribute('width',String(record.AssetWidth));clone.setAttribute('height',String(record.AssetHeight));
          record.SVG=new XMLSerializer().serializeToString(clone);
        }
        return record;
      });
    }""")
    page.screenshot(path=str(args.output / "browser.png"))
    page.screenshot(path=str(args.output / "browser-full.png"), full_page=True)
    raster = context.new_page()
    for index, record in enumerate(records):
        img = None
        if record["Tag"] == "img" and record.get("Src", "").startswith("file:"):
            from urllib.parse import urlparse
            from urllib.request import url2pathname
            source = Path(url2pathname(urlparse(record["Src"]).path))
            if source.suffix.lower() != ".svg" and source.is_file():
                img = Image.open(source).convert("RGBA")
                img.thumbnail((768, 768))
            elif source.is_file():
                import xml.etree.ElementTree as ET
                ET.register_namespace("", "http://www.w3.org/2000/svg")
                root = ET.fromstring(source.read_text())
                view = root.get("viewBox", "").split()
                width = float(view[2]) if len(view) == 4 else record["Width"] or 24
                height = float(view[3]) if len(view) == 4 else record["Height"] or 24
                factor = min(2, 768 / max(width, height, 1))
                record["AssetWidth"], record["AssetHeight"] = max(1, round(width * factor)), max(1, round(height * factor))
                root.set("width", str(record["AssetWidth"]))
                root.set("height", str(record["AssetHeight"]))
                record["SVG"] = ET.tostring(root, encoding="unicode")
        if record.get("SVG"):
            width, height = max(1, round(record["AssetWidth"])), max(1, round(record["AssetHeight"]))
            raster.set_viewport_size({"width": width, "height": height})
            raster.set_content('<html><body style="margin:0;background:transparent">' + record["SVG"] + '</body></html>')
            img = Image.open(io.BytesIO(raster.screenshot(omit_background=True))).convert("RGBA")
        if img is not None:
            filename = f"asset-{index}.rgba"
            (args.output / filename).write_bytes(img.tobytes())
            assets[record["Path"]] = {"Width": img.width, "Height": img.height, "File": filename}
        record.pop("SVG", None)
    (args.output / "manifest.json").write_text(json.dumps({"Source": str(args.source.resolve()), "Assets": assets}, indent=2))
    (args.output / "browser-bounds.json").write_text(json.dumps(records, indent=2))
    browser.close()
print(f"Captured {len(records)} rectangles and {len(assets)} local graphics at {args.width}x{args.height}.")
