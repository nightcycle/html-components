--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local Paint = require(script.Parent.Paint)
-- Components
-- Hooks
local useFlow = require(script.Parent.Parent.Hook.useFlow)
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

function Root.props<P>(native: P, props: Types.Common, state: useStyle.State, layout: boolean?): P
	local record = (native :: unknown) :: { [unknown]: unknown }
	local explicit = (props :: unknown) :: { [string]: unknown }
	local size, automatic = explicit.Size, explicit.AutomaticSize
	local textTransparency, strokeTransparency = record.TextTransparency, record.TextStrokeTransparency
	local backgroundColor, backgroundTransparency = record.BackgroundColor3, record.BackgroundTransparency
	record.ref = useFlow({
		Tag = state.Tag,
		Style = state.Style,
		Layout = layout == true,
		Size = if typeof(size) == "UDim2" then size else nil,
		AutomaticSize = if typeof(automatic) == "EnumItem" then automatic :: Enum.AutomaticSize else nil,
		TextTransparency = if type(textTransparency) == "number" then textTransparency else nil,
		TextStrokeTransparency = if type(strokeTransparency) == "number" then strokeTransparency else nil,
		BackgroundColor = if typeof(backgroundColor) == "Color3" then backgroundColor else nil,
		BackgroundTransparency = if type(backgroundTransparency) == "number" then backgroundTransparency else nil,
	}, props.Ref)
	if props.Id and record.Name == nil then
		record.Name = props.Id
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
