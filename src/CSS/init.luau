--!strict
local Selector = require(script.Selector)
local Types = require(script.Parent.Types)
local Values = require(script.Values)
local calculate = require(script.Calculation)
local expandVariables = require(script.Variables)
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
	"row-gap",
	"column-gap",
	"top",
	"right",
	"bottom",
	"left",
	"margin-top",
	"margin-right",
	"margin-bottom",
	"margin-left",
	"border-top-left-radius",
	"border-top-right-radius",
	"border-bottom-right-radius",
	"border-bottom-left-radius",
})
register("pixels", { "min-width", "min-height", "max-width", "max-height", "font-size", "border-width" })
register("integer", { "order", "z-index" })
register("number", { "flex-grow", "flex-shrink" })
register("color", { "color", "background-color", "border-color" })
local options: { [string]: { string } } = {
	display = { "block", "inline", "inline-block", "flex", "inline-flex", "grid", "none" },
	["vertical-align"] = { "baseline", "top", "middle", "bottom" },
	["flex-direction"] = { "row", "column" },
	["flex-wrap"] = { "nowrap", "wrap" },
	["justify-content"] = { "flex-start", "center", "flex-end", "space-between", "space-around", "space-evenly" },
	["align-items"] = { "flex-start", "center", "flex-end", "stretch", "baseline" },
	["align-self"] = { "auto", "flex-start", "center", "flex-end", "stretch", "baseline" },
	["place-self"] = { "auto", "center", "stretch" },
	position = { "static", "relative", "absolute", "fixed" },
	["font-family"] = { "sans-serif", "serif", "monospace", "system" },
	["font-weight"] = { "thin", "extra-light", "light", "normal", "medium", "semi-bold", "bold", "extra-bold", "heavy" },
	["font-style"] = { "normal", "italic" },
	["text-align"] = { "left", "center", "right" },
	["text-decoration"] = { "none", "underline", "line-through" },
	["white-space"] = { "normal", "pre", "pre-wrap", "nowrap" },
	overflow = { "visible", "hidden" },
}
for name, allowed in options do
	properties[name] = { Key = Values.pascal(name), Kind = "option", Allowed = allowed }
end
local styleKeys: { [string]: boolean } = {
	Padding = true,
	Margin = true,
	LineHeight = true,
	BorderRadius = true,
	BoxShadow = true,
	GridTemplateColumns = true,
	GridColumn = true,
}
for _, property in properties do
	styleKeys[property.Key] = true
end

