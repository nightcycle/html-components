--!strict
-- Packages
local storage = script.Parent
local React = require(storage.Packages.React)
local Roblox = require(storage.Packages.RobloxComponents)
-- Modules
local example = require(script.Samples)
local localFixture = require(storage.LocalDocumentFixture)
local read = require(script.Reader)
-- Components
local PreviewStage = require(storage.Stories.PreviewStage)
-- Contexts
-- Hooks
-- Types
export type Tab = "Preview" | "Structure" | "Diagnostics"
export type Properties = { InitialLocal: boolean?, InitialTab: Tab? }
-- Constants
local e = React.createElement
local TABS: { Tab } = { "Preview", "Structure", "Diagnostics" }
-- References
-- Global Variables
-- Private Functions
local function label(
	name: string,
	text: string,
	position: UDim2,
	size: UDim2,
	fontSize: number,
	color: Color3
): React.ReactNode
	return e(Roblox.TextLabel({
		Name = name,
		Text = text,
		Position = position,
		Size = size,
		TextSize = fontSize,
		TextColor3 = color,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		BackgroundTransparency = 1,
	}, {}))
end
local function button(
	name: string,
	text: string,
	x: number,
	width: number,
	selected: boolean,
	enabled: boolean,
	callback: () -> ()
): React.ReactNode
	return e(Roblox.TextButton({
		Name = name,
		Text = text,
		Position = UDim2.fromOffset(x, 0),
		Size = UDim2.fromOffset(width, 34),
		TextSize = 17,
		TextColor3 = if enabled then Color3.fromRGB(235, 240, 255) else Color3.fromRGB(119, 133, 158),
		BackgroundColor3 = if selected then Color3.fromRGB(101, 82, 216) else Color3.fromRGB(37, 49, 75),
		BorderSizePixel = 0,
		Interactable = enabled,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
	}, { [React.Event.Activated] = callback }, { Corner = e(Roblox.UICorner({ CornerRadius = UDim.new(0, 7) }, {})) }))
end
-- Class
return function(props: Properties): React.ReactNode
	local localSample = localFixture.Sample
	local useLocal, setLocal = React.useState(props.InitialLocal == true)
	local tab, setTab = React.useState(props.InitialTab or "Preview")
	local sample = if useLocal and localSample then localSample else example
	local report = React.useMemo(function()
		return read(sample)
	end, { sample })
	local tabs: { [string]: React.ReactNode } = {}
	for index, name in TABS do
		tabs[name] = button(name, name, (index - 1) * 128, 116, tab == name, true, function()
			setTab(name)
		end)
	end
	local content: React.ReactNode = report.Preview
	if tab ~= "Preview" then
		local text = report.Tree
		if tab == "Diagnostics" then
			local lines = table.clone(report.Issues)
			if #lines == 0 then
				table.insert(lines, "No parser, CSS, or preview diagnostics for this example.")
			end
			text = table.concat(lines, "\n\n")
		end
		content = e(Roblox.TextLabel({
			Name = "InspectorText",
			Text = text,
			Size = UDim2.new(1, -32, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 15,
			TextColor3 = Color3.fromRGB(34, 48, 74),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json"),
		}, {}))
	end
	return e(PreviewStage, { Size = Vector2.new(1120, 820), Inset = 20 }, {
		Panel = e(Roblox.Frame({
			Name = "DocumentDemo",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(18, 29, 50),
			BorderSizePixel = 0,
		}, {}, {
			Title = label(
				"Title",
				"HTML document import",
				UDim2.fromOffset(24, 18),
				UDim2.new(1, -48, 0, 34),
				28,
				Color3.new(1, 1, 1)
			),
			Hint = label(
				"Hint",
				"Preview the supported HTML/CSS, then inspect the full tree and remaining gaps.",
				UDim2.fromOffset(24, 54),
				UDim2.new(1, -48, 0, 30),
				17,
				Color3.fromRGB(164, 180, 209)
			),
			Samples = e(Roblox.Frame({
				Position = UDim2.fromOffset(24, 90),
				Size = UDim2.new(1, -48, 0, 34),
				BackgroundTransparency = 1,
			}, {}, {
				Example = button("Example", "Example document", 0, 170, not useLocal, true, function()
					setLocal(false)
				end),
				Local = button(
					"Local",
					"Local fixture",
					182,
					140,
					useLocal and localSample ~= nil,
					localSample ~= nil,
					function()
						setLocal(true)
					end
				),
			})),
			Summary = label(
				"Summary",
				`{sample.Name} · {report.Elements} elements · {report.Attributes} attributes · {report.Stylesheets} stylesheets · {#report.Issues} diagnostics`,
				UDim2.fromOffset(24, 136),
				UDim2.new(1, -48, 0, 26),
				17,
				Color3.fromRGB(218, 226, 244)
			),
			Tabs = e(Roblox.Frame({
				Position = UDim2.fromOffset(24, 172),
				Size = UDim2.new(1, -48, 0, 34),
				BackgroundTransparency = 1,
			}, {}, tabs)),
			Content = e(Roblox.ScrollingFrame({
				Name = "DocumentViewport",
				Position = UDim2.fromOffset(24, 218),
				Size = UDim2.new(1, -48, 1, -256),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 6,
				ClipsDescendants = true,
			}, {}, {
				Padding = e(Roblox.UIPadding({
					PaddingTop = UDim.new(0, 20),
					PaddingLeft = UDim.new(0, 20),
					PaddingRight = UDim.new(0, 20),
					PaddingBottom = UDim.new(0, 20),
				}, {})),
				Content = content,
			})),
			Footer = label(
				"Footer",
				if localSample
					then "Local fixture is available only in this development place."
					else "To add your local HTML: lune run scripts/build-local path/to/index.html",
				UDim2.new(0, 24, 1, -28),
				UDim2.new(1, -48, 0, 20),
				14,
				Color3.fromRGB(164, 180, 209)
			),
		})),
	})
end
