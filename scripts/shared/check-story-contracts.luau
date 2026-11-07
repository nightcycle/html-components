--!strict
-- Packages
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
-- Modules
-- Types
-- Constants
local KEYS: { [string]: boolean } = {
	use = true,
	react = true,
	reactRoblox = true,
	story = true,
	controls = true,
	name = true,
	summary = true,
	cleanup = true,
}
-- References
-- Global Variables
-- Private Functions
local function source(module: roblox.Instance): string
	assert(module:IsA("ModuleScript"), `Expected ModuleScript: {module:GetFullName()}`)
	return ((module :: unknown) :: { Source: string }).Source
end
-- Class
return function(storage: roblox.Instance): number
	local packages = assert(storage:FindFirstChild("Packages"))
	local devPackages = assert(storage:FindFirstChild("DevPackages"))
	local html = assert(packages:FindFirstChild("HTMLComponents"))
	local stories = assert(storage:FindFirstChild("Stories"))
	local tests = assert(storage:FindFirstChild("Tests"))
	local creatorModule: roblox.Instance? = nil
	for _, module in devPackages:GetDescendants() do
		if module.Name == "StoryCreators" and module:IsA("ModuleScript") then
			creatorModule = module
		end
	end
	assert(creatorModule, "Missing installed UI Labs story creator")
	-- Run the installed constructor and every story factory. Rendering belongs to the Studio suite.
	local creators = luau.load(source(creatorModule), {
		environment = {
			script = creatorModule,
			require = function()
				return {}
			end,
		},
		injectGlobals = true,
	})()
	local catalogModule = assert(html:FindFirstChild("Catalog"))
	local catalog = luau.load(source(catalogModule), {
		environment = {
			script = catalogModule,
			require = function()
				return {}
			end,
		},
		injectGlobals = true,
	})()
	local react, renderer = {}, {}
	local cache: { [roblox.Instance]: unknown } = {
		[assert(packages:FindFirstChild("HTMLComponents"))] = { Catalog = catalog },
		[assert(packages:FindFirstChild("React"))] = react,
		[assert(devPackages:FindFirstChild("ReactRoblox"))] = renderer,
		[assert(devPackages:FindFirstChild("UILabs"))] = {
			CreateReactStory = creators.CreateReactStory,
			Slider = function()
				return {}
			end,
		},
		[assert(stories:FindFirstChild("Preview"))] = {},
		[assert(stories:FindFirstChild("PreviewStage"))] = {},
		[assert(storage:FindFirstChild("DocumentDemo"))] = {},
		[assert(tests:FindFirstChild("Layout"))] = {},
		[assert(tests:FindFirstChild("Markup"))] = {},
	}
	local factory = assert(stories:FindFirstChild("CreateStory"))
	local function load(module: roblox.Instance): unknown
		if cache[module] ~= nil then
			return cache[module]
		end
		assert(
			module == factory or module.Name:match("%.story$"),
			`Unexpected story dependency: {module:GetFullName()}`
		)
		local value = luau.load(source(module), {
			environment = {
				script = module,
				game = {
					GetService = function(_, name: string)
						assert(name == "ReplicatedStorage", `Unexpected story service {name}`)
						return storage
					end,
				},
				require = load,
			},
			injectGlobals = true,
			debugName = module:GetFullName(),
		})()
		cache[module] = value
		return value
	end
	local count = 0
	for _, module in storage:GetDescendants() do
		if not (module:IsA("ModuleScript") and module.Name:match("%.story$")) then
			continue
		end
		local value = load(module)
		assert(type(value) == "table", `Story must return a table: {module:GetFullName()}`)
		local story = value :: { [string]: unknown }
		for key in story do
			assert(KEYS[key], `Unknown story key {key}: {module:GetFullName()}`)
		end
		assert(story.use == "react" and type(story.story) == "function", `Invalid React story: {module:GetFullName()}`)
		assert(
			story.react == react and story.reactRoblox == renderer,
			`Missing React libraries: {module:GetFullName()}`
		)
		count += 1
	end
	assert(count == 66, `Expected 66 story contracts, got {count}`)
	return count
end
