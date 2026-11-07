"""Compare Luau's parsed document to Chromium's inert DOMParser; optional offline screenshots."""
import argparse
import json
from pathlib import Path

from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
parser.add_argument("report", type=Path)
parser.add_argument("--capture", action="store_true")
parser.add_argument("--update-cases", action="store_true", help="Capture Chromium expectations for owned JSON test cases")
args = parser.parse_args()
source = args.source.read_bytes().decode("utf-8")
output = args.report.parent

def normalize(node):
    kind = node["Kind"]
    if kind == "Element":
        return {"Kind": kind, "Name": node["SourceName"], "Namespace": node["Namespace"],
                "Attributes": {entry["SourceName"]: entry["Value"] for entry in node["Attributes"]},
                "Children": [normalize(child) for child in node["Children"]]}
    return {"Kind": kind, "Name" if kind == "Doctype" else "Text": node["Name" if kind == "Doctype" else "Text"]}

def differences(actual, expected, path="Document"):
    if type(actual) is not type(expected):
        return [f"{path}: {type(actual).__name__} != {type(expected).__name__}"]
    if isinstance(actual, dict):
        if set(actual) != set(expected):
            return [f"{path}: fields {sorted(actual)} != {sorted(expected)}"]
        return [difference for key in actual for difference in differences(actual[key], expected[key], f"{path}.{key}")]
    if isinstance(actual, list):
        errors = [] if len(actual) == len(expected) else [f"{path}: length {len(actual)} != {len(expected)}"]
        return errors + [difference for index, (a, b) in enumerate(zip(actual, expected))
                         for difference in differences(a, b, f"{path}[{index}]")]
    return [] if actual == expected else [f"{path}: {str(actual)[:100]!r} != {str(expected)[:100]!r}"]

SNAPSHOT = """source => {
    const document = new DOMParser().parseFromString(source, 'text/html');
    const namespace = {'http://www.w3.org/1999/xhtml':'HTML', 'http://www.w3.org/2000/svg':'SVG', 'http://www.w3.org/1998/Math/MathML':'MathML'};
    const snapshot = node => {
        if (node.nodeType === 1) return {Kind:'Element', Name:node.localName, Namespace:namespace[node.namespaceURI],
            Attributes:Object.fromEntries([...node.attributes].map(attr => [attr.name, attr.value])),
            Children:[...node.childNodes].map(snapshot)};
        if (node.nodeType === 10) return {Kind:'Doctype', Name:node.name};
        if (node.nodeType !== 3 && node.nodeType !== 8) throw new Error(`Unsupported oracle node type ${node.nodeType}`);
        return {Kind:node.nodeType === 8 ? 'Comment' : 'Text', Text:node.nodeValue};
    };
    return [...document.childNodes].map(snapshot);
}"""

with sync_playwright() as playwright:
    browser = playwright.chromium.launch(timeout=30000)
    page = browser.new_page(viewport={"width": 1440, "height": 1000}, color_scheme="light")
    if args.update_cases:
        cases = json.loads(source)
        for case in cases:
            case["Expected"] = page.evaluate(SNAPSHOT, case["Source"])
        args.report.write_text(json.dumps(cases, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Captured {len(cases)} owned cases with Chromium {browser.version}.")
        browser.close()
        raise SystemExit(0)
    report = json.loads(args.report.read_text(encoding="utf-8"))
    # DOMParser is inert: remote scripts cannot mutate the structure used as the oracle.
    expected = page.evaluate(SNAPSHOT, source)
    (output / "browser-document.json").write_text(json.dumps(expected, indent=2), encoding="utf-8")
    actual = [normalize(node) for node in report["Document"]["Children"]]
    errors = differences(actual, expected)
    (output / "document-differences.json").write_text(json.dumps(errors, indent=2), encoding="utf-8")
    if args.capture:
        context = browser.new_context(viewport={"width": 1440, "height": 1000}, color_scheme="light", java_script_enabled=False)
        context.route("**/*", lambda route: route.continue_() if route.request.url.startswith("file:") else route.abort())
        preview = context.new_page()
        preview.goto(args.source.resolve().as_uri())
        preview.screenshot(path=str(output / "browser-desktop.png"))
        preview.set_viewport_size({"width": 390, "height": 844})
        preview.screenshot(path=str(output / "browser-mobile.png"))
        context.close()
    browser.close()
print(f"Chromium DOM comparison: {len(errors)} differences.")
for error in errors[:12]:
    print(error)
raise SystemExit(1 if errors or not report["Document"]["Success"] else 0)
