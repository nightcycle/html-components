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
local DEFAULT_STYLE: Types.Style = { Color = "#285cdd", TextDecoration = "Underline", Height = 28 }
-- Variables
-- References
-- Private Functions
-- Class
return function(props: Properties): React.ReactNode
	return render("A", props, DEFAULT_STYLE)
end
