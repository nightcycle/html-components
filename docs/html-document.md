# Experimental HTML document reader

`HTML.Document.parse(source)` reads UTF-8 HTML into a typed, ordered document tree. It does not create React elements or Roblox instances. `HTML.Content` continues to render its smaller XML-style fragment and typed table formats. A development-only adapter now previews document trees in the demo; a production document renderer remains future work.

```luau
local HTML = require(game.ReplicatedStorage.Packages.HTMLComponents)
local document: HTML.DocumentResult = HTML.Document.parse([[<!doctype html>
<html><head><link rel="stylesheet" href="page.css"></head>
<body><p class="Greeting">Hello <strong>world</strong>!</body></html>]])
if document.Success then
	local sources: { HTML.DocumentStyleSource } = HTML.Document.stylesheets(document)
	-- The application resolves sources, compiles CSS, and chooses rendering adapters.
	print(#document.Children, #sources)
end
```

## Public records

All types are exported from the Wally header. `DocumentResult` contains `Success`, `Children`, and `Diagnostics`. Each `DocumentNode` is discriminated by `Kind`: `Element`, `Text`, `Comment`, or `Doctype`. Their individual kind types, `DocumentNodeKind`, `DocumentNamespace`, `DocumentSeverity`, and `DocumentIssue` are exported too.

An element has PascalCase `Tag`, `Namespace` (`HTML`, `SVG`, or `MathML`), ordered `Attributes`, ordered `Children`, and optional `Location`. `SourceName` retains the HTML-normalized name or SVG-adjusted spelling. Attribute records contain PascalCase `Name`, semantic `SourceName`, decoded `Value`, and `Location`. For example, `aria-label` becomes `Name = "AriaLabel"` while retaining `SourceName = "aria-label"`. The ordered array preserves different raw names that normalize to the same PascalCase spelling. Boolean attributes have empty values. `Document.attribute(element, "aria-label")` looks up the raw name case-insensitively.

Text and attribute values are decoded once; script/style bodies remain literal. Unknown tags and attributes, including event-handler strings, are retained as data. The reader does not execute scripts, navigate, fetch resources, apply CSS, or sanitize HTML for browser use.

Locations use one-based original byte offsets, lines, and byte columns; implied elements have no location. Token values normalize CRLF/CR before decoding references. Diagnostics contain `Severity`, `Issue`, `Message`, and `Location`. Warnings describe recoveries; errors set `Success = false` while retaining the partial tree. Always check `Success`.

## Tested behavior and limits

Browser reference fixtures cover implicit HTML/head/body structure, comments, doctypes, case folding, quoted/unquoted/boolean attributes, void tags, duplicate attributes, custom elements, and selected paragraph/list/heading/option/table closing behavior. They also cover raw text, preformatted newlines, numeric/named references, SVG case adjustment/CDATA/foreignObject integration, and basic MathML integration.

This is not a complete WHATWG tree builder. Detected cases requiring template/noscript insertion modes, adoption-agency repair, nested-anchor reconstruction, table foster parenting, escaped script-data states, processing instructions, or legacy doctypes report errors. Other malformed combinations, scope rules, foreign-content breakouts, select/frameset handling, and browser quirks modes are not exhaustively implemented or diagnosed. `Success` means no detected fatal condition; it does not certify arbitrary input as browser-equivalent. Compare each new real document with the browser.

Limits: 1 MiB input, 20,000 nodes, 128 nested elements, and 100 stored diagnostics. Input must be UTF-8. This is a whole-document reader, not a context-sensitive fragment parser. It does not validate caller-created document tables. `Markup.validate` supports the renderer's smaller table format independently.

## Local workflow

In the demo, choose **Documents** in the sidebar. UI Labs exposes the same panel under **HTML Components → Documents → Document**. Preview renders supported tags/styles through the existing typed components; Structure shows the parsed tree; Diagnostics lists parser, stylesheet, and preview limitations. The standard demo includes an owned example with a linked stylesheet.

To include your ignored local HTML and its adjacent CSS in a separate development place:

```sh
lune run scripts/build-local path/to/index.html
```

Open `.tools/local-demo/html-components-demo.rbxl` and select **Documents → Local fixture**. The local build embeds only the supplied HTML and locally resolved stylesheets. It does not upload graphics or execute scripts. Its output is outside release artifact globs. Ordinary `scripts/build` and CI always produce the owned example with an empty local-fixture slot, verified during build.

