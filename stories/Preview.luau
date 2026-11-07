--!strict
-- Services
-- Packages
local HTML = require(script.Parent.Parent.Packages.HTMLComponents)
local React = require(script.Parent.Parent.Packages.React)
-- Modules
-- Components
local PreviewStage = require(script.Parent.PreviewStage)
-- Hooks
-- Contexts
-- Types
export type Properties = {
	Tag: string,
	Text: string?,
	Placeholder: string?,
	Disabled: boolean?,
	Value: number?,
	Radius: number?,
	Dark: boolean?,
	Inset: number?,
}
-- Constants
local components = (HTML.Tags :: unknown) :: { [string]: React.ElementType }
local kinds: { [string]: string } = {}
for _, entry in HTML.Catalog do
	kinds[entry.Tag] = entry.Kind
end

local sizes: { [string]: Vector2 } = {
	Container = Vector2.new(420, 180),
	Text = Vector2.new(320, 72),
	Button = Vector2.new(240, 44),
	Input = Vector2.new(320, 40),
	Image = Vector2.new(176, 176),
	Video = Vector2.new(480, 270),
	Meter = Vector2.new(320, 18),
	Spacer = Vector2.new(320, 16),
}
local tagSizes: { [string]: Vector2 } = {
	A = Vector2.new(260, 36),
	H1 = Vector2.new(380, 104),
	H2 = Vector2.new(360, 96),
	H3 = Vector2.new(340, 88),
	P = Vector2.new(360, 96),
	Pre = Vector2.new(420, 112),
	BlockQuote = Vector2.new(400, 112),
	TextArea = Vector2.new(420, 128),
	Hr = Vector2.new(360, 1),
	Br = Vector2.new(160, 16),
}
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local value, setValue = React.useState("")
	local clicks, setClicks = React.useState(0)
	local component = assert(components[props.Tag], `Unknown preview tag {props.Tag}`)
	local kind = kinds[props.Tag]
	local text = props.Text
		or (if props.Tag == "Pre" then "local greeting = 'Hello'\nprint(greeting)" else "The quick brown fox")
	local content: React.ReactNode
	if kind == "Container" then
		content = e(component, { Id = "sample", CSS = { Padding = 12, Gap = 6 } } :: HTML.ContainerProperties, {
			Title = e(HTML.H3, { Text = "A semantic container", LayoutOrder = 1 } :: HTML.TextProperties),
			Body = e(HTML.P, { Text = "Typography inherits through context.", LayoutOrder = 2 } :: HTML.TextProperties),
			Action = e(
				HTML.Button,
				{
					Text = `Clicked {clicks}`,
					LayoutOrder = 3,
					OnActivated = function()
						setClicks(clicks + 1)
					end,
				} :: HTML.ButtonProperties
			),
		})
	elseif kind == "Text" then
		content = e(
			component,
			{
				Id = "sample",
				Text = text,
				CSS = { Padding = 12 },
				TextYAlignment = Enum.TextYAlignment.Center,
			} :: HTML.TextProperties
		)
	elseif kind == "Button" then
		content = e(
			component,
			{
				Id = "sample",
				Text = `{text} · {clicks}`,
				Disabled = props.Disabled,
				Href = "/example",
				TextYAlignment = Enum.TextYAlignment.Center,
				OnActivated = function()
					setClicks(clicks + 1)
				end,
			} :: HTML.ButtonProperties
		)
	elseif kind == "Input" then
		content = e(
			component,
			{
				Id = "sample",
				Placeholder = props.Placeholder or "Type here…",
				Value = value,
				OnInput = setValue,
				Disabled = props.Disabled,
			} :: HTML.InputProperties
		)
	elseif kind == "Image" then
		content = e(
			component,
			{
				Id = "sample",
				Src = "rbxasset://textures/ui/GuiImagePlaceholder.png",
				Alt = "Roblox image placeholder",
			} :: HTML.ImageProperties
		)
	elseif kind == "Video" then
		content = e(component, { Id = "sample", Muted = true } :: HTML.VideoProperties, {
			Caption = e(
				HTML.P,
				{
					Text = "Set Src to a permitted Roblox video asset",
					TextColor3 = Color3.new(1, 1, 1),
					Size = UDim2.fromScale(1, 1),
					TextYAlignment = Enum.TextYAlignment.Center,
					TextXAlignment = Enum.TextXAlignment.Center,
				} :: HTML.TextProperties
			),
		})
	elseif kind == "Meter" then
		content = e(component, { Id = "sample", Value = props.Value or 0.65 } :: HTML.MeterProperties)
	else
		content = e(component, { Id = "sample" } :: HTML.ContainerProperties)
	end
	local background = if props.Dark then "#25314b" else "#f1f4fb"
	local foreground = if props.Dark then "#e8efff" else "#25314b"
	if props.Tag == "Hr" then
		background = foreground
	end
	return e(HTML.StyleProvider, {
		CSS = {
			["#sample"] = {
				Width = "100%",
				Height = "100%",
				BackgroundColor = background,
				Color = foreground,
				BorderRadius = props.Radius or 8,
			},
			["#sample:Hover"] = { BorderWidth = 1, BorderColor = "#6085ee" },
			["#sample:Disabled"] = { BackgroundColor = "#c6cddd", Color = "#707a90" },
			["#sample:Focus, #sample:Hover:Focus"] = { BorderWidth = 2, BorderColor = "#315fe8" },
		},
	}, {
		Stage = e(
			PreviewStage,
			{
				Size = tagSizes[props.Tag] or sizes[kind],
				Inset = props.Inset,
				AspectRatio = if kind == "Video" then 16 / 9 elseif kind == "Image" then 1 else nil,
			} :: PreviewStage.Properties,
			{ Sample = content }
		),
	})
end
