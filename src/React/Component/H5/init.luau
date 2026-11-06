--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local render = require(script.Parent.Parent.Render.Text)
-- Components
-- Hooks
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type Properties = Types.TextProperties
-- Constants
local DEFAULT_STYLE: Types.Style = { FontSize = 18, FontWeight = "Bold" }
-- Variables
-- References
-- Private Functions
-- Class
return function(props: Properties): React.ReactNode
	return render("H5", props, DEFAULT_STYLE)
end
