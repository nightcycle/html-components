--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local CSS = require(script.Parent.Parent.Parent.CSS)
-- Components
-- Hooks
-- Contexts
local StyleContext = require(script.Parent.Parent.Context.Style)
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type State = {
	Style: Types.Style,
	Context: Types.StyleContext,
	SetHover: (boolean) -> (),
	SetActive: (boolean) -> (),
	SetFocus: (boolean) -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(tag: Types.Tag, props: Types.Common, defaults: Types.Style, disabled: boolean?): State
	local parent = React.useContext(StyleContext)
	local hover, setHover = React.useState(false)
	local active, setActive = React.useState(false)
	local focus, setFocus = React.useState(false)
	local classes: { string } = {}
	for class in (props.ClassName or ""):gmatch("%S+") do
		table.insert(classes, class)
	end
	local node: Types.Node = {
		Tag = tag,
		Id = props.Id,
		Classes = classes,
		Hover = hover,
		Active = active and not disabled,
		Focus = focus,
		Disabled = disabled,
	}
	local style = CSS.resolve(parent.Sheets, node, parent.Ancestors, parent.Inherited, defaults, props.Css)
	local ancestors = table.clone(parent.Ancestors)
	table.insert(ancestors, node)
	return {
		Style = style,
		Context = { Sheets = parent.Sheets, Ancestors = ancestors, Inherited = CSS.inherited(style) },
		SetHover = setHover,
		SetActive = setActive,
		SetFocus = setFocus,
	}
end
