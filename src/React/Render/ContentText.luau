--!strict
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
local Roblox = require(script.Parent.Parent.Parent.Parent.RobloxComponents)
-- Modules
local Paint = require(script.Parent.Paint)
-- Components
-- Contexts
-- Hooks
local useFlow = require(script.Parent.Parent.Hook.useFlow)
local useStyleScope = require(script.Parent.Parent.Hook.useStyleScope)
-- Types
type Properties = { Text: string, Order: number }
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(props: Properties): React.ReactNode
	-- Anonymous text inherits typography but never adds a selector node.
	local style = useStyleScope({ Text = true })
	local native = Paint.text(style, "#text", props.Text)
	native.LayoutOrder = props.Order
	local ref = useFlow({
		Tag = "Span",
		Style = style,
		Layout = true,
		TextTransparency = native.TextTransparency,
		BackgroundColor = native.BackgroundColor3,
		BackgroundTransparency = native.BackgroundTransparency,
	}, nil)
	-- Builder metadata belongs on the first argument, as for normal HTML roots.
	local record = (native :: unknown) :: { [unknown]: unknown }
	record.ref = ref
	return React.createElement(Roblox.TextLabel(native, {}))
end
