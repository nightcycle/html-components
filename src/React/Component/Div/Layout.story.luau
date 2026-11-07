--!strict
-- Packages
local storage = game:GetService("ReplicatedStorage")
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
local UILabs = require(storage.DevPackages.UILabs)
-- Modules
local Layout = require(storage.Tests.Layout)
-- Components
local PreviewStage = require(storage.Stories.PreviewStage)
-- Contexts
-- Hooks
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return UILabs.CreateReactStory({ react = React, reactRoblox = ReactRoblox, controls = {} }, function()
	return React.createElement(
		PreviewStage,
		{ Size = Vector2.new(772, 484) },
		{ Layout = React.createElement(Layout.View) }
	)
end)
