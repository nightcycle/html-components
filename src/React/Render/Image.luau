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
export type Properties = Types.ImageProperties
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(tag: Types.Tag, props: Properties): React.ReactNode
	local state = useStyle(tag, props, if props.IntrinsicSize then {} else { Height = 160 })
	local _, native = RobloxComponents.ImageLabel({}, props)
	local base = Paint.box(state.Style, props.Id or tag) :: RobloxComponents.ImageLabelProperties
	base.Image = if props.ImageContent then nil else props.Src or ""
	base.ScaleType = Enum.ScaleType.Fit
	local _, merged = RobloxComponents.ImageLabel(native, base)
	return e(
		RobloxComponents.ImageLabel(
			Root.props(merged, props, state),
			{},
			Root.children(state, getChildren(props), false)
		)
	)
end
