--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local CSS = require(script.Parent.Parent.Parent.CSS)
local getChildren = require(script.Parent.Parent.Parent.Children)
-- Components
-- Hooks
local useStyleScope = require(script.Parent.Parent.Hook.useStyleScope)
-- Contexts
local StyleContext = require(script.Parent.Parent.Context.Style)
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type Properties = Types.ProviderProperties
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local parsed = React.useMemo(function()
		return if props.CSS then CSS.parse(props.CSS) else nil
	end, { props.CSS or false })
	React.useEffect(function()
		for _, sheet in { parsed, props.StyleSheet } do
			if sheet then
				for _, diagnostic in sheet.Diagnostics do
					warn(`[HTML CSS] {diagnostic.Message}: {diagnostic.Source}`)
				end
			end
		end
	end, { parsed or false, props.StyleSheet or false })
	local sheets = React.useMemo(function(): { Types.StyleSheet }
		local result: { Types.StyleSheet } = {}
		if parsed then
			table.insert(result, parsed)
		end
		if props.StyleSheet then
			table.insert(result, props.StyleSheet)
		end
		return result
	end, { parsed or false, props.StyleSheet or false } :: { unknown })
	local _, scope = useStyleScope({ Sheets = sheets })
	return e(StyleContext.Provider, { value = scope }, getChildren(props))
end
