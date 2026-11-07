--!strict
local storage = script.Parent.Parent
local App = require(storage.Demo)
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
local UILabs = require(storage.DevPackages.UILabs)
local STORY_KEYS: { [string]: boolean } = {
	use = true,
	react = true,
	reactRoblox = true,
	story = true,
	controls = true,
	name = true,
	summary = true,
	cleanup = true,
}
return function(): string
	local target = Instance.new("Frame")
	target.Size = UDim2.fromOffset(1200, 800)
	local root = ReactRoblox.createRoot(target)
	local count = 0
	local ok, problem = pcall(function()
		local modules = storage.Packages.HTMLComponents.React.Component:GetDescendants()
		for _, module in storage.Stories.Documents:GetDescendants() do
			table.insert(modules, module)
		end
		for _, module in modules do
			if module:IsA("ModuleScript") and module.Name:match("%.story$") then
				local story = require(module) :: UILabs.ReactStory
				for key in (story :: unknown) :: { [string]: unknown } do
					assert(STORY_KEYS[key], `Unknown UI Labs story key {key}: {module.Name}`)
				end
				assert(
					story.use == "react" and story.react == React and story.reactRoblox == ReactRoblox,
					`Invalid UI Labs React configuration: {module.Name}`
				)
				local mounted, issue = pcall(function()
					ReactRoblox.act(function()
						root:render(React.createElement(story.story, {
							controls = {
								Text = "Live story check",
								Disabled = false,
								Dark = false,
								Value = 0.5,
								Radius = 10,
								Gap = 12,
							},
						}))
					end)
				end)
				assert(mounted, `{module.Name}: {tostring(issue)}`)
				assert(#target:GetChildren() > 0, `Empty story {module.Name}`)
				count += 1
			end
		end
		assert(count == 66, `Expected 62 tags, provider, layout, markup and document stories, got {count}`)
		ReactRoblox.act(function()
			root:render(React.createElement(App))
		end)
		assert(#target:GetDescendants() > 500, "Demo gallery did not mount")
	end)
	ReactRoblox.act(function()
		root:unmount()
	end)
	assert(#target:GetChildren() == 0, "Story/demo cleanup leaked children")
	target:Destroy()
	assert(ok, tostring(problem))
	return `Mounted {count} UI Labs stories and the complete demo; cleanup passed.`
end
