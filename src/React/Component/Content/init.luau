--!strict
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local Markup = require(script.Parent.Parent.Parent.Markup)
-- Components
local Br = require(script.Parent.Br)
local ContentText = require(script.Parent.Parent.Render.ContentText)
local Div = require(script.Parent.Div)
-- Contexts
-- Hooks
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type Properties = Types.ContentProperties
-- Constants
local TEXT_TAGS: { [string]: (Types.TextProperties) -> React.ReactNode } = {
	P = require(script.Parent.P),
	Span = require(script.Parent.Span),
	Strong = require(script.Parent.Strong),
	B = require(script.Parent.B),
	Em = require(script.Parent.Em),
	I = require(script.Parent.I),
	U = require(script.Parent.U),
	S = require(script.Parent.S),
	Del = require(script.Parent.Del),
	Ins = require(script.Parent.Ins),
	Code = require(script.Parent.Code),
	Kbd = require(script.Parent.Kbd),
	Samp = require(script.Parent.Samp),
	Small = require(script.Parent.Small),
	Mark = require(script.Parent.Mark),
	Abbr = require(script.Parent.Abbr),
	Time = require(script.Parent.Time),
	Output = require(script.Parent.Output),
	Q = require(script.Parent.Q),
	Cite = require(script.Parent.Cite),
	Var = require(script.Parent.Var),
	Label = require(script.Parent.Label),
}
-- References
-- Global Variables
-- Private Functions
local e = React.createElement
local function render(nodes: { Types.ContentNode }, offset: number): { [string]: React.ReactNode }
	local children: { [string]: React.ReactNode } = {}
	for index, node in nodes do
		local order = offset + index
		if type(node) == "string" then
			children[tostring(index)] = e(ContentText, { Text = node, Order = order })
		else
			local descendants = table.clone(node.Children or {})
			if node.Text then
				table.insert(descendants, 1, node.Text)
			end
			if node.Tag == "Div" or node.Tag == "Br" then
				local props: Types.ContainerProperties =
					{ Id = node.Id, ClassName = node.ClassName, CSS = node.CSS, Ref = node.Ref, LayoutOrder = order }
				children[tostring(index)] = e(if node.Tag == "Div" then Div else Br, props, render(descendants, 0))
			else
				local props: Types.TextProperties =
					{ Id = node.Id, ClassName = node.ClassName, CSS = node.CSS, Ref = node.Ref, LayoutOrder = order }
				children[tostring(index)] = e(assert(TEXT_TAGS[node.Tag]), props, render(descendants, 0))
			end
		end
	end
	return children
end
-- Class
return function(props: Properties): React.ReactNode
	local result = React.useMemo(function()
		return if type(props.Source) == "string" then Markup.parse(props.Source) else Markup.validate(props.Source)
	end, { props.Source })
	React.useEffect(function()
		if props.OnDiagnostics then
			props.OnDiagnostics(result.Diagnostics)
		else
			for _, problem in result.Diagnostics do
				warn(
					`HTML markup {problem.Path or `{problem.Location.Line}:{problem.Location.Column}`}: {problem.Message}`
				)
			end
		end
	end, { result, props.OnDiagnostics } :: { unknown })
	return e(React.Fragment, nil, render(result.Nodes, props.OrderOffset or 0))
end
