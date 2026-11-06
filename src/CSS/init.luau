--!strict
local Selector = require(script.Selector)
local Types = require(script.Parent.Types)
local Values = require(script.Values)
local CSS = {}

export type Style = Types.Style
export type StyleSheet = Types.StyleSheet
export type StyleMap = Types.StyleMap
export type Diagnostic = Types.Diagnostic
type Property = { Key: string, Kind: string, Allowed: { string }? }
local properties: { [string]: Property } = {}
local function register(kind: string, names: { string })
	for _, name in names do
		local key = Values.pascal(name)
		properties[name] = { Key = key, Kind = kind }
	end
end
register("length", {
	"width",
	"height",
	"padding-top",
	"padding-right",
	"padding-bottom",
	"padding-left",
	"gap",
	"border-top-left-radius",
	"border-top-right-radius",
	"border-bottom-right-radius",
	"border-bottom-left-radius",
})
register("pixels", { "min-width", "min-height", "max-width", "max-height", "font-size", "border-width" })
register("integer", { "order", "z-index" })
register("color", { "color", "background-color", "border-color" })
local options: { [string]: { string } } = {
	display = { "block", "flex", "none" },
	["flex-direction"] = { "row", "column" },
	["flex-wrap"] = { "nowrap", "wrap" },
	["justify-content"] = { "flex-start", "center", "flex-end", "space-between", "space-around", "space-evenly" },
	["align-items"] = { "flex-start", "center", "flex-end" },
	["font-family"] = { "sans-serif", "serif", "monospace" },
	["font-weight"] = { "normal", "bold" },
	["font-style"] = { "normal", "italic" },
	["text-align"] = { "left", "center", "right" },
	["text-decoration"] = { "none", "underline", "line-through" },
	["white-space"] = { "normal", "pre", "nowrap" },
	overflow = { "visible", "hidden" },
}
for name, allowed in options do
	properties[name] = { Key = Values.pascal(name), Kind = "option", Allowed = allowed }
end
local styleKeys: { [string]: boolean } = { Padding = true, BorderRadius = true, BoxShadow = true }
for _, property in properties do
	styleKeys[property.Key] = true
end

local function declaration(name: string, value: string): Types.Style?
	if name == "padding" or name == "border-radius" then
		local tokens: { string } = {}
		for token in value:gmatch("%S+") do
			local length = Values.length(token)
			if not length or length.Scale < 0 or length.Offset < 0 then
				return nil
			end
			table.insert(tokens, token)
		end
		if #tokens < 1 or #tokens > 4 then
			return nil
		end
		local a, b, c, d =
			tokens[1], tokens[2] or tokens[1], tokens[3] or tokens[1], tokens[4] or tokens[2] or tokens[1]
		if name == "padding" then
			return { PaddingTop = a, PaddingRight = b, PaddingBottom = c, PaddingLeft = d }
		end
		return {
			BorderTopLeftRadius = a,
			BorderTopRightRadius = b,
			BorderBottomRightRadius = c,
			BorderBottomLeftRadius = d,
		}
	end
	if name == "box-shadow" then
		if value == "none" or Values.shadow(value) then
			return { BoxShadow = value :: string } :: Types.Style
		end
		return nil
	end
	local property = properties[name]
	if not property then
		return nil
	end
	local parsed: string | number = value
	if property.Kind == "length" then
		local length = Values.length(value)
		if not length then
			if value ~= "auto" or (name ~= "width" and name ~= "height") then
				return nil
			end
		elseif length.Scale < 0 or length.Offset < 0 then
			return nil
		end
	elseif property.Kind == "pixels" or property.Kind == "integer" then
		local number = if property.Kind == "pixels" then Values.pixels(value) else tonumber(value)
		if not number or number ~= number or math.abs(number) == math.huge then
			return nil
		end
		if property.Kind == "pixels" and number < 0 then
			return nil
		end
		if property.Kind == "integer" and number % 1 ~= 0 then
			return nil
		end
		parsed = number
	elseif property.Kind == "color" then
		if not Values.color(value) then
			return nil
		end
	elseif property.Allowed then
		if not table.find(property.Allowed, value) then
			return nil
		end
		parsed = Values.pascal(value)
	end
	-- Conversion happens only after the property-specific validation above.
	return ({ [property.Key] = parsed } :: unknown) :: Types.Style
end

local function parseDeclarations(source: string, diagnostics: { Types.Diagnostic }): (Types.Style, Types.Style)
	local normal: Types.Style, important: Types.Style = {}, {}
	for _, text in Values.split(source, ";") do
		if text == "" then
			continue
		end
		local name, value = text:match("^([%a%-]+)%s*:%s*(.-)%s*$")
		if not name or not value then
			table.insert(diagnostics, { Message = "Malformed declaration", Source = text })
			continue
		end
		name = string.lower(name)
		local isImportant = value:match("!%s*important%s*$") ~= nil
		value = Values.trim((value:gsub("!%s*important%s*$", "")))
		local style = declaration(name, value)
		if style then
			Values.merge(if isImportant then important else normal, style)
		else
			table.insert(diagnostics, { Message = `Unsupported property or value: {name}`, Source = text })
		end
	end
	return normal, important
end

