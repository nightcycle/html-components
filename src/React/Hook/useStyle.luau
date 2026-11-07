--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local StyleStore = require(script.Parent.Parent.Context.StyleStore)
-- Components
-- Hooks
local useStyleScope = require(script.Parent.useStyleScope)
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
export type State = {
	Tag: Types.Tag,
	Style: Types.Style,
	Context: StyleStore.Scope,
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
		Hidden = props.Hidden,
		PreviousSiblings = props.PreviousSiblings,
	}
	local style, scope = useStyleScope({ Node = node, Defaults = defaults, Inline = props.CSS })
	return {
		Tag = tag,
		Style = style,
		Context = scope,
		SetHover = setHover,
		SetActive = setActive,
		SetFocus = setFocus,
	}
end
