--!strict
-- Packages
-- Modules
local Types = require(script.Parent.Parent.Types)
-- Types
-- Constants
local TAGS: { [string]: Types.ContentTag } = {
	div = "Div",
	p = "P",
	span = "Span",
	strong = "Strong",
	b = "B",
	em = "Em",
	i = "I",
	u = "U",
	s = "S",
	del = "Del",
	ins = "Ins",
	code = "Code",
	kbd = "Kbd",
	samp = "Samp",
	small = "Small",
	mark = "Mark",
	abbr = "Abbr",
	time = "Time",
	output = "Output",
	q = "Q",
	cite = "Cite",
	var = "Var",
	label = "Label",
	br = "Br",
}
-- References
-- Global Variables
-- Private Functions
-- Class
return function(name: string): Types.ContentTag?
	return TAGS[string.lower(name)]
end
