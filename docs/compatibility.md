# Compatibility contract for 0.1.0

This library provides visual mappings and a documented CSS subset. The component name alone does not imply DOM, browser layout, accessibility, navigation, or form behavior.

## Tags

| Tags | Roblox root | Supported behavior / limits |
| --- | --- | --- |
| `html body div main section article aside header footer nav form figure fieldset` | Frame | Vertical block flow by default, optional flex layout. `fieldset` adds padding/border. Forms do not submit, validate, serialize, or disable descendants. `html`/`body` do not create ScreenGuis. |
| `ul ol li dl dt dd` | Frame | Semantic grouping and flow only; no automatic bullets, numbering, indentation, or definition-list semantics. |
| `p span label legend figcaption abbr time output` | TextLabel | Plain text. Labels do not associate/focus controls; abbreviations do not create tooltips; time/output carry no browser semantics. |
| `h1 h2 h3 h4 h5 h6` | TextLabel | Bold text at 32/28/24/20/18/16 pixels. |
| `b strong` | TextLabel | Bold text. |
| `i em cite var address q` | TextLabel | Italic text; `q` does not synthesize language-sensitive quotation marks. |
| `s del u ins` | TextLabel | Escaped rich-text strike/underline decoration. |
| `code kbd samp pre` | TextLabel | Monospace font; `pre` preserves supplied line breaks without wrapping. |
| `small mark blockquote` | TextLabel | Smaller font, highlight background, or padded italic quote styling. |
| `a button` | TextButton | Activation, disabled state, native gamepad selection, and app-owned navigation callback. No browser URL navigation, downloads, targets, or form-submit defaults. |
| `input textarea` | TextBox | Single/multiple-line text, controlled/uncontrolled values, placeholder, readonly, disabled, input/commit callbacks. No input-type dispatch, password security, checkbox/radio/range/file/date/color controls, validation, or submission. |
| `img` | ImageLabel | Roblox image URI; `ScaleType` escape hatch. `Alt` is metadata, not a browser accessibility tree or automatic fallback. No web-image downloading. |
| `video` | VideoFrame | Roblox video URI and play/loop/mute properties. No browser codecs, web streams, poster/track controls, or automatic transport UI. |
| `progress meter` | Frame | Determinate clamped fill. No indeterminate animation or HTML low/high/optimum semantics. |
| `hr br` | Frame | `hr` is a block separator. `br` forces a line break in a flow container, using the inherited line height. |

Other tags are absent from `HTML.Tags`. In particular: document metadata/scripts/styles, embedded documents, audio, canvas, SVG/MathML, tables, select/option, details/summary, dialog, template/slot, ruby, and browser-specific APIs are not implemented. Do not silently substitute a supported tag when its behavior matters.

## CSS

Selectors: type, `*`, `.class`, `#id`, compound selectors, comma-separated selectors, descendant and direct-child (`>`) relationships; `:hover`, `:active`, `:focus`, `:disabled`. CSS escapes are decoded in identifiers, including utility classes such as `.hover\:active`, `.w-1\/2`, and `.p-2\.5`. Ancestry is the HTML component context tree, independent of intervening React providers. Native-only Roblox components do not add CSS selector ancestors.

| Properties | Accepted values / implementation |
| --- | --- |
| `display` | `block`, `inline`, `inline-block`, `flex`, `inline-flex`, `none`. Normal flow uses measured line boxes; flex uses UIListLayout. Hidden roots contribute no layout. |
| `width`, `height` | Pixel numbers/`px`, `%`, `auto`. Block width fills its container; inline-block auto width is capped max-content width. Normal non-replaced inline text ignores these dimensions. Sizes currently use border-box semantics. |
| `min-width`, `min-height`, `max-width`, `max-height` | Nonnegative pixels; UISizeConstraint. |
| `padding`, four padding sides | 1–4 nonnegative pixel/percentage values for the shorthand; UIPadding. |
| `margin`, four margin sides | Pixel/percentage lengths, including negatives; `auto` horizontal margins center or push a specified-width block. Adjacent block sibling vertical margins collapse. Parent/child and empty-block collapse are not implemented. |
| `gap` | Nonnegative pixel/percentage length; UIListLayout.Padding in flex. Retained as an extension between adjacent block children for compatibility; browser normal flow ignores gap. |
| `line-height` | `normal`, nonnegative unitless multiplier, or pixels. Inherited. Inline table form uses `"Normal"`, a number multiplier, or a `"24px"` string. |
| `vertical-align` | `baseline`, `top`, `middle`, `bottom` for inline fragments and inline blocks. Baselines use bundled font metrics. |
| `flex-direction`, `flex-wrap` | `row`/`column`, `nowrap`/`wrap`. Default flex direction is row. |
| `justify-content` | `flex-start`, `center`, `flex-end`, `space-between`, `space-around`, `space-evenly`; native list/flex alignment. |
| `align-items` | `flex-start`, `center`, `flex-end`; native cross-axis alignment. |
| `order`, `z-index` | Integers; LayoutOrder and ZIndex. |
| `background-color`, `color`, `border-color` | `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`, comma-form and space/slash `rgb()`/`rgba()` with numeric or percentage channels/alpha, plus black/white/red/green/blue/gray/grey/yellow/orange/purple/transparent. `var()`, `calc()`, and `none` channels are unsupported. |
| `font-size` | Nonnegative CSS em-size pixels, converted to Roblox TextSize line-height units using the bundled font metrics and rounded to integer pixels. Explicit native TextSize overrides this conversion. |
| `font-family` | Uses the first supported generic in a comma-separated fallback list: `sans-serif`, `serif`, `monospace` map to SourceSansPro, Merriweather, RobotoMono. Named fonts are skipped; a list with no supported generic produces a diagnostic. Quoted family names are not generics. |
| `font-weight`, `font-style` | `normal`/`bold`, `normal`/`italic`. |
| `text-align`, `text-decoration` | `left`/`center`/`right`; `none`/`underline`/`line-through`, including `underline line-through`. Table form uses `UnderlineLineThrough` for both. Decoration escapes text before adding Roblox RichText markup. |
| `white-space` | `normal`, `pre`, `pre-wrap`, `nowrap`. Flowing text collapses ASCII spaces/tabs/newlines across element boundaries or preserves them in pre modes. Tabs currently use four spaces, not CSS tab stops. |
| `border-width` | Nonnegative pixels; UIStroke with Border apply mode and Inner border position. |
| `border-radius`, four corner radii | Shorthand accepts 1–4 nonnegative lengths. Individual UICorner radii; one circular radius per corner, no elliptical `/` syntax. |
| `box-shadow` | One shadow: `[inset] x y blur [spread] color`, pixel lengths, nonnegative blur, color last; or `none`. Maps to UIShadow. |
| `overflow` | `visible`, `hidden`; ClipsDescendants. Scroll containers are supplied as native ScrollingFrames. |

