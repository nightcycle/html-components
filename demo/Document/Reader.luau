--!strict
-- Packages
local storage = script.Parent.Parent
local HTML = require(storage.Packages.HTMLComponents)
local React = require(storage.Packages.React)
-- Modules
local Samples = require(script.Parent.Samples)
-- Components
local Asset = require(script.Parent.Asset)
-- Contexts
-- Hooks
-- Types
export type Report = {
	Document: HTML.DocumentResult,
	StyleSheet: HTML.StyleSheet,
	Elements: number,
	Attributes: number,
	TextNodes: number,
	Stylesheets: number,
	Issues: { string },
	Tree: string,
	Preview: React.ReactNode,
}
-- Constants
local e = React.createElement
local components = (HTML.Tags :: unknown) :: { [string]: React.ElementType }
local kinds: { [string]: HTML.RenderKind } = {}
for _, entry in HTML.Catalog do
	kinds[entry.Tag] = entry.Kind
end
local METADATA: { [string]: boolean } =
	{ Head = true, Script = true, Style = true, Link = true, Meta = true, Title = true, Base = true }
-- References
-- Global Variables
-- Private Functions
local function textContent(nodes: { HTML.DocumentNode }): string
	local parts: { string } = {}
	for _, node in nodes do
		if node.Kind == "Text" then
			table.insert(parts, node.Text)
		elseif node.Kind == "Element" and not METADATA[node.Tag] then
			table.insert(parts, textContent(node.Children))
		end
	end
	return table.concat(parts)
