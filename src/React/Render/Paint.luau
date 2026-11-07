--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
local RobloxComponents = require(script.Parent.Parent.Parent.Parent.RobloxComponents)
-- Modules
local Decoration = require(script.Parent.Decoration)
local Metrics = require(script.Parent.Parent.Parent.Layout.Metrics)
local Values = require(script.Parent.Parent.Parent.CSS.Values)
-- Components
-- Hooks
-- Contexts
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
-- Constants
-- TextSize is a line height. CSS font-size is an em size. These bundled font
-- metrics are (hhea ascent - descent + lineGap) / unitsPerEm.
local FONT_LINE_HEIGHT: { [Types.FontFamily]: number } = {
	SansSerif = 1.257,
	System = 1.26,
	Serif = 1.257,
	Monospace = 2701 / 2048,
}
-- Variables
local Paint = {}
-- References
-- Private Functions
local e = React.createElement
function Paint.lineHeight(style: Types.Style): number
	local fontFamily: Types.FontFamily = style.FontFamily or "SansSerif"
	return math.round((style.FontSize or 16) * FONT_LINE_HEIGHT[fontFamily])
end

function Paint.box(style: Types.Style, tag: string): RobloxComponents.GuiObjectProperties
	local width = if style.Width then Values.length(style.Width) else nil
	local height = if style.Height then Values.length(style.Height) else nil
	local autoX = style.Width == "Auto" or style.Width == "auto"
	local autoY = height == nil
	local background, transparency = Values.color(style.BackgroundColor or "transparent")
	return {
		Name = tag,
		BackgroundColor3 = background or Color3.new(),
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Size = UDim2.new(width or UDim.new(if autoX then 0 else 1, 0), height or UDim.new(0, 0)),
		AutomaticSize = if autoX and autoY
			then Enum.AutomaticSize.XY
			elseif autoX then Enum.AutomaticSize.X
			elseif autoY then Enum.AutomaticSize.Y
			else Enum.AutomaticSize.None,
		Visible = style.Display ~= "None",
		ClipsDescendants = style.Overflow == "Hidden",
		LayoutOrder = style.Order or 0,
		ZIndex = style.ZIndex or (if style.Position == "Fixed" or style.Position == "Absolute" then 2 else 1),
	}
end

function Paint.text(style: Types.Style, tag: string, text: string): RobloxComponents.TextLabelProperties
	local props = Paint.box(style, tag) :: RobloxComponents.TextLabelProperties
	local color, transparency = Values.color(style.Color or "#182033")
	props.Text = text
	props.TextColor3 = color or Color3.new()
	props.TextTransparency = transparency
	props.TextSize = Paint.lineHeight(style)
	props.FontFace = Metrics.face(style)
	props.TextXAlignment = if style.TextAlign == "Center"
		then Enum.TextXAlignment.Center
		elseif style.TextAlign == "Right" then Enum.TextXAlignment.Right
		else Enum.TextXAlignment.Left
	props.TextYAlignment = Enum.TextYAlignment.Top
	props.TextWrapped = style.WhiteSpace ~= "Pre" and style.WhiteSpace ~= "Nowrap"
	props.Text, props.RichText = Decoration.markup(text, style.TextDecoration)
	return props
end

function Paint.children(style: Types.Style, _layout: boolean): { [string]: React.ReactNode }
	local children: { [string]: React.ReactNode } = {}
	local border = style.BorderWidth or 0
	local function inset(value: Types.Length): UDim
		local length = Values.length(value) or UDim.new()
		return UDim.new(length.Scale, length.Offset + border)
	end
	if
		style.Display ~= "Inline"
		and (
			border > 0
			or style.Padding
			or style.PaddingTop
			or style.PaddingRight
			or style.PaddingBottom
			or style.PaddingLeft
		)
	then
		children.Padding = e(RobloxComponents.UIPadding({
			PaddingTop = inset(style.PaddingTop or style.Padding or 0),
			PaddingRight = inset(style.PaddingRight or style.Padding or 0),
			PaddingBottom = inset(style.PaddingBottom or style.Padding or 0),
			PaddingLeft = inset(style.PaddingLeft or style.Padding or 0),
		}, {}))
	end
	if
		style.BorderRadius
		or style.BorderTopLeftRadius
		or style.BorderTopRightRadius
		or style.BorderBottomRightRadius
		or style.BorderBottomLeftRadius
	then
		children.Corner = e(RobloxComponents.UICorner({
			TopLeftRadius = Values.length(style.BorderTopLeftRadius or style.BorderRadius or 0),
			TopRightRadius = Values.length(style.BorderTopRightRadius or style.BorderRadius or 0),
			BottomRightRadius = Values.length(style.BorderBottomRightRadius or style.BorderRadius or 0),
			BottomLeftRadius = Values.length(style.BorderBottomLeftRadius or style.BorderRadius or 0),
		}, {}))
	end
	if style.BorderWidth and style.BorderWidth > 0 then
		local color, transparency = Values.color(style.BorderColor or style.Color or "black")
		children.Border = e(RobloxComponents.UIStroke({
			Color = color,
			Transparency = transparency,
			Thickness = style.BorderWidth,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		}, {}))
	end
	if style.BoxShadow and style.BoxShadow ~= "none" then
		for index, shadow in ipairs(Values.shadows(style.BoxShadow) or {}) do
			if shadow.Transparency >= 1 then
				continue
			end
			children[if index == 1 then "Shadow" else `Shadow{index}`] = e(RobloxComponents.UIShadow({
				Offset = shadow.Offset,
				BlurRadius = shadow.Blur,
				Spread = shadow.Spread,
				Color = shadow.Color,
				Transparency = shadow.Transparency,
				Inset = shadow.Inset,
				ZIndex = -index,
			}, {}))
		end
	end
	if style.Display ~= "Inline" and (style.MinWidth or style.MinHeight or style.MaxWidth or style.MaxHeight) then
		local minX, minY = style.MinWidth or 0, style.MinHeight or 0
		children.Constraint = e(RobloxComponents.UISizeConstraint({
			MinSize = Vector2.new(minX, minY),
			MaxSize = Vector2.new(math.max(minX, style.MaxWidth or 100000), math.max(minY, style.MaxHeight or 100000)),
		}, {}))
	end

	return children
end

-- Class
return Paint
