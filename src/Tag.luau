--!strict
-- Generated from scripts/tags.luau.
export type Name =
	| "Html"
	| "Body"
	| "Div"
	| "Main"
	| "Section"
	| "Article"
	| "Aside"
	| "Header"
	| "Footer"
	| "Nav"
	| "Form"
	| "Figure"
	| "Ul"
	| "Ol"
	| "Li"
	| "Dl"
	| "Dt"
	| "Dd"
	| "Fieldset"
	| "P"
	| "Span"
	| "Label"
	| "Legend"
	| "Figcaption"
	| "Abbr"
	| "Time"
	| "Output"
	| "H1"
	| "H2"
	| "H3"
	| "H4"
	| "H5"
	| "H6"
	| "B"
	| "Strong"
	| "I"
	| "Em"
	| "Cite"
	| "Var"
	| "Address"
	| "S"
	| "Del"
	| "U"
	| "Ins"
	| "Code"
	| "Kbd"
	| "Samp"
	| "Pre"
	| "Small"
	| "Mark"
	| "Blockquote"
	| "Q"
	| "A"
	| "Button"
	| "Input"
	| "Textarea"
	| "Img"
	| "Video"
	| "Progress"
	| "Meter"
	| "Hr"
	| "Br"
local names: { [string]: Name } = {
	["html"] = "Html",
	["body"] = "Body",
	["div"] = "Div",
	["main"] = "Main",
	["section"] = "Section",
	["article"] = "Article",
	["aside"] = "Aside",
	["header"] = "Header",
	["footer"] = "Footer",
	["nav"] = "Nav",
	["form"] = "Form",
	["figure"] = "Figure",
	["ul"] = "Ul",
	["ol"] = "Ol",
	["li"] = "Li",
	["dl"] = "Dl",
	["dt"] = "Dt",
	["dd"] = "Dd",
	["fieldset"] = "Fieldset",
	["p"] = "P",
	["span"] = "Span",
	["label"] = "Label",
	["legend"] = "Legend",
	["figcaption"] = "Figcaption",
	["abbr"] = "Abbr",
	["time"] = "Time",
	["output"] = "Output",
	["h1"] = "H1",
	["h2"] = "H2",
	["h3"] = "H3",
	["h4"] = "H4",
	["h5"] = "H5",
	["h6"] = "H6",
	["b"] = "B",
	["strong"] = "Strong",
	["i"] = "I",
	["em"] = "Em",
	["cite"] = "Cite",
	["var"] = "Var",
	["address"] = "Address",
	["s"] = "S",
	["del"] = "Del",
	["u"] = "U",
	["ins"] = "Ins",
	["code"] = "Code",
	["kbd"] = "Kbd",
	["samp"] = "Samp",
	["pre"] = "Pre",
	["small"] = "Small",
	["mark"] = "Mark",
	["blockquote"] = "Blockquote",
	["q"] = "Q",
	["a"] = "A",
	["button"] = "Button",
	["input"] = "Input",
	["textarea"] = "Textarea",
	["img"] = "Img",
	["video"] = "Video",
	["progress"] = "Progress",
	["meter"] = "Meter",
	["hr"] = "Hr",
	["br"] = "Br",
}
return function(source: string): Name?
	return names[string.lower(source)]
end