local function declaration(name: string, value: string): Types.Style?
	if name == "box-sizing" and value == "border-box" then
		return {}
	end
	if name == "border-style" and value == "solid" then
		return {}
	end
	if name == "grid-template-columns" then
		local count = tonumber(value:match("^repeat%(%s*(%d+)%s*,%s*minmax%(%s*0%s*,%s*1fr%s*%)%s*%)$"))
		return if count and count > 0 and count <= 64 then { GridTemplateColumns = count } else nil
	end
	if name == "grid-column" then
		local first, second = value:match("^span%s+(%d+)%s*/%s*span%s+(%d+)$")
		return if first
				and first == second
				and tonumber(first)
				and tonumber(first) > 0
			then { GridColumn = tonumber(first) }
			else nil
	end
	if name == "font-weight" then
		local weights =
			{ "thin", "extra-light", "light", "normal", "medium", "semi-bold", "bold", "extra-bold", "heavy" }
		local numeric = tonumber(value)
		if numeric and numeric % 100 == 0 and numeric >= 100 and numeric <= 900 then
			value = weights[numeric / 100]
		end
	end
	if name == "font-family" then
		local family: Types.FontFamily? = Values.fontFamily(value)
		if not family then
			return nil
		end
		local style: Types.Style = {}
		style.FontFamily = family
		return style
	end
	if name == "text-decoration" then
		local underline, strike = false, false
		if value == "none" then
			return { TextDecoration = "None" }
		end
		for token in value:gmatch("%S+") do
			if token == "underline" then
				underline = true
			elseif token == "line-through" then
				strike = true
			else
				return nil
			end
		end
		if not underline and not strike then
			return nil
		end
		return {
			TextDecoration = if underline and strike
				then "UnderlineLineThrough"
				elseif underline then "Underline"
				else "LineThrough",
		}
	end
	if name == "line-height" then
		if value == "normal" then
			return { LineHeight = "Normal" }
		end
		local ratio = tonumber(value)
		if ratio and ratio >= 0 and ratio < math.huge then
			return { LineHeight = ratio }
		end
		local pixels = Values.pixels(value)
		return if pixels and pixels >= 0 then { LineHeight = `{pixels}px` } else nil
	end
	if name == "padding" or name == "border-radius" or name == "margin" then
		local tokens: { string } = {}
		for token in value:gmatch("%S+") do
			if name == "margin" and token == "auto" then
				table.insert(tokens, "Auto")
				continue
			end
			local length = Values.length(token)
			if not length or (name ~= "margin" and (length.Scale < 0 or length.Offset < 0)) then
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
		elseif name == "margin" then
			return { MarginTop = a, MarginRight = b, MarginBottom = c, MarginLeft = d }
		end
		return {
			BorderTopLeftRadius = a,
			BorderTopRightRadius = b,
			BorderBottomRightRadius = c,
			BorderBottomLeftRadius = d,
		}
	end
	if name == "box-shadow" then
		if Values.shadows(value) then
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
			if value ~= "auto" or (name ~= "width" and name ~= "height" and not name:match("^margin%-")) then
				return nil
			end
			parsed = "Auto"
		elseif not name:match("^margin%-") and (length.Scale < 0 or length.Offset < 0) then
			return nil
		end
	elseif property.Kind == "pixels" or property.Kind == "integer" or property.Kind == "number" then
		local number = if property.Kind == "pixels" then Values.pixels(value) else tonumber(value)
		if not number or number ~= number or math.abs(number) == math.huge then
			return nil
		end
		if (property.Kind == "pixels" or property.Kind == "number") and number < 0 then
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

local function parseDeclarations(
	source: string,
	diagnostics: { Types.Diagnostic }
): (Types.Style, Types.Style, { Types.CSSDeclaration })
	local normal: Types.Style, important: Types.Style = {}, {}
	local declarations: { Types.CSSDeclaration } = {}
	for _, text in Values.split(source, ";") do
		if text == "" then
			continue
		end
		local name, value = text:match("^([%w_%-]+)%s*:%s*(.-)%s*$")
		if not name or not value then
			table.insert(diagnostics, { Message = "Malformed declaration", Source = text })
			continue
		end
		name = if name:sub(1, 2) == "--" then name else string.lower(name)
		local isImportant = value:match("!%s*important%s*$") ~= nil
		value = Values.trim((value:gsub("!%s*important%s*$", "")))
		local deferred = name:sub(1, 2) == "--"
			or (
				styleKeys[Values.pascal(name)]
				and (
					value:find("var(", 1, true) ~= nil
					or value:find("calc(", 1, true) ~= nil
					or value == "inherit"
					or value == "initial"
					or value == "unset"
					or value == "currentColor"
					or value == "currentcolor"
					or value:match("[%d%.]em$") ~= nil
				)
			)
		local style = if deferred then {} else declaration(name, value)
		if style then
			Values.merge(if isImportant then important else normal, style)
			table.insert(declarations, { Name = name, Value = value, Important = isImportant })
		else
			table.insert(diagnostics, { Message = "Unsupported property or value", Source = text })
		end
	end
	return normal, important, declarations
end

function CSS.declarations(source: string): Types.DeclarationResult
	local diagnostics: { Types.Diagnostic } = {}
	local style, important, declarations = parseDeclarations(source, diagnostics)
	for _, item in declarations do
		if not declaration(item.Name, item.Value) then
			table.insert(diagnostics, {
				Message = "Context-dependent declarations require stylesheet rules",
				Source = item.Name .. ": " .. item.Value,
			})
		end
	end
	return { Style = style, Important = important, Diagnostics = diagnostics }
end

