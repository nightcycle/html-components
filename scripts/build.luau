--!strict
local fs = require("@lune/fs")
local getMetadata = require("./shared/package-metadata")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local run = require("./shared/run")
fs.writeDir("build")
local metadata = getMetadata()
run("rojo", { "build", "default.project.json", "--output", "build/html-components.rbxm" })
run("rojo", { "build", "dev.project.json", "--output", "build/html-components-demo.rbxl" })
run("wally", { "package", "--output", metadata.Archive })
local roots = roblox.deserializeModel(fs.readFile("build/html-components.rbxm"))
assert(#roots == 1 and roots[1]:IsA("ModuleScript"), "Expected one package root")
local packageRoot = roots[1]
local moduleCount = 0
local function compile(instance: roblox.Instance)
	if instance:IsA("LuaSourceContainer") then
		luau.compile(((instance :: unknown) :: { Source: string }).Source)
		moduleCount += 1
	end
end
compile(packageRoot)
for _, child in packageRoot:GetDescendants() do
	assert(not child.Name:find(".story", 1, true), "Stories leaked into runtime model")
	compile(child)
end
assert(
	packageRoot:FindFirstChild("CSS") and packageRoot:FindFirstChild("React") and packageRoot:FindFirstChild("Layout"),
	"Missing runtime modules"
)
local place = roblox.deserializePlace(fs.readFile("build/html-components-demo.rbxl"))
local storage = assert(place:FindFirstChild("ReplicatedStorage"))
assert(assert(assert(storage:FindFirstChild("Packages")):FindFirstChild("HTMLComponents")):IsA("ModuleScript"))
assert(assert(assert(storage:FindFirstChild("Stories")):FindFirstChild("HTML.storybook")):IsA("ModuleScript"))
for _, instance in place:GetDescendants() do
	compile(instance)
end
local listing = process.exec("wally", { "package", "--list" })
assert(listing.ok, listing.stderr)
local paths = listing.stdout:gsub("\\", "/"):gsub("%./", "")
local allowed: { [string]: boolean } = {
	["default.project.json"] = true,
	["wally.toml"] = true,
	["README.md"] = true,
	LICENSE = true,
	src = true,
	docs = true,
}
for _, line in string.split(paths, "\n") do
	line = line:gsub("%s+$", "")
	assert(not line:find(".story.luau", 1, true), `Story leaked into Wally archive: {line}`)
	assert(
		line == "" or allowed[line] or line:match("^src/") ~= nil or line:match("^docs/") ~= nil,
		`Development file leaked into Wally archive: {line}`
	)
end
for _, spec in require("./tags") do
	assert(paths:find(`src/React/Component/{spec.Name}/init.luau`, 1, true), `Missing packaged component {spec.Tag}`)
end
for _, path in
	{ "src/Layout/Flow.luau", "src/Layout/Host.luau", "src/Layout/Metrics.luau", "src/React/Hook/useFlow.luau" }
do
	assert(paths:find(path, 1, true), `Missing packaged layout module {path}`)
end
print(`Built and compiled {moduleCount} scripts across package and demo; Wally contents verified.`)