end
-- Class
return function(sample: Samples.Sample, viewportWidth: number?): Report
	local document = HTML.Document.parse(sample.HTML)
	local issues: { string } = {}
	local tree: { string } = {}
	local sheet = HTML.CSS.parse([[html,body {color:black; font-size:16px; font-weight:normal; line-height:normal}
a {display:inline; height:auto; color:blue; text-decoration:underline}
button {display:inline-block; height:auto; background-color:transparent; color:black; border-radius:0px; padding:2px 6px}
img {display:inline-block; height:auto}
blockquote {padding:0; background-color:transparent; font-style:normal}
]])
	local elements, attributes, texts, loaded = 0, 0, 0, 0
	local function inspect(nodes: { HTML.DocumentNode }, depth: number)
		for _, node in nodes do
			local line = node.Kind
			if node.Kind == "Element" then
				elements += 1
				attributes += #node.Attributes
				line = `<{node.SourceName}> [{node.Namespace}]`
				local id = HTML.Document.attribute(node, "id")
				local className = HTML.Document.attribute(node, "class")
				if id then
					line ..= ` #{id}`
				end
				if className then
					line ..= ` .{className}`
				end
			elseif node.Kind == "Text" then
				texts += 1
				line = `Text {string.format("%q", node.Text):sub(1, 110)}`
			elseif node.Kind == "Doctype" then
				line = `<!doctype {node.Name}>`
			end
			if #tree < 600 then
				table.insert(tree, string.rep("  ", math.min(depth, 16)) .. line)
			end
			if node.Kind == "Element" then
				inspect(node.Children, depth + 1)
			end
		end
	end
	inspect(document.Children, 0)
	if #tree == 600 then
		table.insert(tree, "… tree display limited to 600 rows; counts cover the entire document.")
	end
	for _, problem in document.Diagnostics do
		table.insert(issues, `HTML {problem.Location.Line}:{problem.Location.Column}: {problem.Message}`)
	end
	for _, resource in HTML.Document.stylesheets(document) do
		local source = resource.Text or (if resource.Href then sample.Stylesheets[resource.Href] else nil)
		if resource.Media and resource.Media ~= "" and resource.Media ~= "all" then
			table.insert(issues, `CSS: media condition is not evaluated: {resource.Media}`)
		elseif source then
			loaded += 1
			local parsed = HTML.CSS.parse(source)
			for _, rule in parsed.Rules do
				table.insert(sheet.Rules, rule)
			end
			for _, problem in parsed.Diagnostics do
				table.insert(sheet.Diagnostics, problem)
				table.insert(issues, `CSS: {problem.Message} — {problem.Source}`)
			end
		else
			table.insert(issues, `CSS: stylesheet was not supplied: {resource.Href or "inline style"}`)
		end
	end
	local function render(nodes: { HTML.DocumentNode }, parentPath: string): { [string]: React.ReactNode }
		local children: { [string]: React.ReactNode } = {}
		local previous: { HTML.Node } = {}
		for index, node in nodes do
			local key = tostring(index)
			local path = if parentPath == "" then key else parentPath .. "." .. key
			if node.Kind == "Text" then
				local content: { HTML.ContentNode } = { node.Text }
				children[key] = e(HTML.Content, { Source = content, OrderOffset = index - 1 } :: HTML.ContentProperties)
			elseif node.Kind == "Element" and not METADATA[node.Tag] then
				local style: HTML.Style? = nil
				local declaration = HTML.Document.attribute(node, "style")
				if declaration then
					local parsed = HTML.CSS.declarations(declaration)
					style = parsed.Style
					for _, problem in parsed.Diagnostics do
						table.insert(issues, `Inline CSS: {problem.Message}`)
					end
					if next(parsed.Important) then
						table.insert(issues, "Preview: inline !important is not applied")
					end
				end
				local id = HTML.Document.attribute(node, "id")
				local className = HTML.Document.attribute(node, "class")
				local hidden = HTML.Document.attribute(node, "hidden") ~= nil
				local kind = kinds[node.Tag]
				local component = components[node.Tag]
				local name = id or "HTML_" .. path
				local siblings = table.clone(previous)
				local classes: { string } = {}
				for token in (className or ""):gmatch("%S+") do
					table.insert(classes, token)
				end
				table.insert(previous, {
					Tag = (if component then node.Tag else "Div") :: HTML.Tag,
					Id = id,
					Classes = classes,
					Hidden = hidden,
					PreviousSiblings = siblings,
				})
				if node.Namespace ~= "HTML" or kind == "Image" or kind == "Video" then
					local asset = if sample.Assets then sample.Assets[path] else nil
					if asset then
						local properties: HTML.ImgProperties = {
							Name = name,
							Id = id,
							ClassName = className,
							CSS = style,
							Hidden = hidden,
							SourceOrder = index,
							PreviousSiblings = siblings,
						}
						children[key] = e(Asset, { Asset = asset, Properties = properties })
						continue
					end
					table.insert(issues, `Preview: <{node.SourceName}> needs a Roblox asset/graphics mapping`)
					if kind == "Image" then
						local properties: HTML.ImgProperties = {
							Name = name,
							Id = id,
							ClassName = className,
							CSS = style,
							Hidden = hidden,
							SourceOrder = index,
							PreviousSiblings = siblings,
							IntrinsicSize = Vector2.new(24, 24),
						}
						children[key] = e(HTML.Img, properties)
						continue
					end
					children[key] = e(
						HTML.P,
						{
							Name = name,
							Text = `[{node.SourceName}: {HTML.Document.attribute(node, "alt") or "graphics placeholder"}]`,
							SourceOrder = index,
							PreviousSiblings = siblings,
							Hidden = hidden,
							CSS = { Color = "#667085", FontSize = 13 },
						} :: HTML.PProperties
					)
				elseif kind == "Text" then
					children[key] = e(
						component,
						{
							Name = name,
							Id = id,
							ClassName = className,
							CSS = style,
							Hidden = hidden,
							SourceOrder = index,
							PreviousSiblings = siblings,
							Text = "",
						} :: HTML.TextProperties,
						render(node.Children, path)
					)
				elseif kind == "Button" then
					children[key] = e(
						component,
						{
							Id = id,
							Name = name,
							ClassName = className,
							CSS = style,
							Hidden = hidden,
							SourceOrder = index,
							PreviousSiblings = siblings,
							Text = "",
							Disabled = HTML.Document.attribute(node, "disabled") ~= nil,
						} :: HTML.ButtonProperties,
						render(node.Children, path)
					)
				elseif kind == "Input" then
					children[key] = e(
						component,
						{
							Id = id,
							ClassName = className,
							CSS = style,
							Hidden = hidden,
							SourceOrder = index,
							PreviousSiblings = siblings,
							DefaultValue = HTML.Document.attribute(node, "value") or textContent(node.Children),
							Name = name,
							Placeholder = HTML.Document.attribute(node, "placeholder"),
							Disabled = HTML.Document.attribute(node, "disabled") ~= nil,
						} :: HTML.InputProperties
					)
				elseif kind == "Meter" then
					children[key] = e(
						component,
						{
							Id = id,
							ClassName = className,
							CSS = style,
							Hidden = hidden,
							SourceOrder = index,
							PreviousSiblings = siblings,
							Value = tonumber(HTML.Document.attribute(node, "value") or "0"),
							Name = name,
							Max = tonumber(HTML.Document.attribute(node, "max") or "1"),
						} :: HTML.MeterProperties
					)
				else
					if not component then
						table.insert(issues, `Preview: <{node.SourceName}> uses a generic container`)
					end
					children[key] = e(
						component or HTML.Div,
						{
							Id = id,
							Name = name,
							ClassName = className,
							CSS = style,
							Hidden = hidden,
							SourceOrder = index,
							PreviousSiblings = siblings,
						} :: HTML.ContainerProperties,
						render(node.Children, path)
					)
				end
			end
		end
		return children
	end
	local preview = if document.Success
		then e(HTML.StyleProvider, {
			StyleSheet = sheet,
			ViewportWidth = viewportWidth,
			OnDiagnostics = function(_diagnostics: { HTML.Diagnostic })
				-- Retained in this report's Issues and StyleSheet for the Diagnostics tab.
			end,
		}, render(document.Children, ""))
		else nil
	return {
		Document = document,
		StyleSheet = sheet,
		Elements = elements,
		Attributes = attributes,
		TextNodes = texts,
		Stylesheets = loaded,
		Issues = issues,
		Tree = table.concat(tree, "\n"),
		Preview = preview,
	}
end