function CSS.validate(source: unknown): Types.DeclarationResult
	local result: Types.DeclarationResult = { Style = {}, Important = {}, Diagnostics = {} }
	if type(source) ~= "table" then
		table.insert(result.Diagnostics, { Message = "CSS must be a PascalCase style table", Source = "CSS" })
		return result
	end
	local output = (result.Style :: unknown) :: { [string]: unknown }
	for key, value in source :: { [unknown]: unknown } do
		local property: Property? = nil
		if type(key) == "string" then
			for _, candidate in properties do
				if candidate.Key == key then
					property = candidate
					break
				end
			end
		end
		local valid = false
		local autoDimension = key == "Width" or key == "Height"
		local finite = type(value) == "number" and value == value and math.abs(value) < math.huge
		if property and property.Kind == "option" and type(value) == "string" then
			local allowed: { string } = property.Allowed or {}
			for _, option in allowed do
				if value == Values.pascal(option) then
					valid = true
				end
			end
		elseif property and property.Kind == "color" and type(value) == "string" then
			valid = Values.color(value) ~= nil
		elseif property and (property.Kind == "pixels" or property.Kind == "integer" or property.Kind == "number") then
			valid = finite
				and (if property.Kind == "integer" then (value :: number) % 1 == 0 else (value :: number) >= 0)
		elseif key == "GridTemplateColumns" or key == "GridColumn" then
			valid = finite and (value :: number) % 1 == 0 and (value :: number) >= 1 and (value :: number) <= 64
		elseif
			(property and property.Kind == "length")
			or key == "Padding"
			or key == "Margin"
			or key == "BorderRadius"
		then
			local length = if type(value) == "string" or type(value) == "number" then Values.length(value) else nil
			local margin = type(key) == "string" and key:sub(1, 6) == "Margin"
			valid = length ~= nil and (margin or (length.Scale >= 0 and length.Offset >= 0))
			if (autoDimension or margin) and (value == "Auto" or value == "auto") then
				valid = true
			end
		elseif key == "LineHeight" then
			local pixels = if type(value) == "string" and value:match("px$") then Values.pixels(value) else nil
			valid = (finite and (value :: number) >= 0) or value == "Normal" or (pixels ~= nil and pixels >= 0)
		elseif key == "BoxShadow" and type(value) == "string" then
			valid = Values.shadows(value) ~= nil
		end
		if key == "TextDecoration" and value == "UnderlineLineThrough" then
			valid = true
		end
		if valid and type(key) == "string" then
			output[key] = value
		else
			table.insert(
				result.Diagnostics,
				{ Message = `Unsupported or invalid style field: {tostring(key)}`, Source = tostring(key) }
			)
		end
	end
	return result
end

function CSS.parse(source: string, nesting: number?): Types.StyleSheet
	local sheet: Types.StyleSheet = { Rules = {}, Diagnostics = {} }
	if (nesting or 0) >= 32 then
		table.insert(sheet.Diagnostics, { Message = "CSS nesting limit exceeded", Source = "@media" })
		return sheet
	end
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
		local minimum = selectorText:match("^@media%s*%(%s*min%-width%s*:%s*([%d%.]+px)%s*%)$")
		local maximum = selectorText:match("^@media%s*%(%s*max%-width%s*:%s*([%d%.]+px)%s*%)$")
		if minimum or maximum then
			local nested = CSS.parse(body, (nesting or 0) + 1)
			for _, rule in nested.Rules do
				if minimum then
					rule.MinWidth = math.max(rule.MinWidth or 0, Values.pixels(minimum) or 0)
				end
				if maximum then
					rule.MaxWidth = math.min(rule.MaxWidth or math.huge, Values.pixels(maximum) or math.huge)
				end
				table.insert(sheet.Rules, rule)
			end
			for _, diagnostic in nested.Diagnostics do
				table.insert(sheet.Diagnostics, diagnostic)
			end
		elseif selectorText:find("@", 1, true) or body:find("{", 1, true) then
			table.insert(
				sheet.Diagnostics,
				{ Message = "At-rules and nested rules are unsupported", Source = selectorText }
			)
		else
			local style, important, declarations = parseDeclarations(body, sheet.Diagnostics)
			for _, text in Values.split(selectorText, ",") do
				local selector = Selector.parse(text)
				if selector then
					table.insert(
						sheet.Rules,
						{ Selector = selector, Style = style, Important = important, Declarations = declarations }
					)
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
		LineHeight = style.LineHeight,
	}
end

