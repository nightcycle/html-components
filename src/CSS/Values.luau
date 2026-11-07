--!strict
local Types = require(script.Parent.Parent.Types)
local escape = require(script.Parent.Escape)
local Values = {}

function Values.pascal(value: string): string
	local result = value:gsub("%-([a-z])", string.upper)
	return result:sub(1, 1):upper() .. result:sub(2)
end

function Values.trim(value: string): string
	local start = value:find("%S")
	if not start then
		return ""
	end
	local index, last = start, start
	while index <= #value do
		local char = value:sub(index, index)
		if char == "\\" then
			local _, after = escape(value, index)
			last = after - 1
			index = after
		else
			if not char:match("%s") then
				last = index
			end
			index += 1
		end
	end
	return value:sub(start, last)
end

-- Split only outside quoted strings and parentheses (rgb(), shadow colors, etc.).
function Values.split(value: string, separator: string): { string }
	local out: { string } = {}
	local start, depth = 1, 0
	local quote: string? = nil
	local index = 1
	while index <= #value do
		local char = value:sub(index, index)
		if char == "\\" then
			local _, after = escape(value, index)
			index = after
			continue
		elseif quote then
			if char == quote then
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
		index += 1
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

local function channel(source: string, scale: number): (number?, boolean)
	local value = Values.trim(source)
	local percent = value:sub(-1) == "%"
	if percent then
		value = value:sub(1, -2)
	end
	local unsigned = value:gsub("^[%+%-]", "")
	local mantissa = unsigned:match("^([%d%.]+)[eE][%+%-]?%d+$") or unsigned
	if not mantissa:match("^%d+$") and not mantissa:match("^%d*%.%d+$") then
		return nil, percent
	end
	local number = tonumber(value)
	if not number or number ~= number or math.abs(number) == math.huge then
		return nil, percent
	end
	return math.clamp(number / (if percent then 100 else scale), 0, 1), percent
end

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
		local legacy = body:find(",", 1, true) ~= nil
		local parts: { string } = {}
		local alpha = "1"
		if legacy then
			parts = Values.split(body, ",")
			if #parts == 4 then
				alpha = table.remove(parts) :: string
			end
		else
			local sections = Values.split(body, "/")
			if #sections > 2 then
				return nil, 0
			end
			alpha = sections[2] or "1"
			for token in sections[1]:gmatch("%S+") do
				table.insert(parts, token)
			end
		end
		if #parts ~= 3 then
			return nil, 0
		end
		local r, rp = channel(parts[1], 255)
		local g, gp = channel(parts[2], 255)
		local b, bp = channel(parts[3], 255)
		local a = channel(alpha, 1)
		if r and g and b and a and (not legacy or (rp == gp and gp == bp)) then
			return Color3.new(r, g, b), 1 - a
		end
	end
	return nil, 0
end

function Values.fontFamily(value: string): Types.FontFamily?
	local families = Values.split(value, ",")
	for _, family in families do
		if family == "" then
			return nil
		end
	end
	for _, family in families do
		local lower = family:lower()
		if lower == "sans-serif" then
			return "SansSerif"
		elseif lower == "serif" then
			return "Serif"
		elseif lower == "monospace" then
			return "Monospace"
		end
	end
	return nil
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
