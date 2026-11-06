# HTML Components

62 strictly typed React Luau components that map an explicit HTML/CSS subset to native Roblox UI. Includes contextual CSS, individual corners, native shadows, UI Labs stories, and a searchable development gallery.

This is a component foundation for an HTML importer. It does **not** parse HTML markup or implement a browser DOM. See [the compatibility contract](docs/compatibility.md) before translating web content.

## Install

The repository is prepared for Wally release `0.1.0`; publication is a separate release step.

```toml
[dependencies]
HTMLComponents = "nightcycle/html-components@^0.1.0"
React = "jsdotlua/react@17.2.1"
ReactRoblox = "jsdotlua/react-roblox@17.2.1"
```

The runtime depends on `nightcycle/typed-instance-components@^0.1.1`. Import the public Wally header, not its private child modules. Run `wally-package-types` with your Rojo sourcemap to expose the exported type aliases.

```luau
--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local HTML = require(game.ReplicatedStorage.Packages.HTMLComponents)
local e = React.createElement

return function()
	return e(HTML.StyleProvider, {
		CSS = {
			[".Card"] = {
				Padding = 24, Gap = 12, BackgroundColor = "#f1f4fb",
				BorderTopLeftRadius = 20, BorderTopRightRadius = 6,
				BorderBottomRightRadius = 20, BorderBottomLeftRadius = 6,
				BoxShadow = "0px 8px 20px #00000030",
			},
			[".Card > H2"] = { Color = "#315fe8" },
			[".Card Button:Hover"] = { BackgroundColor = "#5479ff" },
		},
	}, {
		Card = e(HTML.Article, {
			ClassName = "Card",
			Size = UDim2.fromOffset(460, 280),
		} :: HTML.ContainerProperties, {
			Title = e(HTML.H2, { Text = "Hello, Roblox", LayoutOrder = 1 } :: HTML.TextProperties),
			Body = e(HTML.P, { Text = "CSS follows the React tree.", LayoutOrder = 2 } :: HTML.TextProperties),
			Button = e(HTML.Button, {
				Text = "Continue", LayoutOrder = 3,
				OnActivated = function() print("Continue") end,
			} :: HTML.ButtonProperties),
		}),
	})
end
```

## Component conventions

Following `open-shl`, components expose a `Properties` type, return a React element, and construct their host with the typed instance builders. Every component's properties are exported from the public Wally header as `ComponentNameProperties`: for example, `HTML.DivProperties`, `HTML.H2Properties`, `HTML.TextareaProperties`, and `HTML.StyleProviderProperties`. The shared host-family properties remain available too. Consumers never need to index a Wally submodule for types.

- Components and tag identifiers use PascalCase (`HTML.Div`, `HTML.Tags.Div`, `HTML.Tags.H1`, `HTML.Textarea`). `HTML.Tag` is the exported tag union. `HTML.Catalog` lists PascalCase tags, component names, and renderer kinds. Raw CSS selectors retain normal HTML syntax (`div`, `h1`) and normalize during parsing.
- HTML-facing props are `Id`, `ClassName`, `CSS`, `Hidden`, `Text`, `Src`, `Href`, `Value`, and the control-specific props below. A future parser must normalize lowercase HTML attributes into this API.
- `CSS` is a typed inline `HTML.Style` record. It is named separately from Roblox's native `Frame.Style`/`TextButton.Style` enum property.
- Style fields and option values use PascalCase: `{ FontSize = 16, Display = "Flex", JustifyContent = "SpaceBetween" }`. Every string union has its own public type, including `HTML.Display`, `HTML.FontFamily`, `HTML.TextAlign`, `HTML.SelectorRelation`, and `HTML.RenderKind`. CSS text still uses `font-size: 16px; display: flex; justify-content: space-between`.
- Native host properties, non-string React event/change keys, and native children are forwarded through `typed-instance-components`. Explicit native properties override CSS-derived values. `Hidden`/`display: none` and disabled controls remain enforced.
- `Ref` reaches the actual root `GuiObject`. Use the capitalized prop; React's reserved `ref` is not forwarded by function components. Internal state listeners compose with incoming native listeners.
- Pass text through `Text`, and UI descendants through `Children` or the third argument to `createElement`. The React boundary adapts its reserved lowercase key internally. Raw string children are unsupported by ReactRoblox. Use `LayoutOrder` for deterministic sibling flow.
- Treat stylesheet and inline style tables as immutable. Replace them when changing styles.

### Inline layout

`Span`, `Strong`, `Em`, `Code`, and the other phrasing text tags now default to `Display = "Inline"`. Adjacent and nested text shares line boxes, collapses whitespace across component boundaries, and wraps at words. A component's `Text` precedes its children. `Br` ends the current line. Set `LayoutOrder` to preserve document order.

