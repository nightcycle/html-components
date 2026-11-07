# MDN document workflow fixture

An unchanged copy of MDN's **Document and website structure** example, selected as the first complete-document import target. Open `index.html` in a browser; it links the adjacent `style.css`.

- [Live upstream page](https://mdn.github.io/learning-area/html/introduction-to-html/document_and_website_structure/)
- [Pinned source](https://github.com/mdn/learning-area/tree/21973263ba859ff3477919087b488157f9d618a6/html/introduction-to-html/document_and_website_structure)
- Repository: `mdn/learning-area`
- Revision: `21973263ba859ff3477919087b488157f9d618a6`
- Retrieved: 2026-11-06
- License: CC0-1.0; the upstream license is included as `LICENSE`. This applies to the vendored example, independently of this package's Apache-2.0 license.
- Changes to upstream HTML/CSS: none.

## Why this example

The page is small enough to debug while exercising a real document: doctype/head/body, relative stylesheet discovery, semantic header/navigation/article/section/sidebar/footer elements, headings and paragraphs, lists and links, search/submit inputs, descendant and attribute selectors, percentage widths/padding, relative font units, automatic margins, nested flex layouts, and text wrapping. It has no JavaScript, framework, build step, images, or application backend.

The HTML also links a Google Fonts stylesheet for Open Sans Condensed and Sonsie One. Those fonts are not vendored here. Online rendering uses them when available; offline rendering uses the CSS fallback fonts. A repeatable cross-engine visual comparison must explicitly select a font mapping or pin permitted local font files. Do not silently compare an online font capture against an offline fallback capture.

## Expected workflow

1. Parse the original HTML into the typed document tree, retaining attributes and source locations.
2. Discover the `style.css` link and resolve it relative to `index.html`; handle the separate external font stylesheet explicitly.
3. Compile CSS, preserve supported declarations, and report unsupported features without discarding the document.
4. Render the body through the existing Roblox component adapters, mapping navigation/input actions through application callbacks.
5. Compare document structure and browser/Studio geometry at the same viewport, font mapping, and scroll position.

This is a future acceptance fixture, not a currently passing `HTML.Content` input. The current XML-style fragment API rejects document metadata and several tags/attributes used here. Rendering also needs rem/em units, font-family fallbacks, browser default margins/list styling, content-box sizing, flex ratios, attribute selectors, `background`/`border` shorthands, text transformation/shadows, and search/submit input mapping for full visual parity. Keep the source unchanged so missing features remain visible.

It does not cover malformed HTML recovery, tables, images/media, grid, or responsive media queries. Existing nested-text fixtures remain useful alongside it; additional focused fixtures will be needed for those cases. Files in this directory are test inputs and are excluded from the Wally runtime package.

## SHA-256

| File | Hash |
| --- | --- |
| `index.html` | `8623d0ff8d0696128844a2315d8c23840cf839d52fab09fcd06eabb3e5e966ec` |
| `style.css` | `7da8ec4c700672e169dfd95a03bebacbcb31a6a595189854d91393f6a6dd0ee8` |
| `LICENSE` | `36ffd9dc085d529a7e60e1276d73ae5a030b020313e6c5408593a6ae2af39673` |
