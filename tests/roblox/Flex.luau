--!strict
-- Packages
local storage = script.Parent.Parent
local HTML = require(storage.Packages.HTMLComponents)
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
-- Modules
-- Components
-- Contexts
-- Hooks
-- Types
-- Constants
local e = React.createElement
-- References
-- Global Variables
-- Private Functions
local function near(actual: number, expected: number, label: string)
	assert(math.abs(actual - expected) < 1, `{label}: expected {expected}, received {actual}`)
end
-- Class
return function(): string
	local screen = Instance.new("ScreenGui")
	screen.Name = "HTMLFlexRegression"
	screen.Parent = game:GetService("StarterGui")
	local root = ReactRoblox.createRoot(screen)
	local function mount(style: HTML.Style, children: { [string]: React.ReactNode }): GuiObject
		root:render(e(HTML.Div, { Name = "Container", CSS = style } :: HTML.DivProperties, children))
		task.wait(0.2)
		return screen:FindFirstChild("Container") :: GuiObject
	end
	local function child(parent: Instance, name: string): GuiObject
		return assert(parent:FindFirstChild(name)) :: GuiObject
	end
	local ok, problem = pcall(function()
		local container = mount({ Display = "Flex", Width = 200, Height = 100, AlignItems = "Center" }, {
			Item = e(HTML.Div, { Name = "Item", CSS = { Width = 40, Height = 20 } } :: HTML.DivProperties),
		})
		near(child(container, "Item").AbsolutePosition.Y - container.AbsolutePosition.Y, 40, "Fixed-height row centers")
		container = mount({ Display = "Flex", Width = 200, MinHeight = 100, AlignItems = "Center" }, {
			Item = e(
				HTML.Div,
				{ Name = "Item", CSS = { Width = 40, Height = 20, MarginTop = 10, MarginBottom = 30 } } :: HTML.DivProperties
			),
		})
		near(
			child(container, "Item").AbsolutePosition.Y - container.AbsolutePosition.Y,
			30,
			"Min-height row centers margin box"
		)
		container = mount(
			{ Display = "Flex", FlexDirection = "Column", Width = 200, Height = 200, Padding = 10, Gap = 10 },
			{
				Header = e(
					HTML.Div,
					{ Name = "Header", LayoutOrder = 1, CSS = { Height = 40, FlexShrink = 0 } } :: HTML.DivProperties
				),
				Body = e(HTML.Div, { Name = "Body", LayoutOrder = 2, CSS = { FlexGrow = 1 } } :: HTML.DivProperties, {
					Fill = e(HTML.Div, { Name = "Fill", CSS = { Height = "100%" } } :: HTML.DivProperties),
				}),
			}
		)
		local body = child(container, "Body")
		near(body.AbsoluteSize.Y, 130, "Column grows into content height")
		near(child(body, "Fill").AbsoluteSize.Y, 130, "Percentage height uses grown parent")
		near(body.AbsolutePosition.Y - container.AbsolutePosition.Y, 60, "Column gap and padding")
		container = mount(
			{ Display = "Flex", FlexDirection = "Column", Width = 200, Height = 100, JustifyContent = "SpaceBetween" },
			{
				First = e(HTML.Div, { Name = "First", LayoutOrder = 1, CSS = { Height = 20 } } :: HTML.DivProperties),
				Last = e(HTML.Div, { Name = "Last", LayoutOrder = 2, CSS = { Height = 20 } } :: HTML.DivProperties),
			}
		)
		near(child(container, "Last").AbsolutePosition.Y - container.AbsolutePosition.Y, 80, "Column justify-content")
		container = mount({ Display = "Flex", FlexDirection = "Column", Width = 200, Height = 100 }, {
			First = e(
				HTML.Div,
				{ Name = "First", LayoutOrder = 1, CSS = { Height = 80, FlexShrink = 0 } } :: HTML.DivProperties
			),
			Last = e(HTML.Div, { Name = "Last", LayoutOrder = 2, CSS = { Height = 80 } } :: HTML.DivProperties),
		})
		near(child(container, "Last").AbsoluteSize.Y, 20, "Column shrink respects zero factor")
		container = mount({ Display = "Flex", Width = 200, Height = 100, Padding = 10 }, {
			Item = e(HTML.Div, { Name = "Item", CSS = { Width = 40 } } :: HTML.DivProperties, {
				Fill = e(HTML.Div, { Name = "Fill", CSS = { Height = "100%" } } :: HTML.DivProperties),
			}),
		})
		near(child(container, "Item").AbsoluteSize.Y, 80, "Row stretch uses content height")
		near(child(child(container, "Item"), "Fill").AbsoluteSize.Y, 80, "Stretch relayouts percentage descendants")
		container = mount({ Display = "Flex", Width = 200, Height = 56, PaddingLeft = 16, PaddingRight = 16 }, {
			Indicator = e(
				HTML.Div,
				{
					Name = "Indicator",
					CSS = { Position = "Absolute", Left = 0, Bottom = 0, Width = "100%", Height = 2 } :: HTML.Style,
				} :: HTML.DivProperties
			),
		})
		near(child(container, "Indicator").AbsoluteSize.X, 200, "Absolute width includes padding")
		near(
			child(container, "Indicator").AbsolutePosition.X - container.AbsolutePosition.X,
			0,
			"Absolute left cancels native padding"
		)
		near(child(container, "Indicator").AbsolutePosition.Y - container.AbsolutePosition.Y, 54, "Absolute bottom")
		for _, overlay in { false, true, false } do
			container = mount({ Display = "InlineFlex", Height = 40, Gap = 8 }, {
				First = e(
					HTML.Div,
					{ Name = "First", LayoutOrder = 1, CSS = { Width = 20, Height = 20 } } :: HTML.DivProperties
				),
				Last = e(
					HTML.Div,
					{ Name = "Last", LayoutOrder = 2, CSS = { Width = 30, Height = 20 } } :: HTML.DivProperties
				),
				Overlay = if overlay
					then e(
						HTML.Div,
						{
							Name = "Overlay",
							CSS = { Position = "Absolute", Width = "100%", Height = "100%" } :: HTML.Style,
						} :: HTML.DivProperties
					)
					else nil,
			})
			near(container.AbsoluteSize.X, 58, "Absolute state layer never changes intrinsic gaps")
		end
	end)
	root:unmount()
	task.wait()
	screen:Destroy()
	assert(ok, problem)
	return "Flex: fixed/min-height alignment, margins, growth, shrink, percentage descendants, stretch, justification and absolute overlays passed."
end