Use `InlineBlock` when a text element needs its own width, height, padding, or size constraints:

```luau
local badgeStyle: HTML.Style = {
	Display = "InlineBlock", Width = 96, Height = 40,
	MinWidth = 80, MaxWidth = 120, Padding = 8,
	VerticalAlign = "Middle", BackgroundColor = "#dbeafe",
}
local badge: HTML.StrongProperties = { Text = "Badge", CSS = badgeStyle }
local element = e(HTML.Strong, badge)
```

Normal inline text ignores box width/height and min/max dimensions inside a flow. Its root remains a `TextLabel`; wrapped fragments are native child labels, so nested components retain their identities and refs. `InlineBlock` remains an atomic box. `InlineFlex` combines an atomic outer box with the existing native flex layout.

`LineHeight = 1.5` is a font-size multiplier; `LineHeight = "24px"` is an absolute line height. `WhiteSpace` accepts `Normal`, `Nowrap`, `Pre`, and `PreWrap`. Block margins support negative lengths, horizontal `"Auto"` centering, and adjacent sibling vertical collapse. Parent/child margin collapse is not implemented. Layout measurements are cached and geometry updates run outside React; resizing does not render every component again. See [the layout limits](docs/compatibility.md) and [the browser comparison](docs/visual-validation.md).

`StyleProvider.CSS` accepts a selector map of type `HTML.StyleMap`. Tag names and pseudo states use PascalCase (`Button:Hover`, `Input:Focus`, `Button:Disabled`). Class names and IDs are case-sensitive identifiers that must match `ClassName` and `Id`. Nested providers append rules while retaining ancestry and inherited typography. They introduce no Roblox instance:

```luau
local css: HTML.StyleMap = {
	[".Primary"] = { FontSize = 16 },
	Button = { FontWeight = "Bold" },
	["Button:Hover"] = { BackgroundColor = "#315fe8" },
}
local properties: HTML.StyleProviderProperties = { CSS = css }
local element = e(HTML.StyleProvider, properties, children)
```

Map keys are sorted alphabetically: when two selectors have equal specificity, the alphabetically later key wins. Table insertion order and `ClassName` order do not affect the result. Use more specific selectors to express an override. Comma-separated selector groups are supported. Map declarations use the same PascalCase fields and option values as inline `CSS`; unsupported fields and selectors produce diagnostics.

`HTML.CSS.fromMap(css)` compiles a map for the optional `StyleSheet` prop. For importing browser CSS, `HTML.CSS.parse(text)` remains available and preserves textual source order and `!important`; pass its returned table through `StyleSheet`. The `CSS` provider prop accepts a selector map, not a string.

The cascade is inherited typography → tag defaults → matching normal rules (specificity, then source order) → inline `CSS` → matching `!important` declarations. Native props are the final Roblox escape hatch. Unsupported CSS is omitted with diagnostics; providers also log these diagnostics once when their stylesheet inputs change.

Style contexts hold stable subscription scopes. Stylesheet updates compare each element's resolved style field by field and schedule React updates only for changed results. Changing `.notice` leaves unrelated elements out of React rendering; inherited typography still reaches descendants that have not overridden it. Ancestor state and class changes still affect descendant selectors. A local background or padding change does not propagate to descendants.

Replacing a stylesheet still runs style resolution through its subtree; rules are not yet indexed by class. These subscriptions prevent style-driven renders, not ordinary renders caused by an application's parent rebuilding children or changing props. Keep child elements stable or use `React.memo` where those parent renders matter. Continue replacing style tables instead of mutating them in place.

## Controls and assets

| Component | Props and behavior |
| --- | --- |
| `Button`, `A` | `OnActivated: () -> ()`, `Disabled`; links call `OnNavigate(Href)` when supplied. Navigation is application-owned. |
| `Input`, `Textarea` | Text inputs. `Value` is controlled; `DefaultValue` initializes uncontrolled state. `OnInput(string)`, `OnCommit(string, enterPressed)`, `Placeholder`, `ReadOnly`, `Disabled`. `Text` is an initial-value alias; use `Value` for updates. |
| `Img` | `Src` maps to `ImageLabel.Image`; native `ScaleType` remains available. `Alt` is metadata only. |
| `Video` | `Src`, `AutoPlay`, `Loop`, `Muted`, plus native VideoFrame properties. Requires a permitted Roblox video asset. |
| `Progress`, `Meter` | `Value`, `Min` (default 0), `Max` (default 1), `FillColor`. Clamps the visual fill; invalid ranges render empty. |

## Development

Install Rokit, then run from this repository:

