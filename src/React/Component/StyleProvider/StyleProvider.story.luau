--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Packages
local HTML = require(ReplicatedStorage.Packages.HTMLComponents)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UILabs = require(ReplicatedStorage.DevPackages.UILabs)
-- Modules
-- Components
local PreviewStage = require(ReplicatedStorage.Stories.PreviewStage)
-- Hooks
-- Contexts
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory(
	{ react = React, reactRoblox = ReactRoblox, controls = { Dark = false, Gap = UILabs.Slider(12, 0, 32, 1) } },
	function(props)
		local color = if props.controls.Dark then "#e9efff" else "#25314b"
		local background = if props.controls.Dark then "#25314b" else "#f1f4fb"
		return e(HTML.StyleProvider, {
			CSS = `.card \{ color: {color}; background-color: {background}; padding: 24px; gap: {props.controls.Gap}px; border-radius: 24px 6px 24px 6px; box-shadow: 0px 8px 18px #00000030; \} .card > h2 \{ color: #6685ff; \} .card button:hover \{ background-color: #5479ff; \}`,
		}, {
			Stage = e(PreviewStage, { Size = Vector2.new(480, 300), Inset = 24 } :: PreviewStage.Properties, {
				Card = e(
					HTML.Article,
					{ ClassName = "card", Size = UDim2.fromScale(1, 1), AutomaticSize = Enum.AutomaticSize.None } :: HTML.ContainerProperties,
					{
						Title = e(HTML.H2, { Text = "CSS through context", LayoutOrder = 1 } :: HTML.TextProperties),
						Body = e(
							HTML.P,
							{
								Text = "This text inherits its color. The card has four independent radii and a native UIShadow.",
								LayoutOrder = 2,
							} :: HTML.TextProperties
						),
						Nested = e(HTML.StyleProvider, { CSS = "button { background-color: #315fe8; }" }, {
							Button = e(
								HTML.Button,
								{ Text = "Hover to test the cascade", LayoutOrder = 3 } :: HTML.ButtonProperties
							),
						}),
					}
				),
			}),
		})
	end
)
