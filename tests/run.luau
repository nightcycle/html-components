--!strict
local fs = require("@lune/fs")
local load = require("./load")()
local roblox = require("./Datatypes")
local CSS, Values = load("src/CSS"), load("src/CSS/Values")
local count = 0
local function check(condition: boolean, message: string)
	assert(condition, message)
	count += 1
end
local node = { Tag = "P", Id = "title", Classes = { "copy", "featured" } }
local ancestors = { { Tag = "Main", Classes = { "app" } }, { Tag = "Section", Classes = { "card" } } }
local function resolve(source: string, inline: unknown?)
	local sheet = CSS.parse(source)
	check(#sheet.Diagnostics == 0, `Unexpected diagnostic: {source}`)
	return CSS.resolve({ sheet }, node, ancestors, { Color = "black", FontSize = 16 }, {}, inline)
end
check(resolve("p {color: red} .copy {color: blue} #title {color: green}").Color == "green", "Specificity")
check(resolve(".copy {color:red} .copy {color:blue}").Color == "blue", "Source order")
check(
	resolve("#title {color:green} " .. string.rep(".copy", 1001) .. " {color:red}").Color == "green",
	"ID specificity cannot be outweighed by class count"
)
check(resolve("#title {color:red}", { Color = "blue" }).Color == "blue", "Inline priority")
check(resolve("p {color:red !important} #title {color:blue}", { Color = "green" }).Color == "red", "Important priority")
check(resolve("main > p {color:red} main p {color:blue}").Color == "blue", "Child vs descendant")
check(resolve(".app > .card > p.copy.featured {color:purple}").Color == "purple", "Compound selectors")
check(resolve("h1, p {font-size:24px}").FontSize == 24, "Selector lists")
check(resolve("p {padding:1px 2px 3px 4px; padding-left:9px}").PaddingLeft == "9px", "Shorthand declaration order")
check(resolve("p {padding-left:9px; padding:1px 2px}").PaddingLeft == "2px", "Later shorthand resets longhand")
check(
	resolve("p {border-top-right-radius:20px}", { BorderRadius = 2 }).BorderTopRightRadius == 2,
	"Inline shorthand resets sheet corners"
)
check(
	resolve("p { color:rgba(10,20,30,0.5); box-shadow:0px 4px 8px rgba(0,0,0,0.2) }").BoxShadow ~= nil,
	"Functional colors"
)
check(resolve("/* comment */ p { width:50%; height:auto }").Width == "50%", "Comments and lengths")
local state = CSS.parse("p:hover:focus {color:red} p:disabled {color:gray}")
check(CSS.resolve({ state }, node, {}, {}, {}, nil).Color == nil, "Inactive pseudo classes")
node.Hover, node.Focus = true, true
check(CSS.resolve({ state }, node, {}, {}, {}, nil).Color == "red", "Active pseudo classes")
local nested = { CSS.parse("p {color:red}"), CSS.parse("p {color:blue}") }
check(CSS.resolve(nested, node, {}, {}, {}, nil).Color == "blue", "Nested provider order")
local inherit = CSS.inherited({ Color = "red", Padding = 10, BackgroundColor = "blue", TextDecoration = "Underline" })
check(inherit.Color == "red" and inherit.Padding == nil and inherit.BackgroundColor == nil, "Only typography inherits")
local invalid = CSS.parse(
	"p { position:sticky; width:12vh; color:nope; border-width:-2px } @media (x) { p { color:red } } p:has(span) {color:red}"
)
check(
	#invalid.Diagnostics == 6 and #invalid.Rules == 1,
	"Unsupported declarations and selectors diagnose without leaking nested rules"
)
check(#CSS.parse("p { color:red").Diagnostics == 1, "Unclosed rule")
check(CSS.parseSelector("p >") == nil and CSS.parseSelector("[href]") == nil, "Invalid selectors")
for _, case in
	{
		{ [[.hover\:text-red:hover]], "hover:text-red" },
		{ [[.w-1\/2]], "w-1/2" },
		{ [[.p-2\.5]], "p-2.5" },
		{ [[.\32 xl\:wide]], "2xl:wide" },
		{ [[.\000032xl\:wide]], "2xl:wide" },
		{ [[.a\,b]], "a,b" },
		{ [[.a\>b]], "a>b" },
		{ [[.a\ b]], "a b" },
		{ [[.a\ ]], "a " },
		{ [[.a\\b]], [[a\b]] },
		{ [[.caf\e9 ]], "café" },
	}
do
	local escaped = CSS.parse(case[1] .. " { color:red }")
	check(#escaped.Diagnostics == 0 and #escaped.Rules == 1, `Escaped selector compiles: {case[1]}`)
	local target = { Tag = "Div", Classes = { case[2] }, Hover = true }
	check(CSS.resolve({ escaped }, target, {}, {}, {}).Color == "red", `Decoded class matches: {case[2]}`)
end
check(CSS.parseSelector([[.\0]]).Parts[1].Classes[1] == utf8.char(0xFFFD), "Invalid codepoint replaced")
check(CSS.parseSelector(".bad\\") == nil and CSS.parseSelector(".bad\\\nname") == nil, "Invalid escapes rejected")
local escapedMap = CSS.fromMap({ ["Button.hover\\:red:Hover"] = { Color = "red" } })
check(
	#escapedMap.Diagnostics == 0
		and CSS.resolve({ escapedMap }, { Tag = "Button", Classes = { "hover:red" }, Hover = true }, {}, {}, {}).Color
			== "red",
	"Escapes preserve PascalCase table selector contract"
)
check(#CSS.parse([[.a\,b, .other { color:red }]]).Rules == 2, "Escaped comma does not split a selector group")
local escapedChild = CSS.parseSelector([[.a\>b > .w-1\/2]])
check(
	CSS.matches(escapedChild, { Tag = "Div", Classes = { "w-1/2" } }, { { Tag = "Div", Classes = { "a>b" } } }),
	"Escaped combinator does not alter child matching"
)
local selector = CSS.parseSelector("main > section p")
check(
	CSS.matches(
		selector,
		node,
		{ { Tag = "Main", Classes = {} }, { Tag = "Section", Classes = {} }, { Tag = "Section", Classes = {} } }
	),
	"Descendant matching backtracks"
)
local color, transparency = Values.color("#abcd")
check(color == roblox.Color3.fromRGB(170, 187, 204) and math.abs(transparency - (1 - 221 / 255)) < 0.001, "Hex alpha")
for _, input in
	{ "rgb(255 0 0 / 50%)", "rgba(100% 0% 0% / .5)", "rgb(255,0,0,50%)", "rgb(100%,0%,0%,.5)", "rgb(2.55e2 0 0/.5)" }
do
	local rgb, alpha = Values.color(input)
	check(rgb == roblox.Color3.fromRGB(255, 0, 0) and alpha == 0.5, `RGB syntax: {input}`)
end
check(Values.color("rgb(100% 0 0)") == roblox.Color3.fromRGB(255, 0, 0), "Modern RGB allows mixed channels")
check(Values.color("rgb(300 -10 0)") == roblox.Color3.fromRGB(255, 0, 0), "RGB channels clamp")
for _, input in
	{
		"rgb(255, 0 0)",
		"rgb(255,0,0 / .5)",
		"rgb(255 0 0 /)",
		"rgb(255 0 0 / .5 / .5)",
		"rgb(100%,0,0)",
		"rgb(0xFF 0 0)",
		"rgb(1e999 0 0)",
		"rgb(255 0)",
		"rgb(1. 0 0)",
		"rgb(255 0 0 / var(--alpha))",
	}
do
	check(Values.color(input) == nil, `Invalid or unsupported RGB rejected: {input}`)
end
check(
	resolve([[p { font-family: "Unavailable Font", Arial, sans-serif; color:rgb(255 0 0 / .5) }]]).FontFamily
		== "SansSerif",
	"Supported generic font fallback and modern color compile"
)
check(resolve([[p { font-family: Georgia, SERIF }]]).FontFamily == "Serif", "Generic family is case insensitive")
check(resolve([[p { font-family: "serif", monospace }]]).FontFamily == "Monospace", "Quoted family is a name")
check(
	#CSS.parse([[p { font-family:"serif" } p { font-family:Arial } p { font-family:Arial,,serif }]]).Diagnostics == 3,
	"Missing fallback and empty family diagnose"
)
check(Values.length("50%") == roblox.UDim.new(0.5, 0) and Values.length("2em") == nil, "Length conversion")
check(Values.shadow("0px 2px -1px black") == nil, "Negative blur rejected")
check(Values.shadow("inset 0px 2px 4px 1px #0008").Inset == true, "Inset shadow")
check(
	#Values.shadows("0 0 #0000, 0 1px 3px rgb(0 0 0 / .1), 0 1px 2px rgb(0 0 0 / .06)") == 3,
	"Layered shadows retain zero-blur placeholders and functional colors"
)
check(Values.shadows("0 1px 3px black, invalid") == nil, "A malformed shadow layer rejects the list")
local options = resolve(
	"p { display:flex; flex-direction:row; justify-content:space-between; font-family:sans-serif; text-decoration:line-through }"
)
check(options.Display == "Flex" and options.FlexDirection == "Row", "PascalCase layout options")
check(
	options.JustifyContent == "SpaceBetween"
		and options.FontFamily == "SansSerif"
		and options.TextDecoration == "LineThrough",
	"Hyphenated CSS options normalize to public types"
)
check(CSS.parseSelector("article:hover > p").Parts[1].Tag == "Article", "HTML tag selectors normalize to PascalCase")
check(CSS.parseSelector("article:hover > p").Parts[1].States[1] == "Hover", "Selector states normalize to PascalCase")
check(CSS.parseSelector("article:hover > p").Parts[2].Relation == "Child", "Selector relations normalize to PascalCase")
local mapped = CSS.fromMap({
	Button = { FontWeight = "Bold", Padding = 8, BorderRadius = 12 },
	[".Primary"] = { FontSize = 18 },
	[".Card > Button.Primary:Hover"] = { BackgroundColor = "blue" },
})
local mapNode = { Tag = "Button", Classes = { "Primary" }, Hover = true }
local mapAncestors = { { Tag = "Div", Classes = { "Card" } } }
local function mapResolve(sheet: unknown)
	return CSS.resolve({ sheet }, mapNode, mapAncestors, {}, {}, nil)
end
local mapStyle = mapResolve(mapped)
check(#mapped.Diagnostics == 0 and #mapped.Rules == 3, "Typed selector map compiles without diagnostics")
check(mapStyle.FontWeight == "Bold" and mapStyle.FontSize == 18, "PascalCase table values")
check(mapStyle.BackgroundColor == "blue", "PascalCase tags, child relations, compound classes and hover")
check(mapStyle.PaddingLeft == 8 and mapStyle.BorderTopRightRadius == 12, "Map shorthand normalization")
check(mapResolve(CSS.fromMap({ ["Input, Button"] = { Height = 44 } })).Height == 44, "Map selector groups")
check(
	#CSS.fromMap({ button = { Color = "red" }, ["Button:hover"] = { Color = "blue" } }).Diagnostics == 2,
	"Map tags and states must use PascalCase"
)
check(
	#CSS.fromMap({ [".Primary"] = { fontSize = 18 } }).Diagnostics == 1,
	"Misspelled map fields diagnose instead of silently disappearing"
)
check(
	mapResolve(CSS.fromMap({ [".primary"] = { Color = "red" } })).Color == nil,
	"Class identifiers remain case-sensitive"
)
local first = CSS.fromMap({ [".Primary"] = { Color = "red" }, [".Other"] = { Color = "blue" } })
local second = CSS.fromMap({ [".Other"] = { Color = "blue" }, [".Primary"] = { Color = "red" } })
mapNode.Classes = { "Primary", "Other" }
check(
	mapResolve(first).Color == "red" and mapResolve(second).Color == "red",
	"Equal-specificity map ties use alphabetical selector order"
)
check(
	mapResolve(CSS.fromMap({ [".Other.Primary"] = { Color = "blue" }, [".Primary"] = { Color = "red" } })).Color
		== "blue",
	"Specificity still takes priority over alphabetical order"
)
local original: { [string]: { [string]: number } } = { Button = { Padding = 8 } }
CSS.fromMap(original)
check(original.Button.PaddingLeft == nil, "Compiling a map never mutates the caller's style tables")
check(
	CSS.resolve(
		{ mapped, CSS.parse("button { color: red !important; }") },
		mapNode,
		mapAncestors,
		{},
		{ Color = "blue" }
	).Color == "red",
	"Imported important rules still compose with table styles"
)
for _, spec in require("../scripts/tags") do
	check(
		fs.isFile(`src/React/Component/{spec.Name}/init.luau`)
			and fs.isFile(`src/React/Component/{spec.Name}/{spec.Name}.story.luau`),
		`Component/story pair: {spec.Tag}`
	)
end
local imported = CSS.parse([[.Theme { --Accent: 12 34 56; --Alpha: .5; font-size:20px }
.Child { color:rgb(var(--Accent) / var(--Alpha)); width:2em; padding:1rem; font-weight:800 }
@media (min-width:1024px) { .Child { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:2rem } }
.Stack > :not([hidden]) ~ :not([hidden]) { margin-left:calc(2rem * calc(1 - var(--reverse, 0))) }
]])
check(#imported.Diagnostics == 0, "Imported variables, media, grid and sibling spacing compile")
local parentStyle, variables = CSS.resolve({ imported }, { Tag = "Div", Classes = { "Theme" } }, {}, {}, {})
local child = CSS.resolve(
	{ imported },
	{ Tag = "Div", Classes = { "Child" } },
	{},
	CSS.inherited(parentStyle),
	{},
	nil,
	{ ViewportWidth = 1440 },
	variables
)
check(
	child.Width == "40px" and child.PaddingLeft == "16px" and child.FontWeight == "ExtraBold",
	"Relative dimensions and numeric font weights"
)
local childColor, alpha = Values.color(child.Color)
check(
	childColor == roblox.Color3.fromRGB(12, 34, 56) and alpha == 0.5,
	"Inherited custom properties resolve inside RGB"
)
check(
	child.Display == "Grid" and child.GridTemplateColumns == 3 and child.Gap == "32px",
	"Responsive grid styles apply"
)
local mobile = CSS.resolve(
	{ imported },
	{ Tag = "Div", Classes = { "Child" } },
	{},
	{},
	{},
	nil,
	{ ViewportWidth = 390 },
	variables
)
check(mobile.Display == nil and mobile.GridTemplateColumns == nil, "Media rule does not leak below its breakpoint")
local sibling = { Tag = "Div", Classes = {} }
local last = { Tag = "Div", Classes = {}, PreviousSiblings = { sibling } }
local spaced = CSS.resolve({ imported }, last, { { Tag = "Div", Classes = { "Stack" } } }, {}, {})
check(spaced.MarginLeft == "32px", "Sibling selector and nested calc produce spacing")
check(
	CSS.resolve({ imported }, sibling, { { Tag = "Div", Classes = { "Stack" } } }, {}, {}).MarginLeft == nil,
	"First sibling is not spaced"
)
check(
	CSS.parseSelector("p +") == nil and CSS.parseSelector("p > ~ span") == nil,
	"Incomplete sibling combinators rejected"
)
local calculate = load("src/CSS/Calculation")
check(calculate("calc(10px + 2px * 3)") == "16px", "Calc operator precedence")
check(
	calculate("calc(1px / 0)") == nil and calculate("calc(1px + 2%)") == nil,
	"Invalid and incompatible dimensions rejected"
)
local expand = load("src/CSS/Variables")
check(
	(expand("var(--missing, var(--fallback, red))", {}) or ""):match("^%s*(.-)%s*$") == "red",
	"Nested variable fallback"
)
check(expand("var(--a)", { ["--a"] = "var(--b)", ["--b"] = "var(--a)" }) == nil, "Variable cycle terminates")
check(
	resolve("p { width:2em; font-size:24px; font-family:system-ui }").Width == "48px",
	"Em sizing uses final font size"
)
local inheritedLine = CSS.resolve(
	{ CSS.parse("p {line-height:inherit}") },
	node,
	{},
	{ LineHeight = 1.5 },
	{ LineHeight = "Normal" }
)
check(inheritedLine.LineHeight == 1.5, "Explicit line-height inheritance replaces defaults")
check(
	#CSS.validate({ GridTemplateColumns = 3, GridColumn = 2, FlexGrow = 1, FlexShrink = 0 }).Diagnostics == 0,
	"Grid and flex PascalCase fields validate"
)
check(
	#CSS.validate({ GridTemplateColumns = 0, GridColumn = 1.5, FlexGrow = -1 }).Diagnostics == 3,
	"Invalid grid and flex fields are rejected"
)
check(#CSS.declarations("width:var(--size)").Diagnostics == 1, "Context-dependent inline CSS cannot disappear silently")
for raw, canonical in
	{ blockquote = "BlockQuote", textarea = "TextArea", figcaption = "FigCaption", fieldset = "FieldSet" }
do
	local current = { Tag = canonical, Classes = {} }
	check(CSS.matches(assert(CSS.parseSelector(raw)), current, {}), `Raw HTML selector matches {canonical}`)
	local sheet = CSS.fromMap({ [canonical] = { Color = "purple" } })
	check(CSS.resolve({ sheet }, current, {}, {}, {}).Color == "purple", `PascalCase selector map matches {canonical}`)
end
print(`{count} CSS and component coverage checks passed.`)
