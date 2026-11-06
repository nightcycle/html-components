--!strict
-- Packages
local fs = require("@lune/fs")
local process = require("@lune/process")
-- Modules
local specs = require("./tags")
-- Constants
local PROPERTY_TYPES: { [string]: string } = {
	Container = "Container",
	Text = "Text",
	Button = "Button",
	Input = "Input",
	Image = "Image",
	Video = "Video",
	Meter = "Meter",
	Spacer = "Container",
}
-- Variables
local check = table.find(process.args, "--check") ~= nil
local outputs: { { Path: string, Staged: string } } = {}
-- Private Functions
local function write(path: string, source: string)
	local staged = `.tools/generated-source/{path}`
	fs.writeDir(assert(staged:match("^(.*)/[^/]+$")))
	fs.writeFile(staged, source)
	table.insert(outputs, { Path = path, Staged = staged })
end
-- Class
local header = {
	"--!strict",
	"-- Services",
	"-- Packages",
	"-- Modules",
	"local CSS = require(script.CSS)",
	"local Catalog = require(script.Catalog)",
	"-- Components",
	"local StyleProvider = require(script.React.Component.StyleProvider)",
}
local names: { string } = {}
local tags = { "\tTags = {" }
local catalog = {
	"--!strict",
	"-- Generated from scripts/tags.luau.",
	"local Types = require(script.Parent.Types)",
	"local catalog: { Types.CatalogEntry } = {",
}
local tagType = { "--!strict", "-- Generated from scripts/tags.luau.", "export type Name =" }
local tagLookup = { "local names: { [string]: Name } = {" }
local typeChecks =
	{ "--!strict", "local HTML = require(game.ReplicatedStorage.Packages.HTMLComponents)", "return function()" }
for _, spec in specs do
	local name, tag, kind = spec.Name, spec.Tag, spec.Kind
	local properties = assert(PROPERTY_TYPES[kind]) .. "Properties"
	local renderer = kind:sub(1, 1):upper() .. kind:sub(2)
	local hasDefaults = kind == "Container" or kind == "Text" or kind == "Button" or kind == "Spacer"
	local constants = if hasDefaults then `local DEFAULT_STYLE: Types.Style = {spec.Defaults or "{}"}\n` else ""
	local extra = if hasDefaults
		then ", DEFAULT_STYLE"
		elseif kind == "Input" then ", " .. tostring(tag == "Textarea")
		else ""
	local directory = `src/React/Component/{name}`
	if not check then
		fs.writeDir(directory)
	end
	write(
		`{directory}/init.luau`,
		string.format(
			[=[--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local render = require(script.Parent.Parent.Render.%s)
-- Components
-- Hooks
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type Properties = Types.%s
-- Constants
%s-- Variables
-- References
-- Private Functions
-- Class
return function(props: Properties): React.ReactNode
	return render(%q, props%s)
end
]=],
			renderer,
			properties,
			constants,
			tag,
			extra
		)
	)
	write(
		`{directory}/{name}.story.luau`,
		string.format(
			[=[--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Packages
-- Modules
local createStory = require(ReplicatedStorage.Stories.CreateStory)
-- Components
-- Hooks
-- Contexts
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return createStory(%q)
]=],
			tag
		)
	)
	table.insert(header, `local {name} = require(script.React.Component.{name})`)
	table.insert(names, `\t{name} = {name},`)
	table.insert(tags, `\t\t["{tag}"] = {name},`)
	table.insert(catalog, `\t\{ Tag = "{tag}", Name = "{name}", Kind = "{kind}" \},`)
	table.insert(tagType, `\t| "{tag}"`)
	table.insert(tagLookup, `\t["{string.lower(tag)}"] = "{tag}",`)
	table.insert(typeChecks, `\tlocal {name}Properties: HTML.{name}Properties = \{\}`)
	table.insert(typeChecks, `\tHTML.{name}({name}Properties)`)
end
table.insert(header, "-- Hooks\n-- Contexts\n-- Types\nlocal Types = require(script.Types)")
local componentTypes: { [string]: boolean } = { StyleProviderProperties = true }
for _, spec in specs do
	componentTypes[spec.Name .. "Properties"] = true
end
for name in fs.readFile("src/Types.luau"):gmatch("export type ([%w_]+)") do
	if not componentTypes[name] then
		table.insert(header, `export type {name} = Types.{name}`)
	end
end
for _, spec in specs do
	table.insert(header, `export type {spec.Name}Properties = {spec.Name}.Properties`)
end
table.insert(header, "export type StyleProviderProperties = StyleProvider.Properties")
table.insert(header, "-- Constants\n-- Variables\n-- References\n-- Private Functions\n-- Class\nreturn table.freeze({")
table.insert(header, "\tCSS = CSS,\n\tStyleProvider = StyleProvider,\n\tCatalog = Catalog,")
for _, name in names do
	table.insert(header, name)
end
table.insert(tags, "\t},")
table.insert(header, table.concat(tags, "\n"))
table.insert(header, "})")
table.insert(catalog, "}\nreturn catalog")
table.insert(tagLookup, "}\nreturn function(source: string): Name?\n\treturn names[string.lower(source)]\nend")
table.insert(tagType, table.concat(tagLookup, "\n"))
table.insert(typeChecks, "\tlocal properties: HTML.StyleProviderProperties = {}\n\tHTML.StyleProvider(properties)\nend")
write("src/init.luau", table.concat(header, "\n") .. "\n")
write("src/Catalog.luau", table.concat(catalog, "\n") .. "\n")
write("src/Tag.luau", table.concat(tagType, "\n") .. "\n")
write("tests/roblox/PublicTypes.luau", table.concat(typeChecks, "\n") .. "\n")
local formatArgs = { "--config-path", "stylua.toml" }
for _, output in outputs do
	table.insert(formatArgs, output.Staged)
end
local formatted = process.exec("stylua", formatArgs)
assert(formatted.ok, formatted.stderr)
for _, output in outputs do
	local source = fs.readFile(output.Staged)
	assert(source ~= "", `Empty generated source for {output.Path}`)
	if check then
		assert(fs.isFile(output.Path) and fs.readFile(output.Path) == source, `Generated file is stale: {output.Path}`)
	else
		fs.writeFile(output.Path, source)
	end
end
local folders = { "StyleProvider" }
for _, spec in specs do
	table.insert(folders, spec.Name)
end
table.sort(folders)
local manifest = fs.readFile("wally.toml")
local updated, replacements =
	manifest:gsub("src/React/Component/%b{}", "src/React/Component/{" .. table.concat(folders, ",") .. "}")
assert(replacements == 1, "Expected one generated component-directory glob in wally.toml")
if check then
	assert(manifest == updated, "Wally component-directory list is stale")
else
	fs.writeFile("wally.toml", updated)
end
print(`{#specs} component folders and colocated UI Labs stories {if check then "verified" else "generated"}.`)
