--!strict
-- Packages
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
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
local function base64(data: string): string
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local output: { string } = {}
	for index = 1, #data, 3 do
		local a, b, c = data:byte(index, index + 2)
		local value = a * 65536 + (b or 0) * 256 + (c or 0)
		local function character(shift: number): string
			local at = math.floor(value / 2 ^ shift) % 64 + 1
			return alphabet:sub(at, at)
		end
		table.insert(
			output,
			character(18) .. character(12) .. (if b then character(6) else "=") .. (if c then character(0) else "=")
		)
	end
	return table.concat(output)
end
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
if process.args[2] then
	local manifestPath = process.args[2]
	local manifest =
		serde.decode("json", fs.readFile(manifestPath)) :: { Assets: { [string]: { Width: number, Height: number, File: string } } }
	local directory = manifestPath:gsub("\\", "/"):match("^(.*)/[^/]+$") or "."
	local lines: { string } = { "--!strict", "return {" }
	local images = roblox.Instance.new("ModuleScript")
	images.Name = "Assets"
	local number = 0
	for key, asset in manifest.Assets do
		assert(
			asset.Width > 0 and asset.Height > 0 and asset.Width <= 1024 and asset.Height <= 1024,
			"Local image dimensions exceed EditableImage limits"
		)
		assert(not asset.File:find("[/\\]") and not asset.File:find("..", 1, true), "Expected a local pixel filename")
		local pixels = fs.readFile(directory .. "/" .. asset.File)
		assert(#pixels == asset.Width * asset.Height * 4, "Pixel buffer size mismatch")
		local data = base64(serde.compress("zstd", pixels))
		number += 1
		local image = roblox.Instance.new("ModuleScript")
		image.Name = `Image{number}`
		local chunks: { string } = {}
		for offset = 1, #data, 60000 do
			local chunk = roblox.Instance.new("ModuleScript")
			chunk.Name = `Pixels{#chunks + 1}`
			local source = "--!strict\nreturn " .. string.format("%q", data:sub(offset, offset + 59999))
			luau.compile(source)
			local chunkRecord = (chunk :: unknown) :: { Source: string }
			chunkRecord.Source = source
			chunk.Parent = image
			table.insert(chunks, `require(script.{chunk.Name})`)
		end
		local imageRecord = (image :: unknown) :: { Source: string }
		imageRecord.Source = string.format(
			"--!strict\nreturn { Width = %d, Height = %d, Data = %s }",
			asset.Width,
			asset.Height,
			table.concat(chunks, " .. ")
		)
		image.Parent = images
		table.insert(lines, string.format("[%q] = require(script.%s),", key, image.Name))
	end
	table.insert(lines, "}")
	local imagesRecord = (images :: unknown) :: { Source: string }
	imagesRecord.Source = table.concat(lines, "\n")
	images.Parent = fixture
	record.Source = record.Source:gsub("Stylesheets = {", "Assets = require(script.Assets), Stylesheets = {", 1)
end
fs.writeDir(".tools/local-demo")
fs.writeFile(OUTPUT, roblox.serializePlace(place))
print(`Local fixture demo: {OUTPUT}. Release build outputs contain only the owned example.`)
