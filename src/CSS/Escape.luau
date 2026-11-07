--!strict
-- Packages
-- Modules
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
-- Read a CSS escape at the backslash, returning the decoded character and next byte.
return function(source: string, index: number): (string?, number)
	local nextIndex = index + 1
	local char = source:sub(nextIndex, nextIndex)
	if char == "" or char == "\n" or char == "\r" or char == "\f" then
		return nil, nextIndex
	end
	if char:match("%x") then
		local start = nextIndex
		while nextIndex < start + 6 and source:sub(nextIndex, nextIndex):match("%x") do
			nextIndex += 1
		end
		local codepoint = assert(tonumber(source:sub(start, nextIndex - 1), 16))
		if codepoint == 0 or codepoint > 0x10FFFF or (codepoint >= 0xD800 and codepoint <= 0xDFFF) then
			codepoint = 0xFFFD
		end
		local terminator = source:sub(nextIndex, nextIndex)
		if terminator:match("[ \t\r\n\f]") then
			nextIndex += if terminator == "\r" and source:sub(nextIndex + 1, nextIndex + 1) == "\n" then 2 else 1
		end
		return utf8.char(codepoint), nextIndex
	end
	-- Preserve a complete UTF-8 character when it is escaped literally.
	local after = utf8.offset(source, 2, nextIndex) or (#source + 1)
	return source:sub(nextIndex, after - 1), after
end
