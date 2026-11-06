--!strict
-- Packages
-- Modules
-- Types
-- Constants
local NAMED = { amp = "&", lt = "<", gt = ">", quot = '"', apos = "'", nbsp = utf8.char(160) }
-- References
-- Global Variables
-- Private Functions
local function valid(codepoint: number): boolean
	return codepoint == 9
		or codepoint == 10
		or codepoint == 13
		or (codepoint >= 32 and codepoint <= 0xD7FF)
		or (codepoint >= 0xE000 and codepoint <= 0xFFFD)
		or (codepoint >= 0x10000 and codepoint <= 0x10FFFF)
end
-- Class
local Entities = {}
function Entities.validate(source: string): (number?, string?)
	local length, invalid = utf8.len(source)
	if not length then
		return invalid, "Invalid UTF-8"
	end
	for position, codepoint in utf8.codes(source) do
		if not valid(codepoint) then
			return position, "Character is not allowed in XML text"
		end
	end
	return nil, nil
end

function Entities.decode(source: string): (string?, number?, string?)
	local pieces: { string } = {}
	local position = 1
	while position <= #source do
		local opening = source:find("&", position, true)
		if not opening then
			table.insert(pieces, source:sub(position))
			break
		end
		table.insert(pieces, source:sub(position, opening - 1))
		local closing = source:find(";", opening + 1, true)
		if not closing then
			return nil, opening, "Unclosed character reference; escape literal & as &amp;"
		end
		local name = source:sub(opening + 1, closing - 1)
		local value: string? = (NAMED :: { [string]: string })[name]
		if not value and name:sub(1, 1) == "#" then
			local hex = name:sub(2, 2) == "x"
			local digits = name:sub(if hex then 3 else 2)
			local codepoint = if digits:match(if hex then "^[%da-fA-F]+$" else "^%d+$")
				then tonumber(digits, if hex then 16 else 10)
				else nil
			if codepoint and valid(codepoint) then
				value = utf8.char(codepoint)
			end
		end
		if not value then
			return nil, opening, `Unsupported or invalid character reference &{name};`
		end
		table.insert(pieces, value)
		position = closing + 1
	end
	return table.concat(pieces), nil, nil
end
return Entities
