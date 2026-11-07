--!strict
-- Packages
local storage = game:GetService("ReplicatedStorage")
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
local UILabs = require(storage.DevPackages.UILabs)
-- Modules
local Markup = require(storage.Tests.Markup)
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
		{ Size = Vector2.new(1008, 744) },
		{ Content = React.createElement(Markup.View, {}) }
	)
end)
