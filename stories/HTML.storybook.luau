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
return {
	name = "HTML Components",
	storyRoots = script.Parent.Parent.Packages.HTMLComponents.React.Component:GetChildren(),
	groupRoots = true,
} :: UILabs.Storybook
