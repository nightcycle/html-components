--!strict
-- Packages
local storage = script.Parent.Parent
local HTML = require(storage.Packages.HTMLComponents)
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
local Roblox = require(storage.Packages.RobloxComponents)
-- Modules
local Fixtures = require(storage.MarkupFixtures)
-- Components
-- Contexts
-- Hooks
-- Types
type Properties = { BadgeRef: React.Ref<GuiObject>? }
-- Constants
local e = React.createElement
local BADGE_STYLE: HTML.Style = { Width = 88 }
-- References
-- Global Variables
-- Private Functions
local function node(
	tag: HTML.ContentTag,
	id: string,
	children: { HTML.ContentNode }?,
	text: string?
): HTML.ContentElement
	return { Tag = tag, Id = id, Text = text, Children = children }
end
local function tableContent(ref: React.Ref<GuiObject>?): { HTML.ContentNode }
	local strongChildren: { HTML.ContentNode } = { "bold ", node("Em", "Em", nil, "nested italic") }
	local strong = node("Strong", "Strong", strongChildren)
	strong.ClassName = "Accent"
	local badge = node("Strong", "Badge", nil, "BADGE")
	badge.ClassName, badge.CSS, badge.Ref = "Badge", BADGE_STYLE, ref
	local sized = node("Em", "Sized", nil, "sized text")
	sized.ClassName = "Sized"
	local underlineChildren: { HTML.ContentNode } = { "underlined ", node("S", "Both", nil, "and struck") }
	local copyChildren: { HTML.ContentNode } = {
		"Read ",
		strong,
		" & ",
		node("U", "Underline", underlineChildren),
		" text.",
		node("Br", "Break"),
		node("Span", "Literal", nil, "<strong>literal</strong>"),
		" ",
		node("Mark", "Mark", nil, "highlighted words"),
	}
	local boxesChildren: { HTML.ContentNode } = { "A ", badge, " next to ", sized, " stays independent." }
	return {
		node("P", "Copy", copyChildren),
		node("P", "Boxes", boxesChildren),
	}
end
local function text(
	component: (HTML.TextProperties) -> React.ReactNode,
	id: string,
	value: string,
	order: number,
	children: React.ReactNode?
): React.ReactNode
	local props: HTML.TextProperties = { Id = id, Text = value, LayoutOrder = order }
	return e(component, props, children)
end
local function manualContent(): React.ReactNode
	local strong: HTML.StrongProperties = { Id = "Strong", ClassName = "Accent", Text = "bold ", LayoutOrder = 1 }
	local badge: HTML.StrongProperties =
		{ Id = "Badge", ClassName = "Badge", Text = "BADGE", LayoutOrder = 1, CSS = BADGE_STYLE }
	local sized: HTML.EmProperties = { Id = "Sized", ClassName = "Sized", Text = "sized text", LayoutOrder = 3 }
	return {
		Copy = text(HTML.P, "Copy", "Read ", 1, {
			Strong = e(HTML.Strong, strong, { Em = text(HTML.Em, "Em", "nested italic", 1) }),
			Join = text(HTML.Span, "Join", " & ", 2),
			Underline = text(HTML.U, "Underline", "underlined ", 3, { Both = text(HTML.S, "Both", "and struck", 1) }),
			Tail = text(HTML.Span, "Tail", " text.", 4),
			Break = e(HTML.Br, { LayoutOrder = 5 }),
			Literal = text(HTML.Span, "Literal", "<strong>literal</strong>", 6),
			Space = text(HTML.Span, "Space", " ", 7),
			Mark = text(HTML.Mark, "Mark", "highlighted words", 8),
		}),
		Boxes = text(HTML.P, "Boxes", "A ", 2, {
			Badge = e(HTML.Strong, badge),
			Join = text(HTML.Span, "Next", " next to ", 2),
			Sized = e(HTML.Em, sized),
			Tail = text(HTML.Span, "End", " stays independent.", 4),
		}),
	}
end
local function view(props: Properties): React.ReactNode
	local panes: { [string]: React.ReactNode } = {}
	for row, width in Fixtures.Widths do
		for column, mode in Fixtures.Modes do
			local content: React.ReactNode
			if mode == "React" then
				content = manualContent()
			else
				local input: HTML.ContentProperties =
					{ Source = if mode == "Markup" then Fixtures.Markup else tableContent(props.BadgeRef) }
				content = { Content = e(HTML.Content, input) }
			end
			local title: HTML.PProperties = { Text = `{mode} / {width}px`, Position = UDim2.fromOffset(0, -30) }
			local card: HTML.DivProperties = { Name = "Card", ClassName = "Card" }
			panes[`Pane{row}{column}`] = e(Roblox.Frame({
				Name = `Pane{row}{column}`,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(20 + (column - 1) * 328, 56 + (row - 1) * 344),
				Size = UDim2.fromOffset(width, 300),
			}, {}, { Title = e(HTML.P, title), Card = e(HTML.Div, card, content) }))
		end
	end
	return e(HTML.StyleProvider, { StyleSheet = HTML.CSS.parse(Fixtures.CSS) }, {
		Board = e(Roblox.Frame({
			Name = "MarkupComparison",
			Size = UDim2.fromOffset(1008, 744),
			BackgroundColor3 = Color3.fromRGB(226, 233, 244),
			BorderSizePixel = 0,
		}, {}, panes)),
	})
