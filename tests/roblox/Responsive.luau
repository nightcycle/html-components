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
local SHEET = HTML.CSS.parse([[
.Board {display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:12px; font-size:16px; line-height:1.5}
.Card {grid-column:span 2 / span 2}
.Row {display:flex; align-items:baseline; gap:8px}
.Large {font-size:32px; line-height:1}
.Small {font-size:16px; line-height:1.5}
.Copy {display:flex; gap:12px; align-items:center}
.Padded {display:inline; font-size:14px; line-height:20px; padding:10px 20px; background-color:purple; border-radius:8px}
@media(max-width:500px) {
 .Board {grid-template-columns:repeat(1,minmax(0,1fr))}
 .Card {grid-column:span 1 / span 1}
}
]])
-- References
-- Global Variables
-- Private Functions
local function view(viewport: number): React.ReactNode
	local large: HTML.SpanProperties = { Id = "Large", ClassName = "Large", Text = "$12", SourceOrder = 1 }
	local small: HTML.SpanProperties = { Id = "Small", ClassName = "Small", Text = "/month", SourceOrder = 2 }
	local label: HTML.SpanProperties = { Id = "Label", Text = "Detailed reports and dashboards", SourceOrder = 2 }
	local image: HTML.ImgProperties =
		{ Id = "Image", IntrinsicSize = Vector2.new(400, 300), SourceOrder = 2, CSS = { Width = "100%" } }
	local icon: HTML.ImgProperties = { Id = "Icon", IntrinsicSize = Vector2.new(20, 20), SourceOrder = 1 }
	local row: HTML.DivProperties = { Id = "Row", ClassName = "Row", SourceOrder = 1 }
	local copy: HTML.DivProperties = { Id = "Copy", ClassName = "Copy", SourceOrder = 2 }
	local card: HTML.DivProperties = { Id = "Card", ClassName = "Card", SourceOrder = 1 }
	local line: HTML.DivProperties = { Id = "InlineLine", SourceOrder = 3 }
	local padded: HTML.AProperties = { Id = "Padded", ClassName = "Padded", Text = "Continue" }
	local board: HTML.DivProperties = { Id = "Board", ClassName = "Board" }
	return e(HTML.StyleProvider, { StyleSheet = SHEET, ViewportWidth = viewport }, {
		Board = e(HTML.Div, board, {
			Card = e(HTML.Div, card, {
				Row = e(HTML.Div, row, { Large = e(HTML.Span, large), Small = e(HTML.Span, small) }),
				Copy = e(HTML.Div, copy, { Icon = e(HTML.Img, icon), Label = e(HTML.Span, label) }),
				Line = e(HTML.Div, line, { Link = e(HTML.A, padded) }),
			}),
			Image = e(HTML.Img, image),
		}),
	})
end
-- Class
return function(): string
	local screen = Instance.new("ScreenGui")
	screen.ScreenInsets = Enum.ScreenInsets.None
	screen.Parent = game:GetService("StarterGui")
	local holder = Instance.new("Frame")
	holder.Size = UDim2.fromOffset(600, 700)
	holder.Parent = screen
	local scale = Instance.new("UIScale")
	scale.Scale, scale.Parent = 0.75, holder
	local content = Instance.new("Frame")
	content.Size = UDim2.fromScale(1, 1)
	content.Parent = holder
	local root = ReactRoblox.createRoot(content)
	local function find(name: string): GuiObject
		local child = content:FindFirstChild(name, true)
		assert(child and child:IsA("GuiObject"), name)
		return child
	end
	local function close(actual: number, expected: number, message: string)
		assert(
			math.abs(actual / scale.Scale - expected) < 1,
			`{message}: got {actual / scale.Scale}, expected {expected}`
		)
	end
	local ok, problem = pcall(function()
		ReactRoblox.act(function()
			root:render(view(600))
		end)
		task.wait(0.8)
		close(find("Board").AbsoluteSize.X, 600, "UIScale must not shrink logical available width twice")
		close(find("Card").AbsoluteSize.X, 396, "Grid span includes the internal gap")
		close(find("Image").AbsoluteSize.X, 192, "Remaining grid track")
		close(find("Image").AbsoluteSize.Y, 144, "Image keeps natural aspect ratio")
		close(find("Label").AbsoluteSize.Y, 24, "Max-content flex text stays on one line")
		close(find("InlineLine").AbsoluteSize.Y, 24, "Inline padding does not increase the line box")
		close(find("Padded").AbsoluteSize.Y, 38, "Single-line inline padding expands the painted box")
		assert(find("Padded").BackgroundTransparency == 0, "Padded inline background remains visible behind its text")
		assert(
			find("Small").AbsolutePosition.Y > find("Large").AbsolutePosition.Y,
			"Baseline alignment lowers smaller text"
		)
		holder.Size = UDim2.fromOffset(360, 700)
		scale.Scale = 0.92552477
		ReactRoblox.act(function()
			root:render(view(360))
		end)
		task.wait(0.8)
		close(find("Card").AbsoluteSize.X, 360, "Media query removes the desktop span")
		close(find("Image").AbsoluteSize.X, 360, "Single responsive track")
		close(find("Image").AbsoluteSize.Y, 270, "Responsive image aspect ratio")
		close(
			find("Image").AbsolutePosition.Y - find("Card").AbsolutePosition.Y - find("Card").AbsoluteSize.Y,
			12,
			"Grid row gap"
		)
	end)
	ReactRoblox.act(function()
		root:unmount()
	end)
	screen:Destroy()
	assert(ok, problem)
	return "Native grid spans, responsive media, UIScale, flex intrinsic text, baselines and image aspect ratios passed."
end