```sh
rokit install
lune run scripts/setup
lune run scripts/check
lune run scripts/build
rojo serve dev.project.json
```

Open **`build/html-components-demo.rbxl`** in Studio and press Play for the gallery. Or connect Rojo to the dev project. In UI Labs, select **HTML Components**: every exported tag has a centered, bounded preview sized for its function, plus a CSS/provider example. Controls are specific to each component: text for labels/buttons, placeholders for text inputs, disabled state for interactive controls, value sliders for meters, and theme/corner-radius controls where applicable.

Outputs:

- `build/html-components-demo.rbxl`: standalone place, including dependencies, demo, stories, and Studio smoke tests.
- `build/html-components.rbxm`: runtime ModuleScript; requires sibling `React` and `RobloxComponents` dependencies.
- `build/html-components-0.1.0.zip`: Wally package, excluding development assets and dependencies.

Source follows the `open-shl` React layout and section headings:

```text
src/React/
  Component/
    Button/
      init.luau
      Button.story.luau
    StyleProvider/
      init.luau
      StyleProvider.story.luau
  Context/Style.luau
  Hook/useStyle.luau
  Render/
    Button.luau
    Container.luau
    Input.luau
    ...
```

Each component exports `Properties` and an explicit component function. Shared rendering is split by host family; CSS remains in `src/CSS`. Stories sit alongside their components and are excluded from the runtime model and Wally archive. The dev project includes them, and `stories/HTML.storybook.luau` organizes them under **HTML Components**.

`scripts/tags.luau` owns the tag catalog and default styles. Run `lune run scripts/generate` after editing it; commit the component folders, header, catalog, stories, and Wally directory list together. Generated source uses the same StyLua settings as `open-shl`; the check command detects drift.

Local checks cover CSS parsing/cascade/selector behavior, selective style notifications (including 500 subscribers), generated story coverage, all 63 component property exports through the package header, formatting, strict runtime **and tooling** analysis, and 17 fixtures that must fail type checking. Build checks compile the runtime and demo and verify Wally contents. GitHub CI performs these checks; it does not run Studio.

The editor uses the Luau LSP extension's automatically updated Roblox definitions. The pinned `.tools/globalTypes-*.d.luau` file is used only by the command-line checks; loading it again through `luau-lsp.types.definitionFiles` creates conflicting enum types (`@roblox` versus `@roblox0`). After changing these settings, restart the Luau language server if old diagnostics remain.

For actual ReactRoblox smoke tests, open a fresh demo place and run this in the Studio command bar **before requiring React or ReactRoblox**:

```luau
_G.__DEV__ = true
_G.__ROACT_17_MOCK_SCHEDULER__ = true
print(require(game.ReplicatedStorage.Tests.Integration)())
print(require(game.ReplicatedStorage.Tests.StyleUpdates)())
print(require(game.ReplicatedStorage.Tests.Stories)())
print(require(game.ReplicatedStorage.Tests.Layout).Verify())
```

The tests clean up their targets; the layout test uses a temporary StarterGui so the engine can compute geometry. Reopen the place before normal Play testing so the mocked scheduler does not affect the demo. Development validation mounts all 62 tags, 64 stories (including the inline layout comparison under **HTML Components → Div → Layout**), and the gallery. `StyleUpdates` verifies actual render invocations and committed updates, accounting for development Strict Mode's double invocation. The shared browser/Studio fixtures cover the original nine scenes and nested inline layout at two widths. See [the screenshot comparison workflow and measured limits](docs/visual-validation.md).

## Releases

CI/CD follows `typed-instance-components`, adapted to this repository's setup/check/build commands and `build/` outputs. CI runs on pull requests and main-branch pushes, verifies that dependency installation leaves `wally.lock` unchanged, and uploads the build artifacts. Actions and tools are pinned.

1. Configure the repository secret `WALLY_AUTH_TOKEN` for the `nightcycle` scope.
2. Update `wally.toml`, run `wally install` to refresh the lockfile, then run setup, checks, and build.
3. Commit/push the validated source and lockfile, then push the matching stable tag: either `v0.1.0` or `0.1.0`.

The Release workflow tries the requested tag spelling first, then its alternate spelling, and checks out that exact existing commit. It verifies the manifest version, reruns checks/builds and the lockfile check, publishes Wally, then uploads GitHub release assets. Existing GitHub releases are found under either spelling and their assets are updated. Stable versions with leading zeros or prerelease suffixes are rejected. Releases are serialized so alternate spellings cannot publish concurrently.

A missing token or unconfirmed Wally publication fails the release. For retrying GitHub assets after Wally already succeeded, manually dispatch with `publish_wally` disabled. Wally versions are immutable; changed code needs a new version.

No publication occurs on ordinary CI runs.
