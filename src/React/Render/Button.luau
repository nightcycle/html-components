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
export type Properties = Types.ButtonProperties
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(tag: Types.Tag, props: Properties, defaults: Types.Style): React.ReactNode
	local state = useStyle(tag, props, defaults, props.Disabled)
	local _, native = RobloxComponents.TextButton({}, props)
	native.Text = nil
	local _, merged = RobloxComponents.TextButton(
		native,
		Paint.text(state.Style, props.Id or tag, props.Text or tag) :: RobloxComponents.TextButtonProperties
	)
	merged.AutoButtonColor = false
	if props.TextYAlignment == nil then
		merged.TextYAlignment = Enum.TextYAlignment.Center
	end
	if props.Disabled then
		merged.Interactable = false
		merged.Selectable = false
	end
	Root.props(merged, props, state)
	Root.event(merged, React.Event.Activated, function()
		if props.Disabled then
			return
		end
		if props.OnActivated then
			props.OnActivated()
		end
		if props.Href and props.OnNavigate then
			props.OnNavigate(props.Href)
		end
	end)
	return e(RobloxComponents.TextButton(merged, {}, Root.children(state, getChildren(props), false)))
end
