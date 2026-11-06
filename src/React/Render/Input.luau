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
export type Properties = Types.InputProperties
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(tag: Types.Tag, props: Properties, multiline: boolean): React.ReactNode
	local state = useStyle(tag, props, {
		Height = if multiline then 100 else 36,
		BackgroundColor = "#ffffff",
		BorderWidth = 1,
		BorderColor = "#b4bed1",
		Padding = 8,
	}, props.Disabled)
	local value, setValue = React.useState(props.DefaultValue or props.Text or "")
	local _, native = RobloxComponents.TextBox({}, props)
	local _, merged = RobloxComponents.TextBox(
		native,
		Paint.text(state.Style, props.Id or tag, props.Value or value) :: RobloxComponents.TextBoxProperties
	)
	merged.Text = props.Value or value
	merged.RichText = false
	merged.ClearTextOnFocus = false
	merged.MultiLine = multiline
	if props.TextYAlignment == nil then
		merged.TextYAlignment = if multiline then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center
	end
	merged.PlaceholderText = props.Placeholder or props.PlaceholderText or ""
	merged.TextEditable = not props.Disabled and not props.ReadOnly
	if props.Disabled then
		merged.Interactable = false
	end
	Root.props(merged, props, state)
	Root.event(merged, React.Change.Text, function(instance: unknown)
		local box = instance :: TextBox
		if props.Disabled or props.ReadOnly then
			return
		end
		local nextValue = box.Text
		-- React writes also emit Text changes; only report actual user edits.
		if nextValue == (props.Value or value) then
			return
		end
		if props.Value == nil then
			setValue(nextValue)
		end
		if props.OnInput then
			props.OnInput(nextValue)
		end
		if props.Value ~= nil and box.Text ~= props.Value then
			box.Text = props.Value
		end
	end)
	Root.event(merged, React.Event.Focused, function()
		state.SetFocus(true)
	end)
	Root.event(merged, React.Event.FocusLost, function(instance: unknown, enterPressed: unknown)
		state.SetFocus(false)
		if props.OnCommit and not props.Disabled then
			props.OnCommit((instance :: TextBox).Text, enterPressed == true)
		end
	end)
	return e(RobloxComponents.TextBox(merged, {}, Root.children(state, getChildren(props), false)))
end
