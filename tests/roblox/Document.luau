--!strict
-- Packages
local storage = script.Parent.Parent
local HTML = require(storage.Packages.HTMLComponents)
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
-- Modules
local example = require(storage.DocumentDemo.Samples)
local fixture = require(storage.LocalDocumentFixture)
local read = require(storage.DocumentDemo.Reader)
-- Components
local DocumentDemo = require(storage.DocumentDemo)
-- Contexts
-- Hooks
-- Types
-- Constants
local CASES: { DocumentDemo.Properties } = {
	{ InitialTab = "Preview" },
	{ InitialTab = "Structure" },
	{ InitialTab = "Diagnostics" },
}
-- References
-- Global Variables
-- Private Functions
-- Class
return function(): string
	-- A real Instance require catches collisions hidden by the pure-Luau test loader.
	assert(typeof(storage.Packages.HTMLComponents.Document.SourceText) == "Instance")
	local parsed = HTML.Document.parse("<!doctype html><p>Native require &amp; parse")
	assert(parsed.Success, "Public document parser failed in Studio")
	local report = read(example)
	assert(report.Document.Success and report.Elements > 10 and report.Stylesheets == 1)
	assert(#report.Issues == 0, table.concat(report.Issues, "\n"))
	if fixture.Sample then
		local localReport = read(fixture.Sample)
		assert(localReport.Document.Success and localReport.Elements > 0 and localReport.Stylesheets > 0)
	end
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ScreenInsets, gui.Parent = "HTMLDocumentTest", Enum.ScreenInsets.None, game:GetService("StarterGui")
	local root = ReactRoblox.createRoot(gui)
	local ok, problem = pcall(function()
		for _, properties in CASES do
			local tab = assert(properties.InitialTab)
			ReactRoblox.act(function()
				root:render(React.createElement(React.Fragment, { key = tab }, {
					View = React.createElement(DocumentDemo, properties),
				}))
			end)
			task.wait(0.15)
			assert(gui:FindFirstChild("DocumentDemo", true), "Missing document panel")
			if tab == "Preview" then
				local heading = gui:FindFirstChild("Heading", true)
				assert(heading and heading:IsA("TextLabel"), "Parsed heading did not become a text element")
				assert(heading:FindFirstChild("#text"), "Parsed heading lost its mixed text")
			else
				assert(gui:FindFirstChild("InspectorText", true), `Missing {tab} inspector`)
			end
		end
	end)
	ReactRoblox.act(function()
		root:unmount()
	end)
	gui:Destroy()
	assert(ok, tostring(problem))
	return "Native document require, linked stylesheet, component preview and inspector tabs passed."
end
