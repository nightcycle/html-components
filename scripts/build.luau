--!strict
local checkStoryContracts = require("./shared/check-story-contracts")
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
		-- Instance properties win over child lookup, even when the sourcemap accepts the require.
		for _, child in instance:GetChildren() do
			assert(
				((instance :: unknown) :: { [string]: unknown })[child.Name] == (child :: unknown),
				`Child collides with a Roblox property: {child:GetFullName()}`
			)
		end
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
local storyCount = checkStoryContracts(storage)
assert(assert(assert(storage:FindFirstChild("Packages")):FindFirstChild("HTMLComponents")):IsA("ModuleScript"))
assert(assert(assert(storage:FindFirstChild("Stories")):FindFirstChild("HTML.storybook")):IsA("ModuleScript"))
assert(storage:FindFirstChild("DocumentDemo"), "Missing document demo")
local fixture = assert(storage:FindFirstChild("LocalDocumentFixture"))
assert(
	((fixture :: unknown) :: { Source: string }).Source:find("Sample = nil", 1, true),
	"Local fixture leaked into distributable demo"
)
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
	{
		"src/Layout/Flow.luau",
		"src/Layout/Host.luau",
		"src/Layout/Metrics.luau",
		"src/React/Hook/useFlow.luau",
		"src/Markup/init.luau",
		"src/Markup/Entities.luau",
		"src/Markup/Tags.luau",
		"src/Document/init.luau",
		"src/Document/Names.luau",
		"src/Document/SourceText.luau",
		"src/Document/Tokenizer.luau",
		"src/Document/Entities.luau",
		"src/Document/NamedEntities.luau",
		"src/React/Component/Content/init.luau",
		"src/React/Render/ContentText.luau",
		"src/React/Render/Decoration.luau",
	}
do
	assert(paths:find(path, 1, true), `Missing packaged runtime module {path}`)
end
print(`Built and compiled {moduleCount} scripts; {storyCount} UI Labs story contracts and Wally contents verified.`)
