--!strict
-- Services
-- Packages
local HTML = require(script.Parent.Packages.HTMLComponents)
local React = require(script.Parent.Packages.React)
local RobloxComponents = require(script.Parent.Packages.RobloxComponents)
-- Modules
-- Components
local Preview = require(script.Parent.Stories.Preview)
-- Hooks
-- Contexts
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function()
	local query, setQuery = React.useState("")
	local category, setCategory = React.useState("all")
	local dark, setDark = React.useState(false)
	local cards: { [string]: React.ReactNode } = {}
	local visible = 0
	for index, entry in HTML.Catalog do
		if
			(category == "all" or category == entry.Kind)
			and (query == "" or string.lower(entry.Tag):find(string.lower(query), 1, true))
		then
			visible += 1
			cards[entry.Tag] = e(
				RobloxComponents.Frame(
					{ BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, LayoutOrder = index },
					{},
					{
						Corner = e(RobloxComponents.UICorner({ CornerRadius = UDim.new(0, 12) }, {})),
						Tag = e(
							HTML.Code,
							{
								Text = `<{string.lower(entry.Tag)}>`,
								Position = UDim2.fromOffset(16, 12),
								Size = UDim2.new(1, -32, 0, 24),
								TextColor3 = Color3.fromRGB(53, 80, 178),
								TextSize = 18,
							} :: HTML.TextProperties
						),
						Kind = e(
							HTML.Small,
							{
								Text = entry.Kind,
								Position = UDim2.fromOffset(16, 38),
								Size = UDim2.new(1, -32, 0, 20),
								TextColor3 = Color3.fromRGB(107, 120, 147),
							} :: HTML.TextProperties
						),
						Stage = e(RobloxComponents.Frame({
							BackgroundTransparency = 1,
							Position = UDim2.fromOffset(16, 72),
							Size = UDim2.new(1, -32, 1, -88),
						}, {}, {
							Preview = e(Preview, { Tag = entry.Tag, Dark = dark } :: Preview.Properties),
						})),
					}
				)
			)
		end
	end
	cards.Layout = e(RobloxComponents.UIGridLayout({
		CellSize = UDim2.fromOffset(300, 248),
		CellPadding = UDim2.fromOffset(16, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, {}))
	cards.Padding =
		e(RobloxComponents.UIPadding({ PaddingBottom = UDim.new(0, 24), PaddingRight = UDim.new(0, 16) }, {}))
	local filters: { [string]: React.ReactNode } = {}
	for index, name in { "all", "Container", "Text", "Button", "Input", "Image", "Video", "Meter", "Spacer" } do
		filters[name] = e(
			HTML.Button,
			{
				Text = name,
				LayoutOrder = index,
				Css = {
					BackgroundColor = if category == name then "#536cff" else "#202e49",
					Color = "#e3eaff",
					Height = 36,
					TextAlign = "Left",
					PaddingLeft = 12,
				} :: HTML.Style,
				OnActivated = function()
					setCategory(name)
				end,
			} :: HTML.ButtonProperties
		)
	end
	return e(
		RobloxComponents.Frame(
			{ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(14, 23, 42), BorderSizePixel = 0 },
			{},
			{
				Sidebar = e(
					HTML.Nav,
					{ Position = UDim2.fromOffset(24, 24), Size = UDim2.new(0, 172, 1, -48), Css = { Gap = 8 } } :: HTML.ContainerProperties,
					{
						Brand = e(
							HTML.H2,
							{ Text = "HTML\nComponents", TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 1 } :: HTML.TextProperties
						),
						Subtitle = e(
							HTML.Small,
							{ Text = "REACT LUAU / 0.1.0", TextColor3 = Color3.fromRGB(142, 159, 194), LayoutOrder = 2 } :: HTML.TextProperties
						),
						Space = e(HTML.Br, { LayoutOrder = 3 } :: HTML.ContainerProperties),
						Filters = e(
							HTML.Div,
							{ LayoutOrder = 4, Css = { Gap = 6 } } :: HTML.ContainerProperties,
							filters
						),
						Theme = e(
							HTML.Button,
							{
								Text = if dark then "Preview: dark" else "Preview: light",
								LayoutOrder = 5,
								OnActivated = function()
									setDark(not dark)
								end,
							} :: HTML.ButtonProperties
						),
					}
				),
				Main = e(RobloxComponents.Frame({
					Position = UDim2.fromOffset(220, 0),
					Size = UDim2.new(1, -220, 1, 0),
					BackgroundColor3 = Color3.fromRGB(235, 240, 249),
					BorderSizePixel = 0,
				}, {}, {
					Heading = e(
						HTML.H1,
						{
							Text = "Native UI. Familiar tags.",
							Position = UDim2.fromOffset(24, 24),
							Size = UDim2.new(1, -48, 0, 44),
						} :: HTML.TextProperties
					),
					Description = e(
						HTML.P,
						{
							Text = `{visible} of {#HTML.Catalog} components · contextual CSS · typed Roblox roots`,
							Position = UDim2.fromOffset(24, 72),
							Size = UDim2.new(1, -48, 0, 24),
						} :: HTML.TextProperties
					),
					Search = e(
						HTML.Input,
						{
							Placeholder = "Find a tag…",
							Value = query,
							OnInput = setQuery,
							Position = UDim2.fromOffset(24, 112),
							Size = UDim2.new(1, -48, 0, 40),
							Css = { BorderRadius = 8 },
						} :: HTML.InputProperties
					),
					Gallery = e(RobloxComponents.ScrollingFrame({
						Position = UDim2.fromOffset(24, 176),
						Size = UDim2.new(1, -32, 1, -176),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						CanvasSize = UDim2.new(),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = 6,
					}, {}, cards)),
				})),
			}
		)
	)
end