end
local function verify(): string
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ScreenInsets, gui.Parent = "HTMLMarkupTest", Enum.ScreenInsets.None, game:GetService("StarterGui")
	local root = ReactRoblox.createRoot(gui)
	local ref = React.createRef()
	local ok, problem = pcall(function()
		ReactRoblox.act(function()
			root:render(e(view, { BadgeRef = ref }))
		end)
		task.wait(1)
		local board = gui:FindFirstChild("MarkupComparison") :: Frame
		for row = 1, 2 do
			local reference = board:FindFirstChild(`Pane{row}3`) :: Frame
			for column = 1, 2 do
				local pane = board:FindFirstChild(`Pane{row}{column}`) :: Frame
				for _, name in
					{
						"Card",
						"Copy",
						"Strong",
						"Em",
						"Underline",
						"Both",
						"Literal",
						"Mark",
						"Boxes",
						"Badge",
						"Sized",
					}
				do
					local actual = assert(pane:FindFirstChild(name, true), name) :: GuiObject
					local expected = assert(reference:FindFirstChild(name, true), name) :: GuiObject
					assert(
						(actual.AbsoluteSize - expected.AbsoluteSize).Magnitude < 1,
						`Size differs: {row}/{column}/{name}`
					)
					assert(
						(
							(actual.AbsolutePosition - pane.AbsolutePosition)
							- (expected.AbsolutePosition - reference.AbsolutePosition)
						).Magnitude < 1,
						`Position differs: {row}/{column}/{name}`
					)
				end
			end
		end
		local badge = ref.current :: GuiObject
		assert(
			badge and badge.Name == "Badge" and badge.AbsoluteSize == Vector2.new(88, 42),
			"Table nodes retain native refs and independent dimensions"
		)
		local both = assert(board:FindFirstChild("Pane11")):FindFirstChild("Both", true) :: TextLabel
		local decorated = false
		for _, child in both:GetDescendants() do
			if child:IsA("TextLabel") and child.RichText and child.Text:find("<s><u>", 1, true) then
				decorated = true
			end
		end
		assert(decorated, "Nested underline and strike use native RichText fragments")
		local reported: { HTML.MarkupDiagnostic } = {}
		local invalid: HTML.ContentProperties = {
			Source = "<strong>unclosed",
			OnDiagnostics = function(errors)
				reported = errors
			end,
		}
		ReactRoblox.act(function()
			root:render(e(HTML.Content, invalid))
		end)
		assert(
			#reported == 1 and #gui:GetChildren() == 0 and ref.current == nil,
			"Invalid source is reported and previous content/ref is removed"
		)
		local hostStyle: HTML.Style = { Width = 200, Color = "blue" }
		local host: HTML.PProperties = { Name = "Host", CSS = hostStyle }
		local content: HTML.ContentProperties = { Source = "plain <strong id='Live'>bold</strong>" }
		local map: HTML.StyleMap = { Span = { Color = "red" }, ["P > Strong"] = { Color = "green" } }
		local body = { Host = e(HTML.P, host, { Content = e(HTML.Content, content) }) }
		ReactRoblox.act(function()
			root:render(e(HTML.StyleProvider, { CSS = map }, body))
		end)
		task.wait(0.3)
		local container = gui:FindFirstChild("Host") :: TextLabel
		local anonymous = container:FindFirstChild("#text") :: TextLabel
		assert(anonymous.TextColor3 == Color3.fromRGB(0, 0, 255), "Anonymous text does not match Span")
		local live = container:FindFirstChild("Live") :: TextLabel
		assert(live.TextColor3 == Color3.fromRGB(0, 128, 0), "Content preserves direct-child selector ancestry")
		local updated: HTML.StyleMap = { Span = { Color = "red" }, ["P > Strong"] = { Color = "purple" } }
		ReactRoblox.act(function()
			root:render(e(HTML.StyleProvider, { CSS = updated }, body))
		end)
		assert(
			live.TextColor3 == Color3.fromRGB(128, 0, 128) and anonymous.TextColor3 == Color3.fromRGB(0, 0, 255),
			"Stable parsed content responds to selective stylesheet updates"
		)
	end)
	ReactRoblox.act(function()
		root:unmount()
	end)
	gui:Destroy()
	assert(ok, tostring(problem))
	return "Markup/table/React equivalence, nested RichText, anonymous selectors, refs and malformed-source cleanup passed."
end
-- Class
return { View = view, Verify = verify }
