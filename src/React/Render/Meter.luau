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
export type Properties = Types.MeterProperties
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(tag: Types.Tag, props: Properties): React.ReactNode
	local state =
		useStyle(tag, props, { Height = 14, BackgroundColor = "#e3e8f2", BorderRadius = 7, Overflow = "Hidden" })
	local low = props.Min or 0
	local high = props.Max or 1
	local value = props.Value or low
	local fraction = if high > low then math.clamp((value - low) / (high - low), 0, 1) else 0
	if fraction ~= fraction then
		fraction = 0
	end
	local _, native = RobloxComponents.Frame({}, props)
	local _, merged =
		RobloxComponents.Frame(native, Paint.box(state.Style, props.Id or tag) :: RobloxComponents.FrameProperties)
	local fillStyle: Types.Style = {
		BorderRadius = state.Style.BorderRadius,
		BorderTopLeftRadius = state.Style.BorderTopLeftRadius,
		BorderTopRightRadius = state.Style.BorderTopRightRadius,
		BorderBottomRightRadius = state.Style.BorderBottomRightRadius,
		BorderBottomLeftRadius = state.Style.BorderBottomLeftRadius,
	}
	return e(RobloxComponents.Frame(Root.props(merged, props, state), {}, {
		Decoration = e(React.Fragment, nil, Root.children(state, getChildren(props), false)),
		Fill = e(RobloxComponents.Frame({
			Name = "Fill",
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Visible = fraction > 0,
			Size = UDim2.fromScale(fraction, 1),
		}, {}, {
			-- Clip a full-width rounded surface to the fraction. This keeps the
			-- track's outer corners and a straight edge at partial values.
			Surface = e(RobloxComponents.Frame({
				BorderSizePixel = 0,
				BackgroundColor3 = props.FillColor or Color3.fromRGB(65, 104, 224),
				Size = UDim2.fromScale(if fraction > 0 then 1 / fraction else 1, 1),
			}, {}, Paint.children(fillStyle, false))),
		})),
	}))
end
