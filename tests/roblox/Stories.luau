--!strict
local storage = script.Parent.Parent
local App = require(storage.Demo)
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
local UILabs = require(storage.DevPackages.UILabs)
return function(): string
	local target = Instance.new("Frame")
	target.Size = UDim2.fromOffset(1200, 800)
	local root = ReactRoblox.createRoot(target)
	local count = 0
	local ok, problem = pcall(function()
		for _, module in storage.Packages.HTMLComponents.React.Component:GetDescendants() do
			if module:IsA("ModuleScript") and module.Name:match("%.story$") then
				local story = require(module) :: UILabs.ReactStory
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
		assert(count == 65, `Expected 62 tags, provider, layout and markup stories, got {count}`)
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
