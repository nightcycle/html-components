--!strict
-- Packages
local storage = script.Parent.Parent
local HTML = require(storage.Packages.HTMLComponents)
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
local Roblox = require(storage.Packages.RobloxComponents)
-- Modules
local Fixtures = require(storage.FlowFixtures)
-- Components
-- Contexts
-- Hooks
-- Types
-- Constants
local e = React.createElement
local components = (HTML.Tags :: unknown) :: { [string]: React.ElementType }
-- References
-- Global Variables
-- Private Functions
local function render(node: Fixtures.Node, order: number): React.ReactNode
	local children: { [string]: React.ReactNode } = {}
	local nodes: { Fixtures.Node } = node.Children or {}
	for index, child in nodes do
		children[child.Id] = render(child, index)
	end
	local properties: HTML.SpanProperties = { Id = node.Id, Text = node.Text, LayoutOrder = order }
	return e(assert(components[node.Tag]), properties, children)
end

local function view(): React.ReactNode
	local panes: { [string]: React.ReactNode } = {}
	for index, width in Fixtures.Widths do
		local titleStyle: HTML.Style = { FontWeight = "Bold" }
		local title: HTML.PProperties =
			{ Text = `{width}px container`, Position = UDim2.fromOffset(0, -32), CSS = titleStyle }
		panes[`Pane{index}`] = e(Roblox.Frame({
			Name = `Pane{index}`,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(if index == 1 then 24 else 308, 64),
			Size = UDim2.fromOffset(width, 420),
		}, {}, {
			Title = e(HTML.P, title),
			Content = e(
				HTML.StyleProvider,
				{ StyleSheet = HTML.CSS.parse(Fixtures.CSS) },
				{ Flow = render(Fixtures.Node, 1) }
			),
		}))
	end
	return e(Roblox.Frame({
		Name = "FlowComparison",
		Size = UDim2.fromOffset(772, 484),
		BackgroundColor3 = Color3.fromRGB(226, 233, 244),
		BorderSizePixel = 0,
	}, {}, panes))
end

local function verify(): string
	local screen = Instance.new("ScreenGui")
	screen.Name, screen.ScreenInsets = "HTMLFlowTest", Enum.ScreenInsets.None
	screen.Parent = game:GetService("StarterGui")
	local root = ReactRoblox.createRoot(screen)
	local ok, problem = pcall(function()
		ReactRoblox.act(function()
			root:render(e(view))
		end)
		task.wait(1)
		local board = screen:FindFirstChild("FlowComparison") :: Frame
		local pane = board:FindFirstChild("Pane1") :: Frame
		local flow = pane:FindFirstChild("Flow") :: Frame
		local copy = flow:FindFirstChild("Copy") :: TextLabel
		local bold = copy:FindFirstChild("Bold") :: TextLabel
		assert(bold:IsA("TextLabel") and #bold:GetChildren() > 0, "Strong retains a native root and fragments")
		local atomic = flow:FindFirstChild("Atomic") :: TextLabel
		local badge = atomic:FindFirstChild("Badge") :: TextLabel
		assert(
			math.abs(badge.AbsoluteSize.X - 92) < 1 and math.abs(badge.AbsoluteSize.Y - 42) < 1,
			"InlineBlock preserves explicit dimensions and constraints"
		)
		local first, second = flow:FindFirstChild("FirstBlock") :: Frame, flow:FindFirstChild("SecondBlock") :: Frame
		assert(
			math.abs(second.AbsolutePosition.Y - first.AbsolutePosition.Y - first.AbsoluteSize.Y - 14) < 1,
			"Block margins collapse in native geometry"
		)
		local before = copy.AbsoluteSize.Y
		pane.Size = UDim2.fromOffset(210, 420)
		task.wait(0.5)
		assert(copy.AbsoluteSize.Y > before, "Parent resizing reflows text without a React update")
		bold.Text = "New text "
		task.wait(0.5)
		local found = false
		for _, child in bold:GetChildren() do
			if child:IsA("TextLabel") and child.Text:find("New text", 1, true) then
				found = true
			end
		end
		assert(found, "Native Text changes invalidate measured fragments")
		badge.TextScaled = true
		task.wait(0.2)
		assert(
			badge.TextTransparency == 0 and not badge:FindFirstChild("HTMLInlineFragment"),
			"TextScaled retains native rendering"
		)
		local containerStyle: HTML.Style = { Width = 200 }
		local containerProps: HTML.DivProperties = { Name = "Switch", CSS = containerStyle }
		local centerStyle: HTML.Style = { Width = 100, MarginLeft = "Auto", MarginRight = "Auto" }
		local centerProps: HTML.PProperties =
			{ Name = "Centered", Text = "Centered", CSS = centerStyle, LayoutOrder = 2 }
		local function switch(mode: HTML.Display)
			local style: HTML.Style = { Display = mode, Width = 100, Height = 30, BackgroundColor = "#fef3c7" }
			local props: HTML.StrongProperties = { Name = "SwitchText", Text = "Box", CSS = style, LayoutOrder = 1 }
			ReactRoblox.act(function()
				root:render(
					e(HTML.Div, containerProps, { Text = e(HTML.Strong, props), Centered = e(HTML.P, centerProps) })
				)
			end)
			task.wait(0.3)
		end
		switch("InlineBlock")
		local container = screen:FindFirstChild("Switch") :: Frame
		local sized = container:FindFirstChild("SwitchText") :: TextLabel
		local centered = container:FindFirstChild("Centered") :: TextLabel
		assert(sized.AbsoluteSize == Vector2.new(100, 30), "InlineBlock dimensions apply")
		assert(
			centered.AbsolutePosition.X - container.AbsolutePosition.X == 50,
			"Horizontal auto margins center blocks"
		)
		switch("Inline")
		assert(sized.AbsoluteSize.X < 100 and sized.AbsoluteSize.Y < 30, "Inline ignores box width and height")
		local painted = sized:FindFirstChild("HTMLInlineFragment") :: TextLabel
		assert(
			sized.BackgroundTransparency == 1 and painted.BackgroundTransparency == 0,
			"Inline backgrounds follow fragments"
		)
		switch("None")
		assert(
			not sized.Visible and container.AbsoluteSize.Y == centered.AbsoluteSize.Y,
			"None contributes no layout height"
		)
	end)
	ReactRoblox.act(function()
		root:unmount()
	end)
	screen:Destroy()
	assert(ok, problem)
	return "Native inline flow, nested roots, InlineBlock constraints, margin collapse, resize and text invalidation passed."
end
-- Class
return { View = view, Verify = verify }
