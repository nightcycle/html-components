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
		CSS = [[
			.card { padding: 24px; gap: 12px; background-color: #f1f4fb;
				border-radius: 20px 6px 20px 6px;
				box-shadow: 0px 8px 20px #00000030; }
			.card > h2 { color: #315fe8; }
			.card button:hover { background-color: #5479ff; }
		]],
	}, {
		Card = e(HTML.Article, {
			ClassName = "card",
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
- HTML-facing props are `Id`, `ClassName`, `Css`, `Hidden`, `Text`, `Src`, `Href`, `Value`, and the control-specific props below. A future parser must normalize lowercase HTML attributes into this API.
- `Css` is a typed inline `HTML.Style` record. It is named separately from Roblox's native `Frame.Style`/`TextButton.Style` enum property.
- Style fields and option values use PascalCase: `{ FontSize = 16, Display = "Flex", JustifyContent = "SpaceBetween" }`. Every string union has its own public type, including `HTML.Display`, `HTML.FontFamily`, `HTML.TextAlign`, `HTML.SelectorRelation`, and `HTML.RenderKind`. CSS text still uses `font-size: 16px; display: flex; justify-content: space-between`.
- Native host properties, non-string React event/change keys, and native children are forwarded through `typed-instance-components`. Explicit native properties override CSS-derived values. `Hidden`/`display: none` and disabled controls remain enforced.
- `Ref` reaches the actual root `GuiObject`. Use the capitalized prop; React's reserved `ref` is not forwarded by function components. Internal state listeners compose with incoming native listeners.
- Pass text through `Text`, and UI descendants through `Children` or the third argument to `createElement`. The React boundary adapts its reserved lowercase key internally. Raw string children are unsupported by ReactRoblox. Use `LayoutOrder` for deterministic sibling flow.
- Treat stylesheet and inline style tables as immutable. Replace them when changing styles.

`StyleProvider` accepts a CSS string and/or a precompiled stylesheet. Nested providers append rules while retaining ancestry and inherited typography. They introduce no Roblox instance:

```luau
local sheet = HTML.CSS.parse("p { color: #315fe8; }")
for _, diagnostic in sheet.Diagnostics do
	warn(diagnostic.Message, diagnostic.Source)
end
local element = e(HTML.StyleProvider, { StyleSheet = sheet }, children)
```

The cascade is inherited typography → tag defaults → matching normal rules (specificity, then source order) → inline `Css` → matching `!important` declarations. Native props are the final Roblox escape hatch. Unsupported CSS is omitted with diagnostics; providers also log these diagnostics once when their stylesheet inputs change.

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

Local checks cover CSS parsing/cascade/selector behavior, generated story coverage, all 63 component property exports through the package header, formatting, strict runtime **and tooling** analysis, and 14 fixtures that must fail type checking. Build checks compile the runtime and demo and verify Wally contents. GitHub CI performs these checks; it does not run Studio.

The editor uses the Luau LSP extension's automatically updated Roblox definitions. The pinned `.tools/globalTypes-*.d.luau` file is used only by the command-line checks; loading it again through `luau-lsp.types.definitionFiles` creates conflicting enum types (`@roblox` versus `@roblox0`). After changing these settings, restart the Luau language server if old diagnostics remain.

For actual ReactRoblox smoke tests, open a fresh demo place and run this in the Studio command bar **before requiring React or ReactRoblox**:

```luau
_G.__DEV__ = true
_G.__ROACT_17_MOCK_SCHEDULER__ = true
print(require(game.ReplicatedStorage.Tests.Integration)())
print(require(game.ReplicatedStorage.Tests.Stories)())
```

The tests use detached targets and clean them up. Reopen the place before normal Play testing so the mocked scheduler does not affect the demo. Development validation mounted all 62 tags, all 63 stories, and the gallery in Studio. The shared browser/Studio visual fixtures also compare nine scenes across all eight renderer families. See [the screenshot comparison workflow and measured limits](docs/visual-validation.md).

## Releases

CI/CD follows `typed-instance-components`, adapted to this repository's setup/check/build commands and `build/` outputs. CI runs on pull requests and main-branch pushes, verifies that dependency installation leaves `wally.lock` unchanged, and uploads the build artifacts. Actions and tools are pinned.

1. Configure the repository secret `WALLY_AUTH_TOKEN` for the `nightcycle` scope.
2. Update `wally.toml`, run `wally install` to refresh the lockfile, then run setup, checks, and build.
3. Commit/push the validated source and lockfile, then push the matching stable tag: either `v0.1.0` or `0.1.0`.

The Release workflow tries the requested tag spelling first, then its alternate spelling, and checks out that exact existing commit. It verifies the manifest version, reruns checks/builds and the lockfile check, publishes Wally, then uploads GitHub release assets. Existing GitHub releases are found under either spelling and their assets are updated. Stable versions with leading zeros or prerelease suffixes are rejected. Releases are serialized so alternate spellings cannot publish concurrently.

A missing token or unconfirmed Wally publication fails the release. For retrying GitHub assets after Wally already succeeded, manually dispatch with `publish_wally` disabled. Wally versions are immutable; changed code needs a new version.

No publication occurs on ordinary CI runs.
