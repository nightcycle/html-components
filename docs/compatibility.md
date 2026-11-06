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
| `hr br` | Frame | 1px separator or a zero-width spacer using the inherited font's line height (20px for the default 16px sans-serif font); not an inline line-breaking algorithm. Explicit CSS dimensions remain available. |

Other tags are absent from `HTML.Tags`. In particular: document metadata/scripts/styles, embedded documents, audio, canvas, SVG/MathML, tables, select/option, details/summary, dialog, template/slot, ruby, and browser-specific APIs are not implemented. Do not silently substitute a supported tag when its behavior matters.

## CSS

Selectors: type, `*`, `.class`, `#id`, compound selectors, comma-separated selectors, descendant and direct-child (`>`) relationships; `:hover`, `:active`, `:focus`, `:disabled`. Ancestry is the HTML component context tree, independent of intervening React providers. Native-only Roblox components do not add CSS selector ancestors.

| Properties | Accepted values / implementation |
| --- | --- |
| `display` | `block`, `flex`, `none`. Hiding removes the root from Roblox layout via `Visible`. |
| `width`, `height` | Pixel numbers/`px`, `%`, `auto`; UDim2 and AutomaticSize. Default width fills the parent and default height grows with content. |
| `min-width`, `min-height`, `max-width`, `max-height` | Nonnegative pixels; UISizeConstraint. |
| `padding`, four padding sides | 1–4 nonnegative pixel/percentage values for the shorthand; UIPadding. |
| `gap` | Nonnegative pixel/percentage length; UIListLayout.Padding. |
| `flex-direction`, `flex-wrap` | `row`/`column`, `nowrap`/`wrap`. Default flex direction is row. |
| `justify-content` | `flex-start`, `center`, `flex-end`, `space-between`, `space-around`, `space-evenly`; native list/flex alignment. |
| `align-items` | `flex-start`, `center`, `flex-end`; native cross-axis alignment. |
| `order`, `z-index` | Integers; LayoutOrder and ZIndex. |
| `background-color`, `color`, `border-color` | `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`, comma-form `rgb()`/`rgba()`, plus black/white/red/green/blue/gray/grey/yellow/orange/purple/transparent. |
| `font-size` | Nonnegative CSS em-size pixels, converted to Roblox TextSize line-height units using the bundled font metrics and rounded to integer pixels. Explicit native TextSize overrides this conversion. |
| `font-family` | `sans-serif`, `serif`, `monospace`; SourceSansPro, Merriweather, RobotoMono. |
| `font-weight`, `font-style` | `normal`/`bold`, `normal`/`italic`. |
| `text-align`, `text-decoration` | `left`/`center`/`right`; `none`/`underline`/`line-through`. Decoration escapes text before adding Roblox RichText markup. |
| `white-space` | `normal`, `pre`, `nowrap`; controls wrapping only. Supply normalized whitespace yourself. |
| `border-width` | Nonnegative pixels; UIStroke with Border apply mode and Inner border position. |
| `border-radius`, four corner radii | Shorthand accepts 1–4 nonnegative lengths. Individual UICorner radii; one circular radius per corner, no elliptical `/` syntax. |
| `box-shadow` | One shadow: `[inset] x y blur [spread] color`, pixel lengths, nonnegative blur, color last; or `none`. Maps to UIShadow. |
| `overflow` | `visible`, `hidden`; ClipsDescendants. Scroll containers are supplied as native ScrollingFrames. |

Inline `Css` uses PascalCase fields (`BackgroundColor`, `BorderTopRightRadius`) and PascalCase option values (`Display = "Flex"`, `FontFamily = "SansSerif"`). Named option types and all `ComponentNameProperties` types are exported directly from the package header. Numbers are pixels for lengths. Inline `Padding` and `BorderRadius` are a single length; use the side/corner fields for asymmetry. Raw HTML/CSS syntax is unchanged. Native property types remain those supplied by typed-instance-components.

Only color, font properties, text alignment, and whitespace inherit. Borders, backgrounds, padding, dimensions, and layout do not. Text decoration is local in this version. Styles are authored in React; this package does not install a Roblox StyleSheet/StyleLink or arbitrate concurrent engine styling of the same properties.

There is no CSS margin/collapsing, content-box sizing, inline formatting across separate text nodes, positioned layout, flex-grow/shrink/basis, CSS grid, media/container queries, variables, at-rules, pseudo-elements, attribute/sibling selectors, transitions, animations, gradients, filters, transforms, multiple shadows, group opacity, or full CSS grammar. Unsupported declarations/selectors produce diagnostics. Unsupported at-rules are skipped as a whole. Valid declarations in a supported rule still apply.

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

## Future HTML importer

An importer can normalize attributes, dispatch known tags through `HTML.Tags`, assign LayoutOrder from document order, translate text runs into `Text`, and pass parsed stylesheets to StyleProvider. It must explicitly report unsupported tags, attributes, CSS, and browser behaviors. Mixed inline markup needs a separate rich-text/run-layout design before general HTML can be represented faithfully. HTML tokenization, entities, error recovery, resource loading, DOM events, and sanitization are intentionally outside this package's current API.
