--!strict
-- Packages
-- Modules
local Named = require(script.Parent.NamedEntities)
-- Types
-- Constants
local REPLACEMENT = utf8.char(0xFFFD)
local WINDOWS_1252: { [number]: number } = {
	[0x80] = 0x20AC,
	[0x82] = 0x201A,
	[0x83] = 0x0192,
	[0x84] = 0x201E,
	[0x85] = 0x2026,
	[0x86] = 0x2020,
	[0x87] = 0x2021,
	[0x88] = 0x02C6,
	[0x89] = 0x2030,
	[0x8A] = 0x0160,
	[0x8B] = 0x2039,
	[0x8C] = 0x0152,
	[0x8E] = 0x017D,
	[0x91] = 0x2018,
	[0x92] = 0x2019,
	[0x93] = 0x201C,
	[0x94] = 0x201D,
	[0x95] = 0x2022,
	[0x96] = 0x2013,
	[0x97] = 0x2014,
	[0x98] = 0x02DC,
	[0x99] = 0x2122,
	[0x9A] = 0x0161,
	[0x9B] = 0x203A,
	[0x9C] = 0x0153,
	[0x9E] = 0x017E,
	[0x9F] = 0x0178,
}
-- References
-- Global Variables
-- Private Functions
-- Class
return function(source: string, attribute: boolean): string
	local pieces: { string } = {}
	local position = 1
	while position <= #source do
		local opening = source:find("&", position, true)
		if not opening then
			table.insert(pieces, source:sub(position))
			break
		end
		table.insert(pieces, source:sub(position, opening - 1))
		local value: string? = nil
		local ending = opening
		if source:sub(opening + 1, opening + 1) == "#" then
			local digitsStart = opening + 2
			local hex = source:sub(digitsStart, digitsStart):lower() == "x"
			if hex then
				digitsStart += 1
			end
			local digits = source:match(if hex then "^[%da-fA-F]+" else "^%d+", digitsStart)
			if digits then
				local number = tonumber(digits, if hex then 16 else 10) or math.huge
				ending = digitsStart + #digits - 1
				if source:sub(ending + 1, ending + 1) == ";" then
					ending += 1
				end
				value = if number == 0
						or number > 0x10FFFF
						or (number >= 0xD800 and number <= 0xDFFF)
					then REPLACEMENT
					else utf8.char(WINDOWS_1252[number] or number)
			end
		else
			-- HTML uses the longest named match, including legacy names without ;.
			for last = math.min(#source, opening + 32), opening + 1, -1 do
				local name = source:sub(opening + 1, last)
				local decoded = Named[name]
				if decoded then
					local nextCharacter = source:sub(last + 1, last + 1)
					if not (attribute and name:sub(-1) ~= ";" and nextCharacter:match("[%w=]")) then
						value, ending = decoded, last
					end
					break
				end
			end
		end
		table.insert(pieces, value or "&")
		position = ending + 1
	end
	return table.concat(pieces)
end
