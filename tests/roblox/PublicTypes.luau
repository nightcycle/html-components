--!strict
local HTML = require(game.ReplicatedStorage.Packages.HTMLComponents)
return function()
	local HtmlProperties: HTML.HtmlProperties = {}
	HTML.Html(HtmlProperties)
	local BodyProperties: HTML.BodyProperties = {}
	HTML.Body(BodyProperties)
	local DivProperties: HTML.DivProperties = {}
	HTML.Div(DivProperties)
	local MainProperties: HTML.MainProperties = {}
	HTML.Main(MainProperties)
	local SectionProperties: HTML.SectionProperties = {}
	HTML.Section(SectionProperties)
	local ArticleProperties: HTML.ArticleProperties = {}
	HTML.Article(ArticleProperties)
	local AsideProperties: HTML.AsideProperties = {}
	HTML.Aside(AsideProperties)
	local HeaderProperties: HTML.HeaderProperties = {}
	HTML.Header(HeaderProperties)
	local FooterProperties: HTML.FooterProperties = {}
	HTML.Footer(FooterProperties)
	local NavProperties: HTML.NavProperties = {}
	HTML.Nav(NavProperties)
	local FormProperties: HTML.FormProperties = {}
	HTML.Form(FormProperties)
	local FigureProperties: HTML.FigureProperties = {}
	HTML.Figure(FigureProperties)
	local UlProperties: HTML.UlProperties = {}
	HTML.Ul(UlProperties)
	local OlProperties: HTML.OlProperties = {}
	HTML.Ol(OlProperties)
	local LiProperties: HTML.LiProperties = {}
	HTML.Li(LiProperties)
	local DlProperties: HTML.DlProperties = {}
	HTML.Dl(DlProperties)
	local DtProperties: HTML.DtProperties = {}
	HTML.Dt(DtProperties)
	local DdProperties: HTML.DdProperties = {}
	HTML.Dd(DdProperties)
	local FieldsetProperties: HTML.FieldsetProperties = {}
	HTML.Fieldset(FieldsetProperties)
	local PProperties: HTML.PProperties = {}
	HTML.P(PProperties)
	local SpanProperties: HTML.SpanProperties = {}
	HTML.Span(SpanProperties)
	local LabelProperties: HTML.LabelProperties = {}
	HTML.Label(LabelProperties)
	local LegendProperties: HTML.LegendProperties = {}
	HTML.Legend(LegendProperties)
	local FigcaptionProperties: HTML.FigcaptionProperties = {}
	HTML.Figcaption(FigcaptionProperties)
	local AbbrProperties: HTML.AbbrProperties = {}
	HTML.Abbr(AbbrProperties)
	local TimeProperties: HTML.TimeProperties = {}
	HTML.Time(TimeProperties)
	local OutputProperties: HTML.OutputProperties = {}
	HTML.Output(OutputProperties)
	local H1Properties: HTML.H1Properties = {}
	HTML.H1(H1Properties)
	local H2Properties: HTML.H2Properties = {}
	HTML.H2(H2Properties)
	local H3Properties: HTML.H3Properties = {}
	HTML.H3(H3Properties)
	local H4Properties: HTML.H4Properties = {}
	HTML.H4(H4Properties)
	local H5Properties: HTML.H5Properties = {}
	HTML.H5(H5Properties)
	local H6Properties: HTML.H6Properties = {}
	HTML.H6(H6Properties)
	local BProperties: HTML.BProperties = {}
	HTML.B(BProperties)
	local StrongProperties: HTML.StrongProperties = {}
	HTML.Strong(StrongProperties)
	local IProperties: HTML.IProperties = {}
	HTML.I(IProperties)
	local EmProperties: HTML.EmProperties = {}
	HTML.Em(EmProperties)
	local CiteProperties: HTML.CiteProperties = {}
	HTML.Cite(CiteProperties)
	local VarProperties: HTML.VarProperties = {}
	HTML.Var(VarProperties)
	local AddressProperties: HTML.AddressProperties = {}
	HTML.Address(AddressProperties)
	local SProperties: HTML.SProperties = {}
	HTML.S(SProperties)
	local DelProperties: HTML.DelProperties = {}
	HTML.Del(DelProperties)
	local UProperties: HTML.UProperties = {}
	HTML.U(UProperties)
	local InsProperties: HTML.InsProperties = {}
	HTML.Ins(InsProperties)
	local CodeProperties: HTML.CodeProperties = {}
	HTML.Code(CodeProperties)
	local KbdProperties: HTML.KbdProperties = {}
	HTML.Kbd(KbdProperties)
	local SampProperties: HTML.SampProperties = {}
	HTML.Samp(SampProperties)
	local PreProperties: HTML.PreProperties = {}
	HTML.Pre(PreProperties)
	local SmallProperties: HTML.SmallProperties = {}
	HTML.Small(SmallProperties)
	local MarkProperties: HTML.MarkProperties = {}
	HTML.Mark(MarkProperties)
	local BlockquoteProperties: HTML.BlockquoteProperties = {}
	HTML.Blockquote(BlockquoteProperties)
	local QProperties: HTML.QProperties = {}
	HTML.Q(QProperties)
	local AProperties: HTML.AProperties = {}
	HTML.A(AProperties)
	local ButtonProperties: HTML.ButtonProperties = {}
	HTML.Button(ButtonProperties)
	local InputProperties: HTML.InputProperties = {}
	HTML.Input(InputProperties)
	local TextareaProperties: HTML.TextareaProperties = {}
	HTML.Textarea(TextareaProperties)
	local ImgProperties: HTML.ImgProperties = {}
	HTML.Img(ImgProperties)
	local VideoProperties: HTML.VideoProperties = {}
	HTML.Video(VideoProperties)
	local ProgressProperties: HTML.ProgressProperties = {}
	HTML.Progress(ProgressProperties)
	local MeterProperties: HTML.MeterProperties = {}
	HTML.Meter(MeterProperties)
	local HrProperties: HTML.HrProperties = {}
	HTML.Hr(HrProperties)
	local BrProperties: HTML.BrProperties = {}
	HTML.Br(BrProperties)
	local css: HTML.StyleMap =
		{ [".Primary"] = { FontSize = 16, FontWeight = "Bold" }, ["Button:Hover"] = { BackgroundColor = "#315fe8" } }
	local properties: HTML.StyleProviderProperties = { CSS = css }
	HTML.StyleProvider(properties)
end
