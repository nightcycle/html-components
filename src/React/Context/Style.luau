--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local StyleStore = require(script.Parent.StyleStore)
-- Components
-- Hooks
-- Contexts
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(StyleStore.create(nil, {}))
