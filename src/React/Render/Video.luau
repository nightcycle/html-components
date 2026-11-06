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
export type Properties = Types.VideoProperties
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(tag: Types.Tag, props: Properties): React.ReactNode
	local state = useStyle(tag, props, { Height = 180, BackgroundColor = "black" })
	local _, native = RobloxComponents.VideoFrame({}, props)
	local base = Paint.box(state.Style, props.Id or tag) :: RobloxComponents.VideoFrameProperties
	base.Video = props.Src or ""
	base.Playing = props.AutoPlay == true
	base.Looped = props.Loop == true
	base.Volume = if props.Muted then 0 else 1
	local _, merged = RobloxComponents.VideoFrame(native, base)
	return e(
		RobloxComponents.VideoFrame(
			Root.props(merged, props, state),
			{},
			Root.children(state, getChildren(props), false)
		)
	)
end