local function normalize(style: Types.Style): Types.Style
	local result = table.clone(style)
	if style.Margin then
		result.MarginTop = style.MarginTop or style.Margin
		result.MarginRight = style.MarginRight or style.Margin
		result.MarginBottom = style.MarginBottom or style.Margin
		result.MarginLeft = style.MarginLeft or style.Margin
	end
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
	inline: Types.Style?,
	options: Types.CSSOptions?,
	inheritedVariables: Types.CSSVariables?
): (Types.Style, Types.CSSVariables)
	local result = Values.merge(table.clone(inherited), normalize(defaults))
	local matches: { { Rule: Types.Rule, Order: number } } = {}
	local order = 0
	for _, sheet in sheets do
		for _, rule in sheet.Rules do
			order += 1
			local viewport = if options then options.ViewportWidth or 1280 else 1280
			if
				viewport >= (rule.MinWidth or 0)
				and viewport <= (rule.MaxWidth or math.huge)
				and Selector.matches(rule.Selector, node, ancestors)
			then
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
	local variables = table.clone(inheritedVariables or {})
	for _, important in { false, true } do
		for _, match in matches do
			for _, item in ipairs(match.Rule.Declarations or {}) do
				if item.Important == important and item.Name:sub(1, 2) == "--" then
					variables[item.Name] = item.Value
				end
			end
		end
	end
	local computedVariables: Types.CSSVariables = {}
	for name, value in variables do
		local expanded = expandVariables(value, variables)
		if expanded then
			computedVariables[name] = expanded
		end
	end
	local rootFont = if options then options.RootFontSize or 16 else 16
	local function apply(item: Types.CSSDeclaration, target: Types.Style, fontSize: number)
		if item.Name:sub(1, 2) == "--" then
			return
		end
		local value = expandVariables(item.Value, computedVariables)
		if not value then
			return
		end
		value = Values.trim(value)
		local property = properties[item.Name]
		local key = if property then property.Key else Values.pascal(item.Name)
		if styleKeys[key] and (value == "inherit" or value == "unset" or value == "initial") then
			local inheritedRecord = (inherited :: unknown) :: { [string]: unknown }
			local targetRecord = (target :: unknown) :: { [string]: unknown }
			targetRecord[key] = if value == "initial" then nil else inheritedRecord[key]
			if item.Name == "text-decoration" and not target.TextDecoration then
				target.TextDecoration = "None"
			end
			return
		end
		if value:lower() == "currentcolor" then
			value = target.Color or inherited.Color or "black"
		end
		value = value:gsub("([%+%-]?[%d%.]+r?em)", function(token: string)
			local amount, unit = token:match("([%+%-]?[%d%.]+)(r?em)")
			return tostring((tonumber(amount) or 0) * (if unit == "rem" then rootFont else fontSize)) .. "px"
		end)
		value = calculate(value)
		if not value then
			return
		end
		local parsed = declaration(item.Name, value)
		if parsed then
			Values.merge(target, parsed)
		end
	end
	-- Resolve font size before other em lengths, irrespective of declaration order.
	local typography: Types.Style = table.clone(result)
	for _, important in { false, true } do
		for _, match in matches do
			if match.Rule.Declarations then
				for _, item in match.Rule.Declarations do
					if item.Important == important and item.Name == "font-size" then
						apply(item, typography, inherited.FontSize or 16)
					end
				end
			else
				local fontSize = (if important then match.Rule.Important else match.Rule.Style).FontSize
				if fontSize then
					typography.FontSize = fontSize
				end
			end
		end
		if not important and inline and inline.FontSize then
			typography.FontSize = inline.FontSize
		end
	end
	for _, important in { false, true } do
		for _, match in matches do
			if match.Rule.Declarations then
				for _, item in match.Rule.Declarations do
					if item.Important == important then
						apply(
							item,
							result,
							if item.Name == "font-size" then inherited.FontSize or 16 else typography.FontSize or 16
						)
					end
				end
			else
				Values.merge(result, if important then match.Rule.Important else match.Rule.Style)
			end
		end
		if not important and inline then
			Values.merge(result, normalize(inline))
		end
	end
	return result, computedVariables
end

CSS.matches = Selector.matches
CSS.parseSelector = Selector.parse
return CSS
