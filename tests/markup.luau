--!strict
-- Packages
-- Modules
local load = require("./load")()
local Markup = load("src/Markup")
local Store = load("src/React/Context/StyleStore")
local CSS = load("src/CSS")
-- Types
-- Constants
-- References
-- Global Variables
local checks = 0
-- Private Functions
local function check(condition: boolean, message: string)
	assert(condition, message)
	checks += 1
end
local function valid(source: string)
	local result = Markup.parse(source)
	check(result.Success and #result.Diagnostics == 0, `Expected valid markup: {source}`)
	return result.Nodes
end
local function invalid(source: string)
	local result = Markup.parse(source)
	check(not result.Success and #result.Nodes == 0 and #result.Diagnostics > 0, `Expected diagnostic: {source}`)
	return result.Diagnostics[1]
end
-- Class
local nodes = valid('Hello <strong id="Title" class="Accent">bold <em>and italic</em></strong> tail')
check(#nodes == 3 and nodes[1] == "Hello " and nodes[3] == " tail", "Mixed text order is preserved")
check(nodes[2].Tag == "Strong" and nodes[2].Children[2].Tag == "Em", "Tag normalization and nesting")
check(nodes[2].Id == "Title" and nodes[2].ClassName == "Accent", "Identifiers retain case")
nodes = valid(
	'<span id="a&gt;b" style="color:#315fe8; font-size:22px; display:inline-block; width:92px">&lt;b&gt; &amp; &#65; &#x1F642; &nbsp;</span>'
)
check(
	nodes[1].Id == "a>b" and nodes[1].CSS.FontSize == 22 and nodes[1].CSS.Display == "InlineBlock",
	"Quoted >, inline CSS and entities"
)
check(
	nodes[1].Children[1] == "<b> & A " .. utf8.char(0x1F642) .. " " .. utf8.char(160),
	"Numeric and named entities decode once"
)
check(valid("&amp;lt;")[1] == "&lt;", "Decoded entities are not reparsed")
check(valid("a<!--comment--><![CDATA[<b>raw</b>]]>z")[1] == "a<b>raw</b>z", "CDATA and adjacent text coalesce")
check(#valid("<br/><span/><br></br>") == 3, "Self-closing tags and empty paired tags")
for _, source in
	{
		"<strong>",
		"<strong><em>x</strong></em>",
		"</span>",
		"<span id=x/>",
		'<span id="x" id="y"/>',
		'<span id="<"/>',
		"<unknown/>",
		'<span onclick="run()"/>',
		"&unknown;",
		"&",
		"&#0;",
		"&#xD800;",
		"&#1114112;",
		"<!DOCTYPE x>",
		"<?xml version='1.0'?>",
		"<!--x",
		"<!--a--b-->",
		"<!--a--->",
		"<![CDATA[x",
		"]]>x",
		"<br>x</br>",
		'<span style="position:absolute"/>',
		'<span style="color:red !important"/>',
		"<Span></span>",
		"\0",
		string.char(255),
	}
do
	invalid(source)
end
local problem = invalid("hello\n<strong>bad</em>")
check(
	problem.Location.Line == 2 and problem.Location.Column == 12 and problem.Location.Offset == 18,
	"Diagnostics identify original byte positions"
)
invalid(string.rep("<span>", 65) .. string.rep("</span>", 65))
invalid(string.rep("<span>", 64) .. "<br/>" .. string.rep("</span>", 64))
invalid(string.rep("x", 1024 * 1024 + 1))
local nested: { unknown } = { "bold", { Tag = "Em", Text = " italic" } }
local original = { Tag = "Strong", ClassName = "Accent", Children = nested }
local tableSource: { unknown } = { "Hello ", original }
local result = Markup.validate(tableSource)
check(result.Success and result.Nodes[2].Children[2].Text == " italic", "Table form accepts ordered mixed content")
result.Nodes[2].ClassName = "Changed"
check(original.ClassName == "Accent", "Validation copies element records")
local malformed: { unknown } = {
	{ { Tag = "strong" } },
	{ { Tag = "Span", Text = 3 } },
	{ { Tag = "Span", Text = string.char(255) } },
	{ { Tag = "Span", Id = "\0" } },
	{ { Tag = "Span", Text = string.rep("x", 1024 * 1024 + 1) } },
	{ { Tag = "Span", CSS = { FontSize = "large" } } },
	{ { Tag = "Span", CSS = { FontWeight = "bold" } } },
	{ { Tag = "Span", CSS = { Width = false } } },
	{ { Tag = "Span", CSS = { Color = "not-a-color" } } },
	{ { Tag = "Br", Text = "bad" } },
	{ { Tag = "Span", css = {} } },
	{ [1] = "a", [3] = "b" },
	{ Child = "a" },
}
for _, source in malformed do
	result = Markup.validate(source)
	check(
		not result.Success and #result.Nodes == 0 and result.Diagnostics[1].Path ~= nil,
		"Table validation has a failing field path"
	)
end
local cycle: { [string]: unknown } = { Tag = "Span" }
cycle.Children = { cycle }
check(not Markup.validate({ cycle }).Success, "Cyclic tables are diagnosed")
local auto = Markup.parse('<span style="width:auto;height:auto"/>')
check(
	auto.Success and auto.Nodes[1].CSS.Width == "Auto" and auto.Nodes[1].CSS.Height == "Auto",
	"Auto dimensions normalize to PascalCase"
)
local provider =
	Store.create(nil, { Sheets = { CSS.fromMap({ Span = { Color = "red" }, ["P > Strong"] = { FontSize = 24 } }) } })
local parent = Store.create(
	provider,
	{ Node = { Tag = "P", Classes = {} }, Inline = { Color = "blue", TextDecoration = "Underline" } }
)
local raw = Store.create(parent, { Text = true })
check(
	raw.GetSnapshot().Style.Color == "blue" and #raw.GetSnapshot().Context.Ancestors == 1,
	"Anonymous text does not match Span or add selector ancestry"
)
local strong =
	Store.create(parent, { Node = { Tag = "Strong", Classes = {} }, Inline = { TextDecoration = "LineThrough" } })
check(
	strong.GetSnapshot().Style.FontSize == 24 and strong.GetSnapshot().Style.TextDecoration == "UnderlineLineThrough",
	"Direct-child selectors and nested decorations"
)
local atomic = Store.create(parent, { Node = { Tag = "Strong", Classes = {} }, Inline = { Display = "InlineBlock" } })
check(
	atomic.GetSnapshot().Style.TextDecoration == nil,
	"Parent decoration does not cross an inline-block formatting boundary"
)
print(`{checks} markup, table and text-context checks passed.`)
