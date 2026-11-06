--!strict
-- Packages
-- Modules
-- Types
export type Node = { Tag: string, Id: string, Text: string?, Children: { Node }? }
-- Constants
local function nodes(value: { Node }): { Node }
	return value
end
local NODE: Node = {
	Tag = "Div",
	Id = "Flow",
	Children = nodes({
		{
			Tag = "P",
			Id = "Copy",
			Text = "Text can mix ",
			Children = nodes({
				{
					Tag = "Strong",
					Id = "Bold",
					Text = "bold words and ",
					Children = nodes({
						{ Tag = "Em", Id = "Nested", Text = "nested italic text" },
					}),
				},
				{ Tag = "Span", Id = "Tail", Text = " while wrapping naturally across the same lines." },
			}),
		},
		{
			Tag = "P",
			Id = "Atomic",
			Children = nodes({
				{ Tag = "Span", Id = "Before", Text = "A sized " },
				{ Tag = "Strong", Id = "Badge", Text = "BADGE" },
				{ Tag = "Span", Id = "After", Text = " stays together. " },
				{ Tag = "Br", Id = "Break" },
				{ Tag = "Span", Id = "AfterBreak", Text = "This starts on a new line." },
			}),
		},
		{
			Tag = "Div",
			Id = "FirstBlock",
			Children = { { Tag = "Span", Id = "FirstText", Text = "Block with a 14px bottom margin" } },
		},
		{
			Tag = "Div",
			Id = "SecondBlock",
			Children = { { Tag = "Span", Id = "SecondText", Text = "8px top margin collapses to 14px" } },
		},
	}),
}
local CSS = [[
#Flow { display:block; padding:16px; background-color:white; border-width:1px; border-color:#cbd5e1; font-size:16px; line-height:24px; color:#182033; }
#Copy { margin-bottom:16px; }
#Nested { font-weight:normal; }
#Atomic { margin-bottom:20px; }
#Badge { display:inline-block; width:92px; height:42px; min-width:80px; max-width:100px; padding:8px; vertical-align:middle; background-color:#dbeafe; color:#1e40af; text-align:center; }
#FirstBlock { height:28px; background-color:#f1f5f9; margin-bottom:14px; }
#SecondBlock { height:28px; background-color:#f1f5f9; margin-top:8px; }
]]
-- References
-- Global Variables
-- Private Functions
-- Class
return { Node = NODE, CSS = CSS, Widths = { 260, 440 } }
