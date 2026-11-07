--!strict
local React = require(script.Parent.Parent.React)
local Roblox = require(script.Parent.Parent.RobloxComponents)
local Tag = require(script.Parent.Tag)

export type Display = "Block" | "Inline" | "InlineBlock" | "Flex" | "InlineFlex" | "Grid" | "None"
export type VerticalAlign = "Baseline" | "Top" | "Middle" | "Bottom"
export type FlexDirection = "Row" | "Column"
export type FlexWrap = "Nowrap" | "Wrap"
export type JustifyContent = "FlexStart" | "Center" | "FlexEnd" | "SpaceBetween" | "SpaceAround" | "SpaceEvenly"
export type AlignItems = "FlexStart" | "Center" | "FlexEnd" | "Stretch" | "Baseline"
export type AlignSelf = "Auto" | "FlexStart" | "Center" | "FlexEnd" | "Stretch" | "Baseline"
export type Position = "Static" | "Relative" | "Absolute" | "Fixed"
export type FontFamily = "SansSerif" | "Serif" | "Monospace" | "System"
export type FontWeight =
	"Thin"
	| "ExtraLight"
	| "Light"
	| "Normal"
	| "Medium"
	| "SemiBold"
	| "Bold"
	| "ExtraBold"
	| "Heavy"
export type FontStyle = "Normal" | "Italic"
export type TextAlign = "Left" | "Center" | "Right"
export type TextDecoration = "None" | "Underline" | "LineThrough" | "UnderlineLineThrough"
export type WhiteSpace = "Normal" | "Pre" | "PreWrap" | "Nowrap"
export type Overflow = "Visible" | "Hidden"
export type SelectorRelation = "Descendant" | "Child" | "AdjacentSibling" | "SubsequentSibling"
export type SelectorState = "Hover" | "Active" | "Focus" | "Disabled" | "NotHidden"
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
	AlignSelf: AlignSelf?,
	PlaceSelf: AlignSelf?,
	GridTemplateColumns: number?,
	GridColumn: number?,
	ColumnGap: Length?,
	RowGap: Length?,
	FlexGrow: number?,
	FlexShrink: number?,
	Position: Position?,
	Top: Length?,
	Right: Length?,
	Bottom: Length?,
	Left: Length?,
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
	Hidden: boolean?,
	PreviousSiblings: { Node }?,
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
export type CSSDeclaration = { Name: string, Value: string, Important: boolean }
export type CSSVariables = { [string]: string }
export type CSSOptions = { ViewportWidth: number?, RootFontSize: number? }
export type Rule = {
	Selector: Selector,
	Style: Style,
	Important: Style,
	Declarations: { CSSDeclaration }?,
	MinWidth: number?,
	MaxWidth: number?,
}
export type StyleMap = { [string]: Style }
export type StyleSheet = { Rules: { Rule }, Diagnostics: { Diagnostic } }
export type StyleContext = {
	Sheets: { StyleSheet },
	Ancestors: { Node },
	Inherited: Style,
	Decoration: TextDecoration?,
	Variables: CSSVariables?,
	ViewportWidth: number?,
	Display: Display?,
}

export type ContentTag =
	"Div"
	| "P"
	| "Span"
	| "Strong"
	| "B"
	| "Em"
	| "I"
	| "U"
	| "S"
	| "Del"
	| "Ins"
	| "Code"
	| "Kbd"
	| "Samp"
	| "Small"
	| "Mark"
	| "Abbr"
	| "Time"
	| "Output"
	| "Q"
	| "Cite"
	| "Var"
	| "Label"
	| "Br"
export type ContentElement = {
	Tag: ContentTag,
	Id: string?,
	ClassName: string?,
	CSS: Style?,
	Text: string?,
	Children: { ContentNode }?,
	Ref: React.Ref<GuiObject>?,
}
export type ContentNode = string | ContentElement
export type ContentSource = string | { ContentNode }
export type SourceLocation = { Offset: number, Line: number, Column: number }
export type MarkupDiagnostic = { Message: string, Source: string, Location: SourceLocation, Path: string? }
export type MarkupResult = { Success: boolean, Nodes: { ContentNode }, Diagnostics: { MarkupDiagnostic } }
export type ContentProperties = {
	Source: ContentSource,
	OrderOffset: number?,
	OnDiagnostics: (({ MarkupDiagnostic }) -> ())?,
}
export type DeclarationResult = { Style: Style, Important: Style, Diagnostics: { Diagnostic } }

export type DocumentElementKind = "Element"
export type DocumentTextKind = "Text"
export type DocumentCommentKind = "Comment"
export type DocumentDoctypeKind = "Doctype"
export type DocumentNodeKind = DocumentElementKind | DocumentTextKind | DocumentCommentKind | DocumentDoctypeKind
export type DocumentNamespace = "HTML" | "SVG" | "MathML"
export type DocumentSeverity = "Warning" | "Error"
export type DocumentIssue = "Syntax" | "Unsupported" | "Limit"
export type DocumentAttribute = { Name: string, SourceName: string, Value: string, Location: SourceLocation }
export type DocumentElement = {
	Kind: DocumentElementKind,
	Tag: string,
	SourceName: string,
	Namespace: DocumentNamespace,
	Attributes: { DocumentAttribute },
	Children: { DocumentNode },
	Location: SourceLocation?,
}
export type DocumentText = { Kind: DocumentTextKind, Text: string, Location: SourceLocation? }
export type DocumentComment = { Kind: DocumentCommentKind, Text: string, Location: SourceLocation? }
export type DocumentDoctype = { Kind: DocumentDoctypeKind, Name: string, Location: SourceLocation? }
export type DocumentNode = DocumentElement | DocumentText | DocumentComment | DocumentDoctype
export type DocumentDiagnostic = {
	Severity: DocumentSeverity,
	Issue: DocumentIssue,
	Message: string,
	Location: SourceLocation,
}
export type DocumentResult = { Success: boolean, Children: { DocumentNode }, Diagnostics: { DocumentDiagnostic } }
export type DocumentStyleSource = { Href: string?, Text: string?, Media: string?, Location: SourceLocation? }

export type Common = {
	Id: string?,
	ClassName: string?,
	CSS: Style?,
	Hidden: boolean?,
	IntrinsicSize: Vector2?,
	SourceOrder: number?,
	PreviousSiblings: { Node }?,
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
export type ProviderProperties = {
	StyleSheet: StyleSheet?,
	CSS: StyleMap?,
	Children: React.ReactNode?,
	OnDiagnostics: (({ Diagnostic }) -> ())?,
	ViewportWidth: number?,
}

return {}
