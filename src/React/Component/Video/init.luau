--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local render = require(script.Parent.Parent.Render.Video)
-- Components
-- Hooks
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type Properties = Types.VideoProperties
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(props: Properties): React.ReactNode
	return render("Video", props)
end
