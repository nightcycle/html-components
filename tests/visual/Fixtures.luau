--!strict
export type Node = {
	Tag: string,
	Id: string,
	Text: string?,
	Value: number?,
	Children: { Node }?,
}
export type Case = { Title: string, Node: Node }
local cases: { Case } = {
	{
		Title = "Article / inherited typography",
		Node = {
			Tag = "Article",
			Id = "article",
			Children = {
				{ Tag = "H2", Id = "heading", Text = "A familiar card" },
				{ Tag = "P", Id = "copy", Text = "CSS follows the component tree." },
				{ Tag = "Button", Id = "action", Text = "Continue" },
			} :: { Node },
		},
	},
	{
		Title = "Flex / centered / space-between",
		Node = {
			Tag = "Div",
			Id = "flex",
			Children = {
				{ Tag = "Button", Id = "one", Text = "One" },
				{ Tag = "Button", Id = "two", Text = "Two" },
				{ Tag = "Button", Id = "three", Text = "Three" },
			} :: { Node },
		},
	},
	{
		Title = "Text / wrapping / decoration",
		Node = {
			Tag = "Div",
			Id = "text",
			Children = {
				{ Tag = "H3", Id = "textHeading", Text = "Readable typography" },
				{
					Tag = "P",
					Id = "wrapped",
					Text = "A short paragraph wraps naturally inside this bounded container.",
				},
				{ Tag = "U", Id = "underline", Text = "Underlined text" },
			} :: { Node },
		},
	},
	{
		Title = "Button / default vertical alignment",
		Node = { Tag = "Button", Id = "button", Text = "Centered action" },
	},
	{
		Title = "Input / TextArea / padding",
		Node = {
			Tag = "Div",
			Id = "form",
			Children = {
				{ Tag = "Input", Id = "input", Text = "Single line" },
				{ Tag = "TextArea", Id = "textarea", Text = "Multiple lines\nSecond line" },
			} :: { Node },
		},
	},
	{
		Title = "Progress / Meter / rounded fill",
		Node = {
			Tag = "Div",
			Id = "meters",
			Children = {
				{ Tag = "Progress", Id = "progress", Value = 0.65 },
				{ Tag = "Meter", Id = "meter", Value = 0.35 },
			} :: { Node },
		},
	},
	{ Title = "Img / corners / border / shadow", Node = { Tag = "Img", Id = "image" } },
	{ Title = "Video / empty media surface", Node = { Tag = "Video", Id = "video" } },
	{
		Title = "Hr / Br / flow spacing",
		Node = {
			Tag = "Div",
			Id = "spacing",
			Children = {
				{ Tag = "P", Id = "above", Text = "Above the rule" },
				{ Tag = "Hr", Id = "rule" },
				{ Tag = "Br", Id = "break" },
				{ Tag = "P", Id = "below", Text = "Below the break" },
			} :: { Node },
		},
	},
}
return {
	Width = 1008,
	Height = 744,
	Cases = cases,
	CSSText = [[
		article, #flex, #text, #form, #meters, #spacing { width: 280px; }
		#article, #text, #form, #meters, #spacing { display: flex; flex-direction: column; }
		#article { height: 176px; padding: 16px; gap: 10px; background-color: #edf2fc;
			color: #25314b; border-radius: 18px 4px 18px 4px; box-shadow: 0px 5px 12px #00000026; }
		#heading { font-size: 24px; height: 28px; }
		#copy { font-size: 16px; height: 22px; }
		#action { height: 40px; }
		#flex { display: flex; height: 136px; padding: 12px; gap: 8px; align-items: center;
			justify-content: space-between; background-color: #edf2fc; border-radius: 12px; }
		#flex button { width: 72px; height: 40px; }
		#text { gap: 10px; height: 156px; color: #25314b; }
		#textHeading { height: 28px; }
		#wrapped { width: 240px; height: 48px; }
		#underline { display: block; height: 24px; }
		#button { width: 240px; height: 44px; }
		#form { height: 164px; gap: 16px; }
		#input { height: 40px; border-radius: 8px; }
		#textarea { height: 108px; border-radius: 8px; }
		#meters { height: 64px; gap: 24px; }
		#progress, #meter { height: 20px; border-radius: 10px; }
		#image { width: 144px; height: 144px; background-color: #bdd3f7;
			border-width: 4px; border-color: #315fe8; border-radius: 24px 6px 24px 6px;
			box-shadow: 0px 6px 12px #00000030; }
		#video { width: 280px; height: 157px; background-color: #182033; border-radius: 10px; }
		#spacing { height: 112px; gap: 8px; }
		#above, #below { height: 24px; }
		#rule { height: 1px; }
		#break { height: 20px; }
	]],
}