The preview maps the component catalog, mixed text, IDs/classes, supported inline styles, input values, and meter values. Links/buttons preserve structured children and graphics. Unknown tags use diagnosed generic containers. Event handlers/navigation are not bound, and arbitrary HTML attributes are not forwarded to Roblox. Simple width media queries respond to the logical preview viewport. The supported CSS/layout subset is documented in [compatibility.md](compatibility.md); this is not a production import API.

For a local visual comparison, optionally prepare graphics and embed them in the local development build:

```sh
python scripts/capture-document.py path/to/index.html .tools/local-document/assets --width 1440 --height 1000
lune run scripts/build-local path/to/index.html .tools/local-document/assets/manifest.json
```

This requires Python, Playwright/Chromium, and Pillow. The capture disables document JavaScript and remote requests. It exports reference rectangles/screenshots, rasterizes local images and inline SVG paint, and writes raw RGBA files. Browser positions and computed layout styles are never renderer input. The optional manifest embeds compressed pixels only in the ignored local place; the demo creates and destroys EditableImages locally. No Roblox uploads are performed. Missing external graphics still produce diagnostics and may differ from the live website. Use the same document and viewport for graphics capture and comparison; SVG paint is a snapshot, not an interactive SVG renderer.

Save Studio geometry as `studio-bounds.json` (`Records` with `Name`, `X`, `Y`, `Width`, `Height`, `Visible`; plus `Viewport` and `Frame` rectangles) and its screenshot as `studio.jpg` beside the browser files. `python scripts/compare-document-layout.py .tools/local-document/assets` retains every matched rectangle difference and creates a cropped side-by-side image. Names use the document ID or the stable `HTML_` child-node path. Keep all reference content, graphics and reports ignored.

`Tests.Document()` checks native Instance requires, stylesheet discovery, the example's component tree, all inspector tabs, and any local fixture. `Tests.Stories()` mounts all 66 stories. Build validation checks that script child names do not collide with native Instance properties: the parser's source helper is named `SourceText` because `ModuleScript.Source` resolves to code text even when a child module has that name.

Keep third-party fixtures in an explicitly ignored directory and reports under ignored `build/`. CI and Wally/runtime builds do not require or include those fixtures.

```sh
lune run scripts/parse-document path/to/index.html build/document/local/parsed.json
python scripts/compare-document.py path/to/index.html build/document/local/parsed.json --capture
```

The first command runs the production parser, discovers linked/inline stylesheets in document order, and separately records `CSS.parse` diagnostics. Its file resolver supports ordinary relative paths beneath the HTML file's directory. It does not resolve `<base>`, network URLs, absolute paths, URL-encoded paths, or CSS imports. A loaded stylesheet or accepted rule count does not imply full style support.

The comparison requires Python, Playwright, and Chromium. An inert browser `DOMParser` supplies the reference: namespaces, names, every attribute value, text, comments, and child order are compared. Luau-only locations and PascalCase aliases are excluded; doctypes compare the supported name-only form. `--capture` also creates desktop (1440 × 1000) and mobile (390 × 844) previews with page JavaScript and remote requests disabled. Remote fonts/assets may differ from the live page. This does not validate Roblox rendering.

CI runs `tests/document.luau` through `scripts/check.luau`: 26 owned cases use checked-in reference trees from Chromium 156.0.8078.4. To intentionally refresh expectations after changing authored cases:

```sh
python scripts/compare-document.py tests/fixtures/document-cases.json tests/fixtures/document-cases.json --update-cases
lune run tests/document
```

Review changed expectations against browser behavior; do not replace an expected tree with Luau output to make a failure pass.

## Character-reference data

`src/Document/NamedEntities.luau` is generated from the WHATWG HTML Standard's [named character-reference data](https://html.spec.whatwg.org/entities.json), retrieved 2026-11-06. The JSON SHA-256 is `d741d877ac77c4194c4ad526b5b4a19aef8dfe411ab840a466891cdbb9f362e6`. The transformation removes leading ampersands from keys and writes codepoints as Luau escapes, preserving all 2,231 entries including legacy spellings.

Copyright © WHATWG (Apple, Google, Mozilla, Microsoft). Portions incorporated into source code use BSD-3-Clause under the [WHATWG publication policy](https://whatwg.org/ipr-policy#7.1). The [license notice](whatwg-license.txt) is also embedded in the generated module for model distribution. This data has its own license independently of the package's Apache-2.0 source.

Save the exact upstream JSON outside tracked source, then regenerate:

```sh
python scripts/generate-html-entities.py .tools/html-entities.json
stylua src/Document/NamedEntities.luau
```

The generator verifies the pinned hash before writing. A changed upstream file requires review and a hash update.