Inline `CSS` uses PascalCase fields (`BackgroundColor`, `BorderTopRightRadius`) and PascalCase option values (`Display = "Flex"`, `FontFamily = "SansSerif"`). Named option types and all `ComponentNameProperties` types are exported directly from the package header. Numbers are pixels for lengths. Inline `Padding` and `BorderRadius` are a single length; use the side/corner fields for asymmetry. Raw HTML/CSS syntax is unchanged. Native property types remain those supplied by typed-instance-components.

Only color, font properties, line height, text alignment, and whitespace inherit. Borders, backgrounds, padding, dimensions, and layout do not. Text decoration propagates through inline descendants separately: a child's `None` does not remove its ancestor's decoration, and `InlineBlock`/`InlineFlex` starts a new decoration boundary. Decoration color/thickness and full CSS decoration painting are not implemented. Styles are authored in React; this package does not install a Roblox StyleSheet/StyleLink or arbitrate concurrent engine styling of the same properties.

There is no content-box sizing, positioned layout, flex-grow/shrink/basis, CSS grid, media/container queries, variables, at-rules, pseudo-elements, attribute/sibling selectors, transitions, animations, gradients, filters, transforms, multiple shadows, group opacity, or full CSS grammar. Unsupported declarations/selectors produce diagnostics. Unsupported at-rules are skipped as a whole. Valid declarations in a supported rule still apply.

## Inline formatting and remaining limits

Phrasing text tags default to `Inline`; paragraphs, headings and semantic containers remain blocks. A text component's own `Text` comes before its children. Nested inline text joins its parent's formatting context without losing its native root or CSS ancestry. Whitespace can cross element boundaries, but a style boundary alone cannot break a word. `InlineBlock` keeps its dimensions/constraints and wraps as one box. `InlineFlex` uses that outer behavior with a native inner list layout. Controls and media retain their existing default dimensions/display in this release; set `Display` explicitly when translating browser defaults.

Layout runs after React commits, uses cached TextService measurements, and updates on parent size, text, typography, visibility, and order changes. A geometry update does not schedule React renders. It currently recomputes the affected HTML root's flow, so it is not an incremental browser layout engine. Native-only children keep their own positioning and are not included in normal HTML flow; wrap them in an HTML container when they must occupy flow space.

The root of a wrapped inline element is the union of its fragment rectangles. Its hover/hit region is therefore rectangular, including gaps between lines. The renderer owns child positions, sizes and the root text transparency while drawing fragment labels; read the root `Text` for content. Native `TextScaled` retains engine text rendering. Inline backgrounds follow text fragments, but inline padding, borders, corners and shadows do not yet implement CSS box-decoration slicing. Use `InlineBlock` for a complete decorated box. Arbitrary native RichText formatting inside `Text`, native text alignment/scaling combined with fragmented children, custom-font baseline metrics, and UIScale-aware line measurement are not full parity paths.

Line breaking currently targets left-to-right text with whitespace-delimited words. CJK line-break rules, bidi, hyphenation, soft hyphens, `word-break`, `overflow-wrap`, browser whitespace edge cases, and full min-content shrink-to-fit are not implemented. An oversized unbroken word overflows. Block descendants inside an inline ancestor also need browser-style anonymous box splitting before they can be imported faithfully. These limits are not detected by the CSS parser; an importer must expose them rather than claim general HTML compatibility.

