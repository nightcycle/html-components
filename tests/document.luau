--!strict
-- Packages
local fs = require("@lune/fs")
local serde = require("@lune/serde")
-- Modules
local load = require("./load")()
local Document = load("src/Document")
-- Types
type Snapshot = {
	Kind: string,
	Name: string?,
	Text: string?,
	Namespace: string?,
	Attributes: { [string]: string }?,
	Children: { Snapshot }?,
}
type Case = { Name: string, Source: string, Expected: { Snapshot } }
-- Constants
-- References
-- Global Variables
local checks = 0
-- Private Functions
local function check(condition: boolean, message: string)
	assert(condition, message)
	checks += 1
end
local function equal(left: unknown, right: unknown): boolean
	if typeof(left) ~= typeof(right) then
		return false
	end
	if typeof(left) ~= "table" or typeof(right) ~= "table" then
		return left == right
	end
	local a = left :: { [unknown]: unknown }
	local b = right :: { [unknown]: unknown }
	for key, value in a do
		if not equal(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end
local function normalize(node): Snapshot
	if node.Kind == "Element" then
		local attributes: { [string]: string } = {}
		local children: { Snapshot } = {}
		for _, attr in node.Attributes do
			attributes[attr.SourceName] = attr.Value
		end
		for _, child in node.Children do
			table.insert(children, normalize(child))
		end
		return {
			Kind = node.Kind,
			Name = node.SourceName,
			Namespace = node.Namespace,
			Attributes = attributes,
			Children = children,
		}
	end
	return { Kind = node.Kind, Name = node.Name, Text = node.Text }
end
-- Class
local cases: { Case } = serde.decode("json", fs.readFile("tests/fixtures/document-cases.json"))
for _, case in cases do
	local result = Document.parse(case.Source)
	check(result.Success, `Document failed: {case.Name}`)
	local actual: { Snapshot } = {}
	for _, node in result.Children do
		table.insert(actual, normalize(node))
	end
	check(equal(actual, case.Expected), `Chromium tree mismatch: {case.Name}\n{serde.encode("json", actual)}`)
end
for _, source in
	{
		"<b><i>misnested</b>tail</i>",
		"<a>one<a>two</a></a>",
		"<template><p>template</p></template>",
		"<noscript><p>conditional</p></noscript>",
		"<table>fostered text<tr><td>cell</td></tr></table>",
		"<script><!-- escaped script --></script>",
		'<!DOCTYPE html PUBLIC "legacy">',
		"<?processor ignored?>",
	}
do
	local result = Document.parse(source)
	check(not result.Success and #result.Diagnostics > 0, `Unsupported input accepted: {source}`)
end
for _, source in
	{ string.rep("x", 1024 * 1024 + 1), string.rep("<div>", 130), string.rep("<br>", 20001), string.char(255) }
do
	local result = Document.parse(source)
	check(not result.Success and #result.Diagnostics > 0, "Resource/UTF-8 limits must fail explicitly")
end
local linked = Document.parse(
	'<link rel="alternate STYLESHEET" href="a.css" media="screen"><style>p { color: red; }</style><link rel=icon href=icon.png>'
)
local styles = Document.stylesheets(linked)
check(
	#styles == 2 and styles[1].Href == "a.css" and styles[1].Media == "screen" and styles[2].Text == "p { color: red; }",
	"Ordered stylesheet discovery"
)
local custom = Document.parse('<my-widget data-item="A" data_item="B"></my-widget>')
local element = custom.Children[1].Children[2].Children[1]
check(element.Tag == "MyWidget" and element.Attributes[1].Name == "DataItem", "PascalCase public names")
check(
	Document.attribute(element, "DATA-ITEM") == "A" and Document.attribute(element, "data_item") == "B",
	"Raw attribute names preserve collisions"
)
local position = Document.parse("<p>a\r\nb\rc\n<template>").Diagnostics[1].Location
check(
	position.Line == 4 and position.Column == 1 and position.Offset == 11,
	"Locations retain original byte offsets and CR/LF line numbers"
)
print(`{checks} document checks passed, including {#cases} Chromium DOM fixtures.`)
