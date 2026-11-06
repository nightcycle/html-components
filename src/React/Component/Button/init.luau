--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local render = require(script.Parent.Parent.Render.Button)
-- Components
-- Hooks
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type Properties = Types.ButtonProperties
-- Constants
local DEFAULT_STYLE: Types.Style =
	{ Height = 38, BackgroundColor = "#315fe8", Color = "white", Padding = 8, BorderRadius = 6, TextAlign = "Center" }
-- Variables
-- References
-- Private Functions
-- Class
return function(props: Properties): React.ReactNode
	return render("Button", props, DEFAULT_STYLE)
end
