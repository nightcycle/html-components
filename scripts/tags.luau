--!strict
export type Spec = { Tag: string, Name: string, Kind: string, Defaults: string? }
local specs: { Spec } = {}
local INLINE = {
	span = true,
	label = true,
	abbr = true,
	time = true,
	output = true,
	b = true,
	strong = true,
	i = true,
	em = true,
	cite = true,
	var = true,
	s = true,
	del = true,
	u = true,
	ins = true,
	code = true,
	kbd = true,
	samp = true,
	small = true,
	mark = true,
	q = true,
	br = true,
}
local function add(tag: string, name: string, kind: string, defaults: string?)
	assert(string.lower(name) == tag, "Component name must match its HTML tag")
	if INLINE[tag] then
		defaults = (defaults or "{}"):gsub("^{", '{ Display = "Inline",', 1)
	end
	table.insert(specs, { Tag = name, Name = name, Kind = kind:sub(1, 1):upper() .. kind:sub(2), Defaults = defaults })
end
for _, tag in
	{
		"html",
		"body",
		"div",
		"main",
		"section",
		"article",
		"aside",
		"header",
		"footer",
		"nav",
		"form",
		"figure",
		"ul",
		"ol",
		"li",
		"dl",
		"dt",
		"dd",
	}
do
	add(tag, tag:sub(1, 1):upper() .. tag:sub(2), "container", "{}")
end
add("fieldset", "FieldSet", "container", '{ BorderWidth = 1, BorderColor = "#b4bed1", Padding = 12 }')
for _, tag in { "p", "span", "label", "legend", "figcaption", "abbr", "time", "output" } do
	add(tag, if tag == "figcaption" then "FigCaption" else tag:sub(1, 1):upper() .. tag:sub(2), "text", "{}")
end
for index, size in { 32, 28, 24, 20, 18, 16 } do
	add(`h{index}`, `H{index}`, "text", `\{ FontSize = {size}, FontWeight = "Bold" \}`)
end
for _, tag in { "b", "strong" } do
	add(tag, tag:sub(1, 1):upper() .. tag:sub(2), "text", '{ FontWeight = "Bold" }')
end
for _, tag in { "i", "em", "cite", "var", "address" } do
	add(tag, tag:sub(1, 1):upper() .. tag:sub(2), "text", '{ FontStyle = "Italic" }')
end
for _, tag in { "s", "del" } do
	add(tag, tag:sub(1, 1):upper() .. tag:sub(2), "text", '{ TextDecoration = "LineThrough" }')
end
for _, tag in { "u", "ins" } do
	add(tag, tag:sub(1, 1):upper() .. tag:sub(2), "text", '{ TextDecoration = "Underline" }')
end
for _, tag in { "code", "kbd", "samp" } do
	add(tag, tag:sub(1, 1):upper() .. tag:sub(2), "text", '{ FontFamily = "Monospace" }')
end
add("pre", "Pre", "text", '{ FontFamily = "Monospace", WhiteSpace = "Pre" }')
add("small", "Small", "text", "{ FontSize = 12 }")
add("mark", "Mark", "text", '{ BackgroundColor = "#fff1a6" }')
add("blockquote", "BlockQuote", "text", '{ FontStyle = "Italic", Padding = 12, BackgroundColor = "#eef1f8" }')
add("q", "Q", "text", '{ FontStyle = "Italic" }')
add("a", "A", "button", '{ Color = "#285cdd", TextDecoration = "Underline", Height = 28 }')
add(
	"button",
	"Button",
	"button",
	'{ Height = 38, BackgroundColor = "#315fe8", Color = "white", Padding = 8, BorderRadius = 6, TextAlign = "Center" }'
)
add("input", "Input", "input")
add("textarea", "TextArea", "input")
add("img", "Img", "image")
add("video", "Video", "video")
add("progress", "Progress", "meter")
add("meter", "Meter", "meter")
add("hr", "Hr", "spacer", '{ Height = 1, BackgroundColor = "#b4bed1" }')
add("br", "Br", "spacer", "{ Width = 0 }")
return specs
