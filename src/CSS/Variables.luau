--!strict
-- Packages
-- Modules
local Types = require(script.Parent.Parent.Types)
-- Types
-- Constants
local MAX_DEPTH = 32
-- References
-- Global Variables
-- Private Functions
local function expand(
	value: string,
	variables: Types.CSSVariables,
	visiting: { [string]: boolean },
	depth: number
): string?
	if depth > MAX_DEPTH then
		return nil
	end
	local result, position = "", 1
	while true do
		local start = value:find("var(", position, true)
		if not start then
			return result .. value:sub(position)
		end
		result ..= value:sub(position, start - 1)
		local level, cursor, comma = 1, start + 4, nil :: number?
		while cursor <= #value and level > 0 do
			local char = value:sub(cursor, cursor)
			if char == "(" then
				level += 1
			elseif char == ")" then
				level -= 1
			elseif char == "," and level == 1 and not comma then
				comma = cursor
			end
			cursor += 1
		end
		if level ~= 0 then
			return nil
		end
		local name = value:sub(start + 4, (comma or (cursor - 1)) - 1):match("^%s*(.-)%s*$") or ""
		if not name:match("^%-%-[%w_%-]+$") then
			return nil
		end
		local replacement: string? = nil
		if variables[name] and not visiting[name] then
			visiting[name] = true
			replacement = expand(variables[name], variables, visiting, depth + 1)
			visiting[name] = nil
		end
		if not replacement and comma then
			replacement = expand(value:sub(comma + 1, cursor - 2), variables, visiting, depth + 1)
		end
		if not replacement then
			return nil
		end
		result ..= replacement
		position = cursor
	end
end
-- Class
return function(value: string, variables: Types.CSSVariables): string?
	return expand(value, variables, {}, 0)
end
