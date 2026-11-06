# Browser and Studio visual validation

The shared fixtures in `tests/visual/Fixtures.luau` drive both real HTML elements in Chromium and React Luau components in `tests/roblox/Visual.luau`. They cover nine scenes and 26 component instances: containers, text, buttons, inputs, images, videos, meters, and spacers. This is representative renderer coverage, not a claim of full browser or all-device parity.

The HTML reference resets browser margins and uses border-box sizing, explicit typography, and normalized control colors. It uses the same bundled SourceSansPro font files as Roblox. Images and videos are empty media surfaces: asset decoding and playback are outside this comparison.

## Capturing the reference

```sh
lune run scripts/visual-reference
python scripts/capture-reference.py --font-directory PATH_TO_ROBLOX/content/fonts
```

The optional Python tools require Playwright and Pillow. Install Chromium through `python -m playwright install chromium`. Browser capture writes `build/visual/browser.png` and `browser-bounds.json`. Fonts are copied only into ignored build output, not the Wally package.

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

Text rasterization, shadow softness, and Chromium's native meter fill thickness still differ. The fixture captions are native debug labels, not HTML components. This comparison does not cover inline text-run layout, loaded media, hover/focus states, every font weight, or mobile safe areas. The validation used a temporary StarterGui with `ScreenInsets.None` in Edit mode; the place's orientation was LandscapeSensor. No device simulation was active, and the temporary tree was removed afterward.
