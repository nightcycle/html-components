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
	"p { position:fixed; width:12em; color:nope; border-width:-2px } @media (x) { p { color:red } } p + span {color:red}"
)
check(
	#invalid.Diagnostics == 6 and #invalid.Rules == 1,
	"Unsupported declarations and selectors diagnose without leaking nested rules"
)
check(#CSS.parse("p { color:red").Diagnostics == 1, "Unclosed rule")
check(CSS.parseSelector("p >") == nil and CSS.parseSelector("[href]") == nil, "Invalid selectors")
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
check(Values.length("50%") == roblox.UDim.new(0.5, 0) and Values.length("2em") == nil, "Length conversion")
check(Values.shadow("0px 2px -1px black") == nil, "Negative blur rejected")
check(Values.shadow("inset 0px 2px 4px 1px #0008").Inset == true, "Inset shadow")
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
for _, spec in require("../scripts/tags") do
	check(
		fs.isFile(`src/React/Component/{spec.Name}/init.luau`)
			and fs.isFile(`src/React/Component/{spec.Name}/{spec.Name}.story.luau`),
		`Component/story pair: {spec.Tag}`
	)
end
print(`{count} CSS and component coverage checks passed.`)
