# Browser and Studio visual validation

The shared fixtures in `tests/visual/Fixtures.luau` drive both real HTML elements in Chromium and React Luau components in `tests/roblox/Visual.luau`. They cover nine scenes and 26 component instances: containers, text, buttons, inputs, images, videos, meters, and spacers. This is representative renderer coverage, not a claim of full browser or all-device parity.

The HTML reference resets browser margins and uses border-box sizing, explicit typography, and normalized control colors. It uses the same bundled SourceSansPro font files as Roblox. Images and videos are empty media surfaces: asset decoding and playback are outside this comparison.

## Capturing the reference

```sh
lune run scripts/visual-reference
python scripts/capture-reference.py --font-directory PATH_TO_ROBLOX/content/fonts --device-scale 1.75
```

The optional Python tools require Playwright and Pillow. Install Chromium through `python -m playwright install chromium`. Set `--device-scale` to Studio's display density (1.75 for the validated 168-DPI window). Browser capture writes `build/visual/browser.png` and `browser-bounds.json`, plus font measurements, capture metadata, and Chromium's internal meter rectangles. It asserts that the meter's bar and fill occupy the host's full height. Fonts are copied only into ignored build output, not the Wally package.

## Capturing Studio

Open the rebuilt dev place. In a fresh Edit session, before requiring React, set the mock scheduler flags as described in the README's test instructions. Then mount the fixture:

```luau
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.DevPackages.ReactRoblox)
local Visual = require(game.ReplicatedStorage.Tests.Visual)
local gui = Instance.new("ScreenGui")
gui.Name = "HTMLVisualValidation"
gui.ScreenInsets = Enum.ScreenInsets.None
gui.Parent = game.StarterGui
local root = ReactRoblox.createRoot(gui)
ReactRoblox.act(function()
	root:render(React.createElement(Visual))
end)
-- Capture with Studio MCP screen_capture, then clean up:
-- ReactRoblox.act(function() root:unmount() end)
-- gui:Destroy()
```

Record each sample's `AbsolutePosition - ParityBoard.AbsolutePosition` and `AbsoluteSize`, alongside the board rectangle and `CurrentCamera.ViewportSize`, in `build/visual/studio-bounds.json`. Save the Studio screenshot as `studio-after.jpg`. `python scripts/compare-visual.py` checks the 26 element rectangles within a one-pixel tolerance and creates `comparison.png`. The comparison image crops and rescales the screenshot using the measured viewport and board coordinates; the original capture remains available.

## Observed result — 2026-11-05

At a 1510 × 1005 logical Studio viewport, the centered 1008 × 744 board matched all 26 browser element rectangles within 0.001 pixels (floating-point rounding). Screenshots exposed issues that geometry checks alone missed. Fixes made during this comparison:

- Convert CSS font size to Roblox's line-height units using the bundled font metrics.
- Center button and single-line input text while preserving explicit native alignment overrides.
- Include inside borders when calculating content padding.
- Round the outer meter-fill corners without rounding a partial-value edge.
- Give `Br` a zero-width box and inherited line height for vertical flow.

The follow-up comparison corrected two reference-harness bugs: captions previously bypassed CSS font-size conversion, and Chromium's absolutely positioned meter bar had a -10px vertical offset that clipped half of its fill. Captions now use `HTML.Span` with a 14px CSS size and an explicit SemiBold native face. The browser meter bar is explicitly anchored to its host, and its internal bar/fill rectangles are checked before capture. Browser capture uses the same 175% display density as Studio.

The main card heading uses the same SourceSansPro Bold/700 face on both sides. Its text width measured 153.27 CSS pixels in Chromium and 153.71 logical pixels in Studio (0.45px difference). Element bounds do not establish glyph-level parity: Roblox quantizes TextSize to integers, glyph advances and stroke rasterization differ, and Studio screenshots pass through JPEG capture/resampling. Shadow softness also remains approximate.

This comparison does not cover inline text-run layout, loaded media, hover/focus states, every font weight, or mobile safe areas. The validation used a temporary StarterGui with `ScreenInsets.None` in Edit mode; the place's orientation was LandscapeSensor. A simulator resolution probe did not change the Edit viewport; its scaling preference was restored and simulation was stopped. The temporary validation tree was removed afterward.

## Inline flow comparison — 2026-11-06

`tests/visual/FlowFixtures.luau` now supplies a second shared reference. It exercises a paragraph with its own text plus nested Strong/Em/Span children, an independently sized Strong badge, Br, and adjacent block margins at 260px and 440px container widths. Run:

```sh
lune run scripts/flow-reference
python scripts/capture-flow.py --font-directory PATH_TO_ROBLOX/content/fonts --device-scale 1.75
```

Mount `React.createElement(require(game.ReplicatedStorage.Tests.Layout).View)` in the temporary ScreenGui using the procedure above. This board starts at the viewport origin for deterministic screenshot cropping; the UI Labs version is centered by PreviewStage under **HTML Components → Div → Layout**. Record each pane descendant as `{ Pane, Id, Rect = { X, Y, Width, Height } }` and the camera viewport as `{ X, Y }`. Save `{ Records = records, Viewport = viewport }` to `build/visual/flow-studio.json`, and the MCP screenshot to `flow-studio.jpg`. Then run `python scripts/compare-flow.py`.

At a 1510 × 965 logical Studio viewport, all 12 block/inline-block rectangles matched within **0.797px**. Paragraph line counts, container heights, block positions, the 92 × 42 badge, and the collapsed 14px margin matched. The screenshot comparison is `build/visual/flow-comparison.png`. Text-root unions are reported separately in `flow-comparison.json`: their largest difference was 8.578px, accumulated across styled runs. Native font hinting, per-run advances and integer TextSize still prevent glyph-level parity. Measurements must use the rendered font size; oversampling TextService at a larger size compressed inter-element spaces in the screenshot and was rejected.

The original nine-scene reference was also recaptured: all 26 rectangles still matched within 0.0001px. Those fixtures now explicitly request flex-column stacks, block underline text, and a 20px spacer in the flex example so their reference does not depend on the former block defaults for inline tags.

`Tests.Layout.Verify()` additionally checks parent resizing without a React update, native text invalidation, auto-margin centering, Inline/InlineBlock/None transitions, dimensions/constraints, native TextScaled, and fragment backgrounds. All 64 stories and the gallery mounted; selective React-render tests still passed. These checks used Edit mode, temporary StarterGuis with `ScreenInsets.None`, and the existing LandscapeSensor orientation. No device-simulator settings were changed; temporary instances were removed afterward. This is a tested subset at two widths, not a guarantee for arbitrary imported HTML.

## Markup, table and React comparison — 2026-11-06

`tests/visual/MarkupFixtures.luau` contains the shared XML-style fragment and CSS. `tests/roblox/Markup.luau` independently constructs equivalent PascalCase table nodes and ordinary React components. Its six panes compare all three inputs at 300px and 220px widths, including nested bold/italic, underline plus strike-through, escaped literal tags, multi-line highlights, Br, and independently sized Strong/Em boxes.

```sh
lune run scripts/markup-reference
python scripts/capture-markup.py --font-directory PATH_TO_ROBLOX/content/fonts --device-scale 1.75
```

Mount `React.createElement(require(game.ReplicatedStorage.Tests.Markup).View, {})` using the Studio procedure above. The 1008 × 744 board starts at the viewport origin; the UI Labs story centers it under **HTML Components → Content**. Save the screenshot as `build/visual/markup-studio.jpg`. Record named descendants (`Card`, `Copy`, `Strong`, `Em`, `Underline`, `Both`, `Literal`, `Mark`, `Boxes`, `Badge`, `Sized`) for each `Pane11` through `Pane23` using the same `{ Records, Viewport }` shape as the flow comparison. Save to `markup-studio.json`, then run `python scripts/compare-markup.py`.

The current Studio capture uses a 1510 × 965 logical viewport, ScreenInsets.None, and the existing LandscapeSensor orientation. The 30 block/inline-block rectangles agree with Chromium within **1px for size and vertical position**, and **1.891px horizontally**. Text advances shift the second inline box slightly; the comparison bounds horizontal error separately at 3px. Inline text-root unions remain a separate measurement, with a largest difference of **9.594px**. Paragraph heights, wrapping, literal entity text, nested decorations and all three Roblox representations agree in the inspected screenshots. Bold italic is retained in the fixture; browser/engine glyph rasterization is not pixel-identical.

The comparison exposed a baseline bug when a tall bottom-aligned box shared a line with a middle-aligned badge. Flow now extends the line above the baseline for bottom alignment and below it for top alignment; two pure regression cases cover the correction. The final screenshot is `build/visual/markup-comparison.png`; `markup-comparison.json` retains all 66 rectangle differences rather than hiding text differences.

`Tests.Markup.Verify()` checks geometry equivalence among the three input paths, native refs and independent dimensions, nested RichText fragments, malformed-source cleanup, anonymous text avoiding Span selectors, direct-child selector ancestry, and stylesheet changes against stable parsed content. All five Studio suites passed, including 65 stories and the gallery, with no warnings or errors during the final run. The checks used an isolated copy of the current modules to avoid Studio's cached requires; temporary instances were removed afterward. CLI checks and the installed VS Code LSP both passed. CI runs parser/table and layout regressions plus package checks; screenshot capture still requires local Studio.