## Engine differences

Roblox UIListLayout/flex is an approximation of web layout. Set explicit dimensions when percentage children would otherwise depend on an automatically sized parent. Equal LayoutOrder values are not a document-order contract; assign orders when constructing a tree. Padding, stroke geometry, automatic sizing, text measurement, and available fonts differ from browsers.

UICorner percentages use the shorter parent dimension and do not clip descendants to the rounded outline. `overflow: hidden` clips a rectangle. UIShadow uses the engine's shape shadow behavior; inset shadows and shadows near clipping ancestors follow engine compositing. Meters clip a full-width rounded fill surface to the current fraction, preserving the track's outer corners and a straight partial-value edge. Browser-native meter skins can differ.

API references checked during implementation:

- [UIShadow](https://create.roblox.com/docs/reference/engine/classes/UIShadow) and [release announcement for shadows and individual corners](https://devforum.roblox.com/t/full-release-new-ui-capabilities-shadows-individual-corners/4636263).
- [UICorner](https://create.roblox.com/docs/reference/engine/classes/UICorner) for independent radius properties and descendant-clipping limits.
- [TextLabel.TextSize](https://create.roblox.com/docs/reference/engine/classes/TextLabel#TextSize) for Roblox's line-height sizing units. Font conversion factors use the installed font files' `hhea` and `head` metrics.
- [UIListLayout](https://create.roblox.com/docs/reference/engine/classes/UIListLayout) for flex, wrapping, and native layout.
- [Roblox UI styling](https://create.roblox.com/docs/ui/styling) for StyleLink scope and property ownership.

The connected Studio successfully created UIShadow, independent UICorner radii, and the newer UIStroke border-position property. Engine/API availability on a different target client remains a deployment requirement.

## XML-style fragments and table input

`HTML.Content` accepts a well-formed XML-style string or an ordered `{ HTML.ContentNode }` array. `HTML.Markup.parse` returns that tree; `HTML.Markup.validate` checks and copies table input. Public types are exported from the package header. The fragment component contributes no native wrapper or selector ancestor. Plain strings become anonymous text hosts that inherit typography without matching any tag selector. Parsed elements preserve their own native roots, CSS classes, and layout behavior. Table nodes additionally accept `Ref`.

The supported `ContentTag` subset is `Div`, `P`, `Span`, `Strong`, `B`, `Em`, `I`, `U`, `S`, `Del`, `Ins`, `Code`, `Kbd`, `Samp`, `Small`, `Mark`, `Abbr`, `Time`, `Output`, `Q`, `Cite`, `Var`, `Label`, and `Br`. Other library components remain available through ordinary React composition. They are not yet importable through `Content`. Parsed text lives in anonymous child text hosts; an element root's native `Text` is not an aggregate of its descendants. Keep the typed node tree when the application needs to inspect content.

String input recognizes these tag names case-insensitively, but opening/closing spelling must match exactly. Attributes are quoted lowercase `id`, `class`, and `style` only. Every paired tag must close; use `<br/>` or `<br></br>`. Text supports comments, CDATA, the five XML named entities, `nbsp`, and decimal/hex numeric references. Table input uses PascalCase `Tag`, `Id`, `ClassName`, `CSS`, `Text`, `Children`, `Ref`; text is literal and is not entity-decoded. `Text` is emitted before `Children`, and array order sets native `LayoutOrder`.

Malformed input, unsupported tags/attributes/style declarations, invalid UTF-8, cycles, sparse arrays, and limit violations fail the entire fragment with diagnostics. Limits: 64 nested elements, 10,000 nodes, 1 MiB of string source or table text/identifiers. Markup diagnostics identify one-based byte positions; table diagnostics provide field paths. Inline `!important` is rejected; parsed external `StyleSheet`s retain their existing cascade behavior. `OnDiagnostics` receives an empty array when a later source is valid.

This is not an HTML5 document parser or a parser for Roblox's entire RichText language. There are no optional closing tags, unquoted/boolean attributes, automatic paragraph repair, full HTML entity catalog, `<font>`/`<stroke>` commands, scripts, DTDs, network loading, or resource resolution. Native RichText is generated internally for supported decorations. Formatting tags still exist as independent elements; `InlineBlock` enables their own size, padding, and constraints. The inline layout limits above continue to apply.

## Future HTML importer

The typed node tree and XML-style parser provide the rendering path for mixed text. `HTML.Document.parse` now provides a separate experimental whole-document tree, including unknown tags/attributes, head metadata, SVG/MathML namespaces, character references, and selected HTML recovery rules. See [its API, tested subset, and browser comparison workflow](html-document.md). It is not yet connected to `Content` and is not a complete HTML5 tree builder.

The demo now includes a development adapter and an inspector for previewing supported document tags/styles. Unsupported graphics use placeholders; unknown tags use diagnosed generic containers. This adapter is not included in the Wally runtime. The next importer work is a production document renderer, resource/event mappings, and broader document styles. Layout priorities remain content-box sizing, min-content sizing, flex grow/shrink/basis, browser default styles and broader line-breaking rules. Unsupported browser behavior must remain visible through diagnostics.
