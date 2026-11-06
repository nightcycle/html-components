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
		return e(component, { Id = node.Id, Text = node.Text, LayoutOrder = order } :: HTML.PProperties, children)
	elseif kind == "Button" then
		return e(component, { Id = node.Id, Text = node.Text, LayoutOrder = order } :: HTML.ButtonProperties, children)
	elseif kind == "Input" then
		return e(component, { Id = node.Id, Value = node.Text, LayoutOrder = order } :: HTML.InputProperties, children)
	elseif kind == "Meter" then
		return e(
			component,
			{ Id = node.Id, Value = node.Value, LayoutOrder = order } :: HTML.ProgressProperties,
			children
		)
	end
	return e(component, { Id = node.Id, LayoutOrder = order } :: HTML.DivProperties, children)
end
-- Class
return function(): React.ReactNode
	local cells: { [string]: React.ReactNode } = {}
	for index, case in Fixtures.Cases do
		local x, y = (index - 1) % 3 * 328 + 20, math.floor((index - 1) / 3) * 232 + 28
		cells[`Case{index}`] = e(Roblox.Frame({
			Name = `Case{index}`,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(312, 216),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, {}, {
			Title = e(Roblox.TextLabel({
				Position = UDim2.fromOffset(12, 8),
				Size = UDim2.fromOffset(288, 20),
				Text = case.Title,
				TextSize = 14,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(82, 97, 124),
				BackgroundTransparency = 1,
			}, {})),
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
	return e(HTML.StyleProvider, { CSS = Fixtures.CSS } :: HTML.StyleProviderProperties, {
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