function CSS.parse(source: string): Types.StyleSheet
	local sheet: Types.StyleSheet = { Rules = {}, Diagnostics = {} }
	local stripped = source:gsub("/%*.-%*/", "")
	local position = 1
	while position <= #stripped do
		local opening = stripped:find("{", position, true)
		if not opening then
			local tail = Values.trim(stripped:sub(position))
			if tail ~= "" then
				table.insert(sheet.Diagnostics, { Message = "Expected a CSS rule", Source = tail })
			end
			break
		end
		local selectorText = Values.trim(stripped:sub(position, opening - 1))
		local depth, closing = 1, opening + 1
		while closing <= #stripped and depth > 0 do
			local char = stripped:sub(closing, closing)
			if char == "{" then
				depth += 1
			elseif char == "}" then
				depth -= 1
			end
			closing += 1
		end
		if depth ~= 0 then
			table.insert(sheet.Diagnostics, { Message = "Unclosed CSS rule", Source = selectorText })
			break
		end
		local body = stripped:sub(opening + 1, closing - 2)
		if selectorText:find("@", 1, true) or body:find("{", 1, true) then
			table.insert(
				sheet.Diagnostics,
				{ Message = "At-rules and nested rules are unsupported", Source = selectorText }
			)
		else
			local style, important = parseDeclarations(body, sheet.Diagnostics)
			for _, text in Values.split(selectorText, ",") do
				local selector = Selector.parse(text)
				if selector then
					table.insert(sheet.Rules, { Selector = selector, Style = style, Important = important })
				else
					table.insert(sheet.Diagnostics, { Message = "Unsupported selector", Source = text })
				end
			end
		end
		position = closing
	end
	return sheet
end

function CSS.inherited(style: Types.Style): Types.Style
	return {
		Color = style.Color,
		FontSize = style.FontSize,
		FontFamily = style.FontFamily,
		FontWeight = style.FontWeight,
		FontStyle = style.FontStyle,
		TextAlign = style.TextAlign,
		WhiteSpace = style.WhiteSpace,
	}
end

local function normalize(style: Types.Style): Types.Style
	local result = table.clone(style)
	if style.Padding then
		result.PaddingTop = style.PaddingTop or style.Padding
		result.PaddingRight = style.PaddingRight or style.Padding
		result.PaddingBottom = style.PaddingBottom or style.Padding
		result.PaddingLeft = style.PaddingLeft or style.Padding
	end
	if style.BorderRadius then
		result.BorderTopLeftRadius = style.BorderTopLeftRadius or style.BorderRadius
		result.BorderTopRightRadius = style.BorderTopRightRadius or style.BorderRadius
		result.BorderBottomRightRadius = style.BorderBottomRightRadius or style.BorderRadius
		result.BorderBottomLeftRadius = style.BorderBottomLeftRadius or style.BorderRadius
	end
	return result
end

-- Map insertion order is unspecified. Sort selector keys for a deterministic
-- tie-break after specificity; parsed browser CSS retains textual source order.
function CSS.fromMap(styles: Types.StyleMap): Types.StyleSheet
	local sheet: Types.StyleSheet = { Rules = {}, Diagnostics = {} }
	local selectors: { string } = {}
	for selector in styles do
		table.insert(selectors, selector)
	end
	table.sort(selectors)
	for _, source in selectors do
		local normal: Types.Style = {}
		local record = (normal :: unknown) :: { [string]: unknown }
		for key, value in (styles[source] :: unknown) :: { [string]: unknown } do
			if styleKeys[key] then
				record[key] = value
			else
				table.insert(sheet.Diagnostics, {
					Message = `Unsupported style field: {key}; use PascalCase property names`,
					Source = source,
				})
			end
		end
		local style = normalize(normal)
		for _, text in Values.split(source, ",") do
			local selector = Selector.parse(text, true)
			if selector then
				table.insert(sheet.Rules, { Selector = selector, Style = style, Important = {} })
			else
				table.insert(sheet.Diagnostics, {
					Message = "Unsupported selector; use PascalCase tag names and states (Button:Hover)",
					Source = text,
				})
			end
		end
	end
	return sheet
end

function CSS.resolve(
	sheets: { Types.StyleSheet },
	node: Types.Node,
	ancestors: { Types.Node },
	inherited: Types.Style,
	defaults: Types.Style,
	inline: Types.Style?
): Types.Style
	local result = Values.merge(table.clone(inherited), normalize(defaults))
	local matches: { { Rule: Types.Rule, Order: number } } = {}
	local order = 0
	for _, sheet in sheets do
		for _, rule in sheet.Rules do
			order += 1
			if Selector.matches(rule.Selector, node, ancestors) then
				table.insert(matches, { Rule = rule, Order = order })
			end
		end
	end
	table.sort(matches, function(a, b)
		local x, y = a.Rule.Selector.Specificity, b.Rule.Selector.Specificity
		if x.Ids ~= y.Ids then
			return x.Ids < y.Ids
		end
		if x.Classes ~= y.Classes then
			return x.Classes < y.Classes
		end
		if x.Tags ~= y.Tags then
			return x.Tags < y.Tags
		end
		return a.Order < b.Order
	end)
	for _, match in matches do
		Values.merge(result, match.Rule.Style)
	end
	if inline then
		Values.merge(result, normalize(inline))
	end
	for _, match in matches do
		Values.merge(result, match.Rule.Important)
	end
	return result
end

CSS.matches = Selector.matches
CSS.parseSelector = Selector.parse
return CSS
