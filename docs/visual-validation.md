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