## Document demo smoke validation

The document reader now has a development preview under **HTML Components → Documents → Document** and the demo's **Documents** navigation. A fresh detached module tree successfully required the package in Studio, mounted all 66 stories plus the gallery, and passed `Tests.Document()` (stylesheet discovery, parsed native heading/mixed text, and all three inspector tabs). Edit-time captures verified the centered 1120 × 820 maximum panel and its scrolling preview. The owned example's HTML/CSS was also rendered in Chromium with Studio's Source Sans Pro fonts for visual inspection; this is a smoke comparison, not a measured parity assertion.

The optional local document also mounted and scrolled in Studio. Its initial preview exposed substantial unsupported CSS and graphics. The later comparison below records the improvements and remaining differences. Local fixture data is embedded only by `scripts/build-local` in `.tools/local-demo/`, outside release artifact outputs. The ordinary build checks that its fixture slot remains empty.

The `Source` child-module collision was reproduced on a real ModuleScript: `typeof(Document.Source)` was `string`. Renaming the helper to `SourceText` fixes native requires and UI Labs loading. Build verification now compares every script child's instance against native property lookup, catching collisions that a sourcemap or the pure-Luau loader can miss.

Story rendering alone does not validate UI Labs metadata. The Layout, Content, and Document story configurations incorrectly used `React`/`ReactRoblox`; UI Labs requires `react`/`reactRoblox`. These third-party API keys are intentionally case-sensitive exceptions to the package's PascalCase conventions. Build validation now evaluates every story factory with the installed UI Labs constructor and checks returned keys, library references, and render functions. The new check reproduced the old failure before the correction and then passed all 66 definitions. The Studio story suite also checks metadata before mounting.

## Responsive document comparison — 2026-11-06

An ignored local document was compared at logical widths of 1440 and 390 pixels. Chromium supplied screenshots and DOM rectangles. Studio rendered the original document and CSS through the development adapter, with local rasterized graphics supplied through an optional manifest. No browser layout positions or computed CSS were injected into the renderer. The capture/build procedure is in [html-document.md](html-document.md).

Repeated screenshots of the hero, navigation, logo grid, feature sections, pricing, FAQ and call-to-action drove fixes to width media queries, CSS variables and bounded calculations, rem/em lengths, numeric font weights, grid spans, intrinsic flex sizing, text wrapping, baselines, sibling spacing, margin collapse, image aspect ratios, layered shadows and padded inline links. The SVG file rasterizer now preserves the source viewBox aspect ratio. All third-party content, pixels, screenshots and comparison reports remain ignored; the scripts and owned regression fixtures are the reproducible tracked artifacts.

At 1440px, 331 visible element rectangles were matched. The header's 60px height matched exactly. The hero, both feature headings, trust heading and pricing heading were within 0.5px vertically; the FAQ heading was 2.33px high and the call-to-action heading 7.33px high. Total document height differed by about 9px across roughly 5000px. These are selected layout landmarks, not an assertion that every rectangle or pixel matches; the JSON report retains all differences.

At 390px, the header, hero and first feature heading matched position and dimensions within floating-point rounding. The second feature/trust headings drifted by 1–2px. Font substitution produced additional wrapped lines later in the document: the pricing heading was 21px low, FAQ 15px low and final call-to-action 58px low; total height differed by 57px. Fresh desktop/mobile Studio captures confirmed the column changes, stacked buttons and logo grid. Separate desktop captures inspected pricing shadows and the padded call-to-action.

Remaining differences include OS-font substitution (BuilderSans for browser system-ui), glyph advances/weight/rasterization, individual-side borders, multi-line inline decoration, missing remote media, general CSS features, and fixed positioning while scrolling. Scripts, menu toggling and accordion interactions were disabled in the reference and are not implemented by the adapter. This is substantially closer static rendering, not arbitrary website parity.

All seven Studio suites passed using a fresh detached copy of the modules: Integration, StyleUpdates, Stories (66), Layout, Markup, Document and Responsive. Responsive covers grid spans, viewport media changes, noninteger UIScale, natural image ratios, flex text, baseline alignment and inline padding that paints outside its line box. Pure checks and both the pinned and installed VS Code LSP passed. Screenshot capture requires a foreground Studio viewport on this machine; the experimental StudioCaptureService permission probe is unsupported and does not predict the MCP capture tool's availability.
