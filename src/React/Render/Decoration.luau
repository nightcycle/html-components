--!strict
-- Packages
-- Modules
local Types = require(script.Parent.Parent.Parent.Types)
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
local Decoration = {}
function Decoration.combine(parent: Types.TextDecoration?, child: Types.TextDecoration?): Types.TextDecoration?
	local underline = parent == "Underline"
		or parent == "UnderlineLineThrough"
		or child == "Underline"
		or child == "UnderlineLineThrough"
	local strike = parent == "LineThrough"
		or parent == "UnderlineLineThrough"
		or child == "LineThrough"
		or child == "UnderlineLineThrough"
	return if underline and strike
		then "UnderlineLineThrough"
		elseif underline then "Underline"
		elseif strike then "LineThrough"
		else child
end
function Decoration.markup(text: string, decoration: Types.TextDecoration?): (string, boolean)
	if not decoration or decoration == "None" then
		return text, false
	end
	local escaped = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
	if decoration == "Underline" or decoration == "UnderlineLineThrough" then
		escaped = `<u>{escaped}</u>`
	end
	if decoration == "LineThrough" or decoration == "UnderlineLineThrough" then
		escaped = `<s>{escaped}</s>`
	end
	return escaped, true
end
return Decoration
