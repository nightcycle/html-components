--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
local RobloxComponents = require(script.Parent.Parent.Parent.Parent.RobloxComponents)
-- Modules
local Paint = require(script.Parent.Paint)
local Root = require(script.Parent.Root)
local getChildren = require(script.Parent.Parent.Parent.Children)
-- Components
-- Hooks
local useStyle = require(script.Parent.Parent.Hook.useStyle)
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type Properties = Types.ContainerProperties
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(tag: Types.Tag, props: Properties, defaults: Types.Style): React.ReactNode
	local state = useStyle(tag, props, defaults)
	local _, native = RobloxComponents.Frame({}, props)
	local _, merged =
		RobloxComponents.Frame(native, Paint.box(state.Style, props.Id or tag) :: RobloxComponents.FrameProperties)
	return e(
		RobloxComponents.Frame(
			Root.props(merged, props, state, true),
			{},
			Root.children(state, getChildren(props), true)
		)
	)
end
