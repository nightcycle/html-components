--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local Paint = require(script.Parent.Paint)
-- Components
-- Hooks
-- Contexts
local StyleContext = require(script.Parent.Parent.Context.Style)
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
local useStyle = require(script.Parent.Parent.Hook.useStyle)
-- Constants
-- Variables
local Root = {}
-- References
-- Private Functions
-- Non-string React event keys and metadata need a heterogeneous table. Native
-- property records remain typed; only this React boundary operates on unknown.
function Root.event<P>(props: P, key: unknown, callback: (...unknown) -> ())
	local record = (props :: unknown) :: { [unknown]: unknown }
	local original = record[key]
	record[key] = function(...: unknown)
		callback(...)
		if type(original) == "function" then
			(original :: (...unknown) -> ())(...)
		end
	end
end

function Root.props<P>(native: P, props: Types.Common, state: useStyle.State): P
	local record = (native :: unknown) :: { [unknown]: unknown }
	if props.Id and record.Name == nil then
		record.Name = props.Id
	end
	if props.Ref then
		record.ref = props.Ref
	end
	if props.Hidden or state.Style.Display == "None" then
		record.Visible = false
	end
	Root.event(native, React.Event.MouseEnter, function()
		state.SetHover(true)
	end)
	Root.event(native, React.Event.MouseLeave, function()
		state.SetHover(false)
		state.SetActive(false)
	end)
	Root.event(native, React.Event.InputBegan, function(_instance: unknown, input: unknown)
		local object = input :: InputObject
		if
			object.UserInputType == Enum.UserInputType.MouseButton1
			or object.UserInputType == Enum.UserInputType.Touch
			or object.KeyCode == Enum.KeyCode.ButtonA
			or object.KeyCode == Enum.KeyCode.Space
		then
			state.SetActive(true)
		end
	end)
	Root.event(native, React.Event.InputEnded, function()
		state.SetActive(false)
	end)
	Root.event(native, React.Event.SelectionGained, function()
		state.SetFocus(true)
	end)
	Root.event(native, React.Event.SelectionLost, function()
		state.SetFocus(false)
		state.SetActive(false)
	end)
	return native
end

function Root.children(state: useStyle.State, children: React.ReactNode?, layout: boolean): React.ReactNode
	return {
		HTMLDecoration = React.createElement(React.Fragment, nil, Paint.children(state.Style, layout)),
		HTMLContent = React.createElement(StyleContext.Provider, { value = state.Context }, children),
	}
end

-- Class
return Root
