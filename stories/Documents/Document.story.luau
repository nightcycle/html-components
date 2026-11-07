--!strict
-- Packages
local storage = script.Parent.Parent.Parent
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
local UILabs = require(storage.DevPackages.UILabs)
-- Modules
-- Components
local DocumentDemo = require(storage.DocumentDemo)
-- Contexts
-- Hooks
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return UILabs.CreateReactStory({ react = React, reactRoblox = ReactRoblox, controls = {} }, function()
	return React.createElement(DocumentDemo, {})
end)
