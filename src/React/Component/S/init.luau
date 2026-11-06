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
local DEFAULT_STYLE: Types.Style = { TextDecoration = "LineThrough" }
-- Variables
-- References
-- Private Functions
-- Class
return function(props: Properties): React.ReactNode
	return render("S", props, DEFAULT_STYLE)
end
