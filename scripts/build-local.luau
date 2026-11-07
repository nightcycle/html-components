--!strict
-- Packages
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
-- Modules
local load = require("../tests/load")()
local Document = load("src/Document")
local run = require("./shared/run")
-- Types
-- Constants
local OUTPUT = ".tools/local-demo/html-components-demo.rbxl"
-- References
-- Global Variables
-- Private Functions
local function relativePath(base: string, href: string): string?
	if href:match("^%a[%w+.-]*:") or href:sub(1, 1) == "/" or href:find("\\", 1, true) then
		return nil
	end
	local parts: { string } = {}
	for part in (href:match("^[^?#]*") or href):gmatch("[^/]+") do
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
local path = assert(process.args[1], "Usage: lune run scripts/build-local path/to/index.html")
local source = fs.readFile(path)
local parsed = Document.parse(source)
assert(parsed.Success, "Local fixture contains parser errors; run scripts/parse-document for details")
local base = path:gsub("\\", "/"):match("^(.*)/[^/]+$") or "."
local styles: { string } = {}
for _, resource in Document.stylesheets(parsed) do
	if resource.Href then
		local file = relativePath(base, resource.Href)
		if file and fs.isFile(file) then
			table.insert(styles, string.format("[%q] = %q,", resource.Href, fs.readFile(file)))
		end
	end
end
run("lune", { "run", "scripts/build" })
local place = roblox.deserializePlace(fs.readFile("build/html-components-demo.rbxl"))
local storage = assert(place:FindFirstChild("ReplicatedStorage"))
local fixture = assert(storage:FindFirstChild("LocalDocumentFixture"))
local moduleSource = table.concat({
	"--!strict",
	"-- Packages",
	"-- Modules",
	"local Samples = require(script.Parent.DocumentDemo.Samples)",
	"-- Types",
	"-- Constants",
	"-- References",
	"-- Global Variables",
	"-- Private Functions",
	"-- Class",
	string.format(
		"return { Sample = { Name = %q, HTML = %q, Stylesheets = { %s } } :: Samples.Sample }",
		"Local: " .. (base:match("([^/]+)$") or "document"),
		source,
		table.concat(styles, "\n")
	),
}, "\n")
luau.compile(moduleSource)
local record = (fixture :: unknown) :: { Source: string }
record.Source = moduleSource
fs.writeDir(".tools/local-demo")
fs.writeFile(OUTPUT, roblox.serializePlace(place))
print(`Local fixture demo: {OUTPUT}. Release build outputs contain only the owned example.`)
