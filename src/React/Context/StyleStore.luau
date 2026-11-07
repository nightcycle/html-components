--!strict
-- Services
-- Packages
-- Modules
local CSS = require(script.Parent.Parent.Parent.CSS)
local Decoration = require(script.Parent.Parent.Render.Decoration)
-- Components
-- Hooks
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type Input = {
	Node: Types.Node?,
	Defaults: Types.Style?,
	Inline: Types.Style?,
	Sheets: { Types.StyleSheet }?,
	Text: boolean?,
	ViewportWidth: number?,
}
export type Snapshot = { Style: Types.Style, Context: Types.StyleContext }
export type Listener = () -> ()
export type Disconnect = () -> ()
export type Scope = {
	GetSnapshot: () -> Snapshot,
	Preview: (Input) -> Types.Style,
	Update: (Input) -> (),
	Connect: () -> Disconnect,
	Subscribe: (Listener) -> Disconnect,
	SubscribeStyle: (Listener) -> Disconnect,
}
-- Constants
local EMPTY_STYLE: Types.Style = table.freeze({})
local ROOT: Snapshot = {
	Style = EMPTY_STYLE,
	Context = {
		Sheets = {},
		Ancestors = {},
		Inherited = { Color = "#182033", FontSize = 16, FontFamily = "SansSerif" },
	},
}
-- Variables
local StyleStore = {}
-- References
-- Private Functions
local function equalArray<T>(left: { T }, right: { T }): boolean
	if #left ~= #right then
		return false
	end
	for index, value in left do
		if value ~= right[index] then
			return false
		end
	end
	return true
end

function StyleStore.equal(left: Types.Style, right: Types.Style): boolean
	-- Style contains only scalar fields; this boundary permits iterating its keys.
	local a = (left :: unknown) :: { [string]: unknown }
	local b = (right :: unknown) :: { [string]: unknown }
	for key, value in a do
		if b[key] ~= value then
			return false
		end
	end
	for key, value in b do
		if a[key] ~= value then
			return false
		end
	end
	return true
end

local function equalNode(left: Types.Node, right: Types.Node): boolean
	return left.Tag == right.Tag
		and left.Id == right.Id
		and left.Hover == right.Hover
		and left.Active == right.Active
		and left.Focus == right.Focus
		and left.Disabled == right.Disabled
		and left.Hidden == right.Hidden
		and left.PreviousSiblings == right.PreviousSiblings
		and equalArray(left.Classes, right.Classes)
end

local function equalAncestors(left: { Types.Node }, right: { Types.Node }): boolean
	if #left ~= #right then
		return false
	end
	for index, node in left do
		if not equalNode(node, right[index]) then
			return false
		end
	end
	return true
end

local function resolve(parent: Snapshot, input: Input, previous: Snapshot?): Snapshot
	local context = parent.Context
	local sheets, ancestors, inherited = context.Sheets, context.Ancestors, context.Inherited
	local decoration: Types.TextDecoration? = context.Decoration
	local variables: Types.CSSVariables = context.Variables or {}
	local viewport = input.ViewportWidth or context.ViewportWidth or 1280
	local display: Types.Display? = context.Display
	local style = EMPTY_STYLE
	if input.Node then
		style, variables = CSS.resolve(
			sheets,
			input.Node,
			ancestors,
			inherited,
			input.Defaults or EMPTY_STYLE,
			input.Inline,
			{ ViewportWidth = viewport },
			variables
		)
		style.TextDecoration = Decoration.combine(
			if style.Display == "InlineBlock" or style.Display == "InlineFlex" then nil else decoration,
			style.TextDecoration
		)
		if display == "Flex" or display == "InlineFlex" or display == "Grid" then
			if style.Display == "Inline" or style.Display == "InlineBlock" then
				style.Display = "Block"
			elseif style.Display == "InlineFlex" then
				style.Display = "Flex"
			end
		end
		display = style.Display
		decoration = style.TextDecoration
		table.freeze(style)
		ancestors = table.clone(ancestors)
		table.insert(ancestors, input.Node)
		inherited = CSS.inherited(style)
	elseif input.Text then
		style = table.clone(inherited)
		style.Display, style.TextDecoration = "Inline", decoration
		table.freeze(style)
	elseif input.Sheets and #input.Sheets > 0 then
		sheets = table.clone(sheets)
		for _, sheet in input.Sheets do
			table.insert(sheets, sheet)
		end
	end
	if previous then
		local old = previous.Context
		local sameVariables = true
		for key, value in variables do
			if not old.Variables or old.Variables[key] ~= value then
				sameVariables = false
				break
			end
		end
		for key, value in pairs(old.Variables or {}) do
			if variables[key] ~= value then
				sameVariables = false
				break
			end
		end
		if sameVariables then
			variables = old.Variables or variables
		end
		style = if StyleStore.equal(style, previous.Style) then previous.Style else style
		sheets = if equalArray(sheets, old.Sheets) then old.Sheets else sheets
		ancestors = if equalAncestors(ancestors, old.Ancestors) then old.Ancestors else ancestors
		inherited = if StyleStore.equal(inherited, old.Inherited) then old.Inherited else inherited
		if
			sheets == old.Sheets
			and ancestors == old.Ancestors
			and inherited == old.Inherited
			and decoration == old.Decoration
			and sameVariables
			and viewport == old.ViewportWidth
			and display == old.Display
		then
			return if style == previous.Style then previous else { Style = style, Context = old }
		end
	end
	return {
		Style = style,
		Context = {
			Sheets = sheets,
			Ancestors = ancestors,
			Inherited = inherited,
			Decoration = decoration,
			Variables = variables,
			ViewportWidth = viewport,
			Display = display,
		},
	}
end

local function subscribe(listeners: { [Listener]: boolean }, listener: Listener): Disconnect
	listeners[listener] = true
	return function()
		listeners[listener] = nil
	end
end

local function notify(listeners: { [Listener]: boolean })
	for listener in table.clone(listeners) do
		if listeners[listener] then
			listener()
		end
	end
end

-- Class
function StyleStore.create(parent: Scope?, initial: Input): Scope
	local input = initial
	local function getParent(): Snapshot
		return if parent then parent.GetSnapshot() else ROOT
	end
	local snapshot = resolve(getParent(), input, nil)
	local listeners: { [Listener]: boolean } = {}
	local styleListeners: { [Listener]: boolean } = {}
	local function refresh()
		local previous = snapshot
		snapshot = resolve(getParent(), input, previous)
		-- Descendants must see selector/inheritance changes even when our own style
		-- is unchanged. React subscribers only receive actual style changes.
		if snapshot.Context ~= previous.Context then
			notify(listeners)
		end
		if snapshot.Style ~= previous.Style then
			notify(styleListeners)
		end
	end
	return {
		GetSnapshot = function(): Snapshot
			return snapshot
		end,
		Preview = function(nextInput: Input): Types.Style
			return resolve(getParent(), nextInput, snapshot).Style
		end,
		Update = function(nextInput: Input)
			input = nextInput
			refresh()
		end,
		Connect = function(): Disconnect
			local disconnect = if parent then parent.Subscribe(refresh) else function() end
			-- Close the gap between render and subscribing to the parent.
			refresh()
			return disconnect
		end,
		Subscribe = function(listener: Listener): Disconnect
			return subscribe(listeners, listener)
		end,
		SubscribeStyle = function(listener: Listener): Disconnect
			return subscribe(styleListeners, listener)
		end,
	}
end

return StyleStore
