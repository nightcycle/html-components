--!strict
local Types = require(script.Parent.Parent.Types)
local Values = {}

function Values.pascal(value: string): string
	local result = value:gsub("%-([a-z])", string.upper)
	return result:sub(1, 1):upper() .. result:sub(2)
end

function Values.trim(value: string): string
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Split only outside quoted strings and parentheses (rgb(), shadow colors, etc.).
function Values.split(value: string, separator: string): { string }
	local out: { string } = {}
	local start, depth = 1, 0
	local quote: string? = nil
	for index = 1, #value do
		local char = value:sub(index, index)
		if quote then
			if char == quote and value:sub(index - 1, index - 1) ~= "\\" then
				quote = nil
			end
		elseif char == '"' or char == "'" then
			quote = char
		elseif char == "(" then
			depth += 1
		elseif char == ")" then
			depth -= 1
		elseif depth == 0 and char == separator then
			table.insert(out, Values.trim(value:sub(start, index - 1)))
			start = index + 1
		end
	end
	table.insert(out, Values.trim(value:sub(start)))
	return out
end

function Values.pixels(value: string): number?
	local number = tonumber(value:match("^([%+%-]?[%d%.]+)px$") or value)
	if number and number == number and math.abs(number) < math.huge then
		return number
	end
	return nil
end

function Values.length(value: Types.Length): UDim?
	if type(value) == "number" then
		if value == value and math.abs(value) < math.huge then
			return UDim.new(0, value)
		end
		return nil
	end
	local percent = tonumber(value:match("^([%+%-]?[%d%.]+)%%$"))
	if percent then
		return UDim.new(percent / 100, 0)
	end
	local pixels = Values.pixels(value)
	return if pixels then UDim.new(0, pixels) else nil
end

local named: { [string]: string } = {
	black = "000000",
	white = "ffffff",
	red = "ff0000",
	green = "008000",
	blue = "0000ff",
	gray = "808080",
	grey = "808080",
	yellow = "ffff00",
	orange = "ffa500",
	purple = "800080",
	transparent = "00000000",
}

function Values.color(value: string): (Color3?, number)
	local lower = string.lower(Values.trim(value))
	local hex = named[lower] or lower:match("^#(%x+)$")
	if hex then
		if #hex == 3 or #hex == 4 then
			hex = (hex:gsub(".", "%0%0"))
		end
		if #hex == 6 or #hex == 8 then
			local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
			local alpha = if #hex == 8 then (tonumber(hex:sub(7, 8), 16) or 255) / 255 else 1
			return Color3.fromRGB(r or 0, g or 0, b or 0), 1 - alpha
		end
	end
	local body = lower:match("^rgba?%((.*)%)$")
	if body then
		local parts = Values.split(body, ",")
		local r, g, b, a = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4] or "1")
		if (#parts == 3 or #parts == 4) and r and g and b and a then
			return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255)),
				1 - math.clamp(a, 0, 1)
		end
	end
	return nil, 0
end

export type Shadow = Types.Shadow
function Values.shadow(value: string): Shadow?
	local tokens: { string } = {}
	for _, token in Values.split(Values.trim(value), " ") do
		if token ~= "" then
			table.insert(tokens, token)
		end
	end
	local inset = tokens[1] == "inset"
	if inset then
		table.remove(tokens, 1)
	end
	if #tokens < 4 or #tokens > 5 then
		return nil
	end
	local x, y, blur = Values.pixels(tokens[1]), Values.pixels(tokens[2]), Values.pixels(tokens[3])
	local spread = if #tokens == 5 then Values.pixels(tokens[4]) else 0
	local color, transparency = Values.color(tokens[#tokens])
	if not x or not y or not blur or blur < 0 or not spread or not color then
		return nil
	end
	return {
		Offset = UDim2.fromOffset(x, y),
		Blur = UDim.new(0, blur),
		Spread = UDim2.fromOffset(spread, spread),
		Color = color,
		Transparency = transparency,
		Inset = inset,
	}
end

-- Style is a closed, validated record. This is the sole dynamic field-copy boundary.
function Values.merge(target: Types.Style, source: Types.Style): Types.Style
	local destination = (target :: unknown) :: { [string]: unknown }
	for key, value in (source :: unknown) :: { [string]: unknown } do
		destination[key] = value
	end
	return target
end

return Values
