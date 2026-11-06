--!strict
local React = require(script.Parent.Parent.React)
local Roblox = require(script.Parent.Parent.RobloxComponents)
local Tag = require(script.Parent.Tag)

export type Display = "Block" | "Inline" | "InlineBlock" | "Flex" | "InlineFlex" | "None"
export type VerticalAlign = "Baseline" | "Top" | "Middle" | "Bottom"
export type FlexDirection = "Row" | "Column"
export type FlexWrap = "Nowrap" | "Wrap"
export type JustifyContent = "FlexStart" | "Center" | "FlexEnd" | "SpaceBetween" | "SpaceAround" | "SpaceEvenly"
export type AlignItems = "FlexStart" | "Center" | "FlexEnd"
export type FontFamily = "SansSerif" | "Serif" | "Monospace"
export type FontWeight = "Normal" | "Bold"
export type FontStyle = "Normal" | "Italic"
export type TextAlign = "Left" | "Center" | "Right"
export type TextDecoration = "None" | "Underline" | "LineThrough"
export type WhiteSpace = "Normal" | "Pre" | "PreWrap" | "Nowrap"
export type Overflow = "Visible" | "Hidden"
export type SelectorRelation = "Descendant" | "Child"
export type SelectorState = "Hover" | "Active" | "Focus" | "Disabled"
export type RenderKind = "Container" | "Text" | "Button" | "Input" | "Image" | "Video" | "Meter" | "Spacer"
export type Tag = Tag.Name
export type CatalogEntry = { Tag: Tag, Name: Tag, Kind: RenderKind }

export type Length = number | string
export type Shadow = { Offset: UDim2, Blur: UDim, Spread: UDim2, Color: Color3, Transparency: number, Inset: boolean }
export type Style = {
	Display: Display?,
	Width: Length?,
	Height: Length?,
	MinWidth: number?,
	MinHeight: number?,
	MaxWidth: number?,
	MaxHeight: number?,
	Padding: Length?,
	PaddingTop: Length?,
	PaddingRight: Length?,
	PaddingBottom: Length?,
	PaddingLeft: Length?,
	Gap: Length?,
	Margin: Length?,
	MarginTop: Length?,
	MarginRight: Length?,
	MarginBottom: Length?,
	MarginLeft: Length?,
	LineHeight: Length?,
	VerticalAlign: VerticalAlign?,
	FlexDirection: FlexDirection?,
	FlexWrap: FlexWrap?,
	JustifyContent: JustifyContent?,
	AlignItems: AlignItems?,
	BackgroundColor: string?,
	Color: string?,
	FontSize: number?,
	FontFamily: FontFamily?,
	FontWeight: FontWeight?,
	FontStyle: FontStyle?,
	TextAlign: TextAlign?,
	TextDecoration: TextDecoration?,
	WhiteSpace: WhiteSpace?,
	BorderWidth: number?,
	BorderColor: string?,
	BorderRadius: Length?,
	BorderTopLeftRadius: Length?,
	BorderTopRightRadius: Length?,
	BorderBottomRightRadius: Length?,
	BorderBottomLeftRadius: Length?,
	BoxShadow: string?,
	Overflow: Overflow?,
	Order: number?,
	ZIndex: number?,
}
export type Diagnostic = { Message: string, Source: string }
export type Node = {
	Tag: Tag,
	Id: string?,
	Classes: { string },
	Hover: boolean?,
	Active: boolean?,
	Focus: boolean?,
	Disabled: boolean?,
}
export type SelectorPart = {
	Tag: Tag?,
	Id: string?,
	Classes: { string },
	States: { SelectorState },
	Relation: SelectorRelation?,
}
export type Specificity = { Ids: number, Classes: number, Tags: number }
export type Selector = { Parts: { SelectorPart }, Specificity: Specificity }
export type Rule = { Selector: Selector, Style: Style, Important: Style }
export type StyleMap = { [string]: Style }
export type StyleSheet = { Rules: { Rule }, Diagnostics: { Diagnostic } }
export type StyleContext = { Sheets: { StyleSheet }, Ancestors: { Node }, Inherited: Style }

export type Common = {
	Id: string?,
	ClassName: string?,
	CSS: Style?,
	Hidden: boolean?,
	Children: React.ReactNode?,
	-- Explicit metadata because the typed instance builder filters string ref/children keys.
	Ref: React.Ref<GuiObject>?,
}
export type ContainerProperties = Roblox.FrameProperties & Common
export type TextProperties = Roblox.TextLabelProperties & Common
export type ButtonProperties = Roblox.TextButtonProperties & Common & {
	Disabled: boolean?,
	Href: string?,
	OnActivated: (() -> ())?,
	OnNavigate: ((string) -> ())?,
}
export type InputProperties = Roblox.TextBoxProperties & Common & {
	Value: string?,
	DefaultValue: string?,
	Placeholder: string?,
	Disabled: boolean?,
	ReadOnly: boolean?,
	OnInput: ((string) -> ())?,
	OnCommit: ((string, boolean) -> ())?,
}
export type ImageProperties = Roblox.ImageLabelProperties & Common & { Src: string?, Alt: string? }
export type VideoProperties =
	Roblox.VideoFrameProperties
	& Common
	& { Src: string?, AutoPlay: boolean?, Loop: boolean?, Muted: boolean? }
export type MeterProperties =
	Roblox.FrameProperties
	& Common
	& { Value: number?, Min: number?, Max: number?, FillColor: Color3? }
export type ProviderProperties = { StyleSheet: StyleSheet?, CSS: StyleMap?, Children: React.ReactNode? }

return {}
