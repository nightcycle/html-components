--!strict
-- Packages
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
-- Modules
local load = require("../tests/load")()
local Document = load("src/Document")
local CSS = load("src/CSS")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
local function relativeFile(base: string, href: string): string?
	-- Local audit only: external URLs and paths outside the fixture are reported, never fetched.
	if href:match("^%a[%w+.-]*:") or href:sub(1, 1) == "/" or href:find("\\", 1, true) then
		return nil
	end
	local clean = href:match("^[^?#]*") or href
	local parts: { string } = {}
	for part in clean:gmatch("[^/]+") do
		if part == ".." then
			if #parts == 0 then
				return nil
			end
			table.remove(parts)
		elseif part ~= "." then
			table.insert(parts, part)
		end
	end
	return base .. "/" .. table.concat(parts, "/")
end
-- Class
local path = assert(process.args[1], "Usage: lune run scripts/parse-document INPUT.html [OUTPUT.json]")
local destination = process.args[2] or "build/document/parsed.json"
local source = fs.readFile(path)
local parsed = Document.parse(source)
local styles = {}
local base = path:gsub("\\", "/"):match("^(.*)/[^/]+$") or "."
for _, resource in Document.stylesheets(parsed) do
	local styleText = resource.Text
	local file = if resource.Href then relativeFile(base, resource.Href) else nil
	if file and fs.isFile(file) then
		styleText = fs.readFile(file)
	end
	local compiled = if styleText then CSS.parse(styleText) else nil
	table.insert(styles, {
		Href = resource.Href,
		Media = resource.Media,
		LocalPath = file,
		Loaded = styleText ~= nil,
		Rules = if compiled then #compiled.Rules else 0,
		Diagnostics = if compiled then compiled.Diagnostics else {},
	})
end
local result = { Document = parsed, Stylesheets = styles, SourcePath = path }
fs.writeDir(destination:gsub("\\", "/"):match("^(.*)/[^/]+$") or ".")
fs.writeFile(destination, serde.encode("json", result, true))
print(
	`Document parsed: {parsed.Success}; {#parsed.Diagnostics} parser diagnostics; {#styles} stylesheets. Report: {destination}`
)
assert(parsed.Success, "Document has parser errors; inspect the report")
