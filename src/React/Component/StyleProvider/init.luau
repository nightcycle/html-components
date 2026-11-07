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
local MAX_DIAGNOSTIC_PREVIEWS = 3
local MAX_DIAGNOSTIC_LENGTH = 180
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local compiled = React.useMemo(function()
		return if props.CSS then CSS.fromMap(props.CSS) else nil
	end, { props.CSS or false })
	React.useEffect(function()
		local diagnostics: { Types.Diagnostic } = {}
		for _, sheet in { compiled, props.StyleSheet } do
			if sheet then
				for _, diagnostic in sheet.Diagnostics do
					table.insert(diagnostics, diagnostic)
				end
			end
		end
		if props.OnDiagnostics then
			props.OnDiagnostics(diagnostics)
		elseif #diagnostics > 0 then
			local previews: { string } = {}
			for index = 1, math.min(MAX_DIAGNOSTIC_PREVIEWS, #diagnostics) do
				local diagnostic = diagnostics[index]
				local preview = (`{diagnostic.Message}: {diagnostic.Source}`):gsub("%s+", " ")
				table.insert(previews, preview:sub(1, MAX_DIAGNOSTIC_LENGTH))
			end
			warn(
				`[HTML CSS] {#diagnostics} unsupported or invalid CSS entries; previewing {#previews}. `
					.. "Use StyleProvider.OnDiagnostics or StyleSheet.Diagnostics for the complete list.\n"
					.. table.concat(previews, "\n")
			)
		end
	end, { compiled or false, props.StyleSheet or false, props.OnDiagnostics or false } :: { unknown })
	local sheets = React.useMemo(function(): { Types.StyleSheet }
		local result: { Types.StyleSheet } = {}
		if compiled then
			table.insert(result, compiled)
		end
		if props.StyleSheet then
			table.insert(result, props.StyleSheet)
		end
		return result
	end, { compiled or false, props.StyleSheet or false } :: { unknown })
	local _, scope = useStyleScope({ Sheets = sheets, ViewportWidth = props.ViewportWidth })
	return e(StyleContext.Provider, { value = scope }, getChildren(props))
end
