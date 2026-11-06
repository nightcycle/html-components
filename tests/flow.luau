--!strict
-- Packages
-- Modules
local load = require("./load")()
local Flow = load("src/Layout/Flow")
local CSS = load("src/CSS")
-- Types
type Item = {
	Display: string,
	Width: number,
	Height: number,
	Baseline: number,
	LineHeight: number,
	Margin: { Top: number, Right: number, Bottom: number, Left: number },
	Text: string?,
	Measure: ((string) -> number)?,
	WhiteSpace: string?,
	VerticalAlign: string?,
	Break: boolean?,
}
-- Constants
local ZERO = { Top = 0, Right = 0, Bottom = 0, Left = 0 }
-- References
-- Global Variables
local count = 0
-- Private Functions
local function check(condition: boolean, message: string)
	assert(condition, message)
	count += 1
end
local function text(value: string): Item
	return {
		Display = "Inline",
		Text = value,
		Width = 0,
		Height = 20,
		LineHeight = 24,
		Baseline = 15,
		Margin = ZERO,
		Measure = function(word: string): number
			return #word * 10
		end,
	}
end
local function options(width: number)
	return { Width = width, LineHeight = 24, Baseline = 17, XHeight = 10 }
end
-- Class
local result = Flow.layout({ text("one "), text("two three") }, options(80))
check(#result.Fragments == 3, "Styled runs wrap into three fragments")
check(result.Fragments[2].X == 40 and result.Fragments[2].Y == 2, "Adjacent styled runs share a line")
check(
	result.Fragments[3].X == 0 and result.Fragments[3].Y == 26 and result.Height == 48,
	"Word wrap with explicit line height"
)
result = Flow.layout({ text("   one \n"), text(" \t two ") }, options(100))
check(result.Height == 24 and result.Width == 70, "Whitespace collapses across elements; no leading/trailing spaces")
result = Flow.layout({ text("hello"), text("world") }, options(60))
check(result.Height == 24 and result.Width == 100, "A style boundary is not a line break opportunity")
local nowrap = text("one two three")
nowrap.WhiteSpace = "Nowrap"
check(Flow.layout({ nowrap }, options(60)).Height == 24, "Nowrap preserves one line")
local pre = text("a\n b")
pre.WhiteSpace = "PreWrap"
result = Flow.layout({ pre }, options(60))
check(result.Height == 48 and result.Fragments[2].Text == " b", "PreWrap retains spaces and hard breaks")
local atomic: Item = { Display = "InlineBlock", Width = 40, Height = 32, LineHeight = 32, Baseline = 32, Margin = ZERO }
result = Flow.layout({ text("one "), atomic, text(" two") }, options(80))
check(result.Fragments[2].X == 40 and result.Fragments[2].Y == 0, "InlineBlock is atomic and baseline aligned")
check(result.Height == 63, "Tall inline blocks expand the line box")
local middle = table.clone(atomic)
middle.Height, middle.VerticalAlign = 42, "Middle"
local bottom = table.clone(atomic)
bottom.Height, bottom.VerticalAlign = 56, "Bottom"
result = Flow.layout({ text("a"), middle, bottom }, options(100))
check(
	result.Height == 56 and result.Fragments[2].Y == 14 and result.Fragments[3].Y == 0,
	"A tall bottom-aligned box moves middle-aligned siblings with the shared baseline"
)
result = Flow.layout({ bottom, text("a") }, options(100))
check(result.Fragments[2].Y == 34, "Text moves with the baseline beside a bottom-aligned box")
result = Flow.layout({
	text("one"),
	{ Display = "Inline", Break = true, Width = 0, Height = 0, LineHeight = 0, Baseline = 0, Margin = ZERO },
	text("two"),
}, options(100))
check(result.Height == 48 and result.Fragments[2].Y == 26, "Br ends the current line")
local block = {
	Display = "Block",
	Width = 80,
	Height = 30,
	LineHeight = 30,
	Baseline = 30,
	Margin = { Top = 10, Right = 0, Bottom = 20, Left = 0 },
}
result = Flow.layout({ block, block }, options(100))
check(result.Fragments[2].Y == 60, "Adjacent block margins collapse")
local hidden = table.clone(atomic)
hidden.Display = "None"
check(Flow.layout({ hidden }, options(80)).Height == 0, "Display None contributes no line")
local sheet = CSS.parse(
	"span {display:inline; line-height:1.5; vertical-align:middle; margin:4px -2px; white-space:pre-wrap} div {display:inline-block}"
)
check(#sheet.Diagnostics == 0, "Browser CSS accepts new layout properties")
local style = sheet.Rules[1].Style
check(
	style.Display == "Inline" and style.LineHeight == 1.5 and style.VerticalAlign == "Middle",
	"CSS values normalize to PascalCase"
)
check(style.MarginRight == "-2px" and style.WhiteSpace == "PreWrap", "Margins and whitespace parse")
check(CSS.inherited(style).LineHeight == 1.5, "Line height inherits")
sheet = CSS.parse("div {margin:0 auto; margin-left:auto}")
check(
	#sheet.Diagnostics == 0 and sheet.Rules[1].Style.MarginLeft == "Auto",
	"Auto margins use PascalCase in compiled tables"
)
print(`{count} inline/block flow checks passed.`)
