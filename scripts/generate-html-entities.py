"""Generate Luau's HTML character-reference table from a saved WHATWG entities.json."""
import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
args = parser.parse_args()
raw = args.source.read_bytes()
expected = "d741d877ac77c4194c4ad526b5b4a19aef8dfe411ab840a466891cdbb9f362e6"
assert hashlib.sha256(raw).hexdigest() == expected, "Entity data changed; review before updating the pinned hash."
entries = json.loads(raw)
root = Path(__file__).resolve().parents[1]
license_text = (root / "docs/whatwg-license.txt").read_text(encoding="utf-8")
lines = ["--!strict", "-- Packages", "-- Modules", "-- Types", "-- Constants",
         "-- Generated from https://html.spec.whatwg.org/entities.json (2026-11-06).",
         "-- See docs/html-document.md for provenance and regeneration."]
lines.extend("-- " + line if line else "--" for line in license_text.splitlines())
lines.append("local entities: { [string]: string } = {")
for name, entry in sorted(entries.items()):
    encoded = "".join(f"\\u{{{codepoint:x}}}" for codepoint in entry["codepoints"])
    lines.append(f'\t["{name[1:]}"] = "{encoded}",')
lines.extend(["}", "-- References", "-- Global Variables", "-- Private Functions", "-- Class", "return table.freeze(entities)", ""])
destination = root / "src/Document/NamedEntities.luau"
destination.write_text("\n".join(lines), encoding="utf-8", newline="\n")
print(f"Generated {len(entries)} HTML named character references.")
