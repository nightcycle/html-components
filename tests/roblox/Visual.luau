--!strict
-- Packages
local HTML = require(script.Parent.Parent.Packages.HTMLComponents)
local React = require(script.Parent.Parent.Packages.React)
local Roblox = require(script.Parent.Parent.Packages.RobloxComponents)
-- Modules
local Fixtures = require(script.Parent.Parent.VisualFixtures)
-- Types
export type Properties = { Children: React.ReactNode? }
-- Constants
local e = React.createElement
local components = (HTML.Tags :: unknown) :: { [string]: React.ElementType }
local kinds: { [string]: HTML.RenderKind } = {}
for _, entry in HTML.Catalog do
	kinds[entry.Tag] = entry.Kind
end
-- Private Functions
local function render(node: Fixtures.Node, order: number): React.ReactNode
	local children: { [string]: React.ReactNode } = {}
	local nodes: { Fixtures.Node } = node.Children or {}
	for index, child in nodes do
		children[child.Id] = render(child, index)
	end
	local component = assert(components[node.Tag], node.Tag)
	local kind = kinds[node.Tag]
	if kind == "Text" then
		local properties: HTML.PProperties = { Id = node.Id, Text = node.Text, LayoutOrder = order }
		return e(component, properties, children)
	elseif kind == "Button" then
		local properties: HTML.ButtonProperties = { Id = node.Id, Text = node.Text, LayoutOrder = order }
		return e(component, properties, children)
	elseif kind == "Input" then
		local properties: HTML.InputProperties = { Id = node.Id, Value = node.Text, LayoutOrder = order }
		return e(component, properties, children)
	elseif kind == "Meter" then
		local properties: HTML.ProgressProperties = { Id = node.Id, Value = node.Value, LayoutOrder = order }
		return e(component, properties, children)
	end
	local properties: HTML.DivProperties = { Id = node.Id, LayoutOrder = order }
	return e(component, properties, children)
end
-- Class
return function(): React.ReactNode
	local cells: { [string]: React.ReactNode } = {}
	for index, case in Fixtures.Cases do
		local x, y = (index - 1) % 3 * 328 + 20, math.floor((index - 1) / 3) * 232 + 28
		local titleProperties: HTML.SpanProperties = {
			Name = "Title",
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.fromOffset(288, 20),
			Text = case.Title,
			Css = { FontSize = 14 },
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = Color3.fromRGB(82, 97, 124),
			BackgroundTransparency = 1,
		}
		cells[`Case{index}`] = e(Roblox.Frame({
			Name = `Case{index}`,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(312, 216),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, {}, {
			Title = e(HTML.Span, titleProperties),
			Stage = e(Roblox.Frame({
				Position = UDim2.fromOffset(16, 32),
				Size = UDim2.fromOffset(280, 176),
				BackgroundTransparency = 1,
			}, {}, {
				Layout = e(Roblox.UIListLayout({
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}, {})),
				Sample = render(case.Node, 1),
			})),
		}))
	end
	local providerProperties: HTML.StyleProviderProperties = { CSS = Fixtures.CSS }
	return e(HTML.StyleProvider, providerProperties, {
		Board = e(Roblox.Frame({
			Name = "ParityBoard",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(Fixtures.Width, Fixtures.Height),
			BackgroundColor3 = Color3.fromRGB(226, 233, 244),
			BorderSizePixel = 0,
		}, {}, cells)),
	})
end
