--!strict
-- Services
-- Packages
local UILabs = require(script.Parent.Parent.DevPackages.UILabs)
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local roots = script.Parent.Parent.Packages.HTMLComponents.React.Component:GetChildren()
table.insert(roots, script.Parent.Documents)
return {
	name = "HTML Components",
	storyRoots = roots,
	groupRoots = true,
} :: UILabs.Storybook
