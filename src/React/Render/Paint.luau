--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
local RobloxComponents = require(script.Parent.Parent.Parent.Parent.RobloxComponents)
-- Modules
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
	local autoX = style.Width == "auto"
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
		ZIndex = style.ZIndex or 1,
	}
end

function Paint.text(style: Types.Style, tag: string, text: string): RobloxComponents.TextLabelProperties
	local props = Paint.box(style, tag) :: RobloxComponents.TextLabelProperties
	local color, transparency = Values.color(style.Color or "#182033")
	local family = if style.FontFamily == "Monospace"
		then "RobotoMono"
		elseif style.FontFamily == "Serif" then "Merriweather"
		else "SourceSansPro"
	props.Text = text
	props.TextColor3 = color or Color3.new()
	props.TextTransparency = transparency
	props.TextSize = Paint.lineHeight(style)
	props.FontFace = Font.new(
		`rbxasset://fonts/families/{family}.json`,
		if style.FontWeight == "Bold" then Enum.FontWeight.Bold else Enum.FontWeight.Regular,
		if style.FontStyle == "Italic" then Enum.FontStyle.Italic else Enum.FontStyle.Normal
	)
	props.TextXAlignment = if style.TextAlign == "Center"
		then Enum.TextXAlignment.Center
		elseif style.TextAlign == "Right" then Enum.TextXAlignment.Right
		else Enum.TextXAlignment.Left
	props.TextYAlignment = Enum.TextYAlignment.Top
	props.TextWrapped = style.WhiteSpace ~= "Pre" and style.WhiteSpace ~= "Nowrap"
	props.RichText = style.TextDecoration == "Underline" or style.TextDecoration == "LineThrough"
	if props.RichText then
		local escaped =
			text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
		local markup = if style.TextDecoration == "Underline" then "u" else "s"
		props.Text = `<{markup}>{escaped}</{markup}>`
	end
	return props
end

function Paint.children(style: Types.Style, layout: boolean): { [string]: React.ReactNode }
	local children: { [string]: React.ReactNode } = {}
	local border = style.BorderWidth or 0
	local function inset(value: Types.Length): UDim
		local length = Values.length(value) or UDim.new()
		return UDim.new(length.Scale, length.Offset + border)
	end
	if
		border > 0
		or style.Padding
		or style.PaddingTop
		or style.PaddingRight
		or style.PaddingBottom
		or style.PaddingLeft
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
		local shadow = Values.shadow(style.BoxShadow)
		if shadow then
			children.Shadow = e(RobloxComponents.UIShadow({
				Offset = shadow.Offset,
				BlurRadius = shadow.Blur,
				Spread = shadow.Spread,
				Color = shadow.Color,
				Transparency = shadow.Transparency,
				Inset = shadow.Inset,
				ZIndex = -1,
			}, {}))
		end
	end
	if style.MinWidth or style.MinHeight or style.MaxWidth or style.MaxHeight then
		local minX, minY = style.MinWidth or 0, style.MinHeight or 0
		children.Constraint = e(RobloxComponents.UISizeConstraint({
			MinSize = Vector2.new(minX, minY),
			MaxSize = Vector2.new(math.max(minX, style.MaxWidth or 100000), math.max(minY, style.MaxHeight or 100000)),
		}, {}))
	end
	if layout then
		local row = style.Display == "Flex" and style.FlexDirection ~= "Column"
		local justify = style.JustifyContent
		local horizontal = if row then justify else style.AlignItems
		local vertical = if row then style.AlignItems else justify
		local flex = if justify == "SpaceBetween"
			then Enum.UIFlexAlignment.SpaceBetween
			elseif justify == "SpaceAround" then Enum.UIFlexAlignment.SpaceAround
			elseif justify == "SpaceEvenly" then Enum.UIFlexAlignment.SpaceEvenly
			else Enum.UIFlexAlignment.None
		children.Layout = e(RobloxComponents.UIListLayout({
			FillDirection = if row then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Values.length(style.Gap or 0),
			HorizontalAlignment = if horizontal == "Center"
				then Enum.HorizontalAlignment.Center
				elseif horizontal == "FlexEnd" then Enum.HorizontalAlignment.Right
				else Enum.HorizontalAlignment.Left,
			VerticalAlignment = if vertical == "Center"
				then Enum.VerticalAlignment.Center
				elseif vertical == "FlexEnd" then Enum.VerticalAlignment.Bottom
				else Enum.VerticalAlignment.Top,
			HorizontalFlex = if row then flex else Enum.UIFlexAlignment.None,
			VerticalFlex = if row then Enum.UIFlexAlignment.None else flex,
			Wraps = style.Display == "Flex" and style.FlexWrap == "Wrap",
		}, {}))
	end
	return children
end

-- Class
return Paint
