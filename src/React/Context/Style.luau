--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
-- Components
-- Hooks
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext({
	Sheets = {},
	Ancestors = {},
	Inherited = { Color = "#182033", FontSize = 16, FontFamily = "SansSerif" },
} :: Types.StyleContext)
