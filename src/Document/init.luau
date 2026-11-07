--!strict
-- Packages
-- Modules
local Names = require(script.Names)
local Types = require(script.Parent.Types)
local newSource = require(script.SourceText)
local tokenize = require(script.Tokenizer)
-- Types
type Element = Types.DocumentElement
type Node = Types.DocumentNode
-- Constants
local MAX_BYTES, MAX_NODES, MAX_DEPTH = 1024 * 1024, 20000, 128
local VOID: { [string]: boolean } = {
	area = true,
	base = true,
	br = true,
	col = true,
	embed = true,
	hr = true,
	img = true,
	input = true,
	link = true,
	meta = true,
	param = true,
	source = true,
	track = true,
	wbr = true,
}
local HEAD: { [string]: boolean } = {
	base = true,
	basefont = true,
	bgsound = true,
	link = true,
	meta = true,
	title = true,
	noscript = true,
	noframes = true,
	style = true,
	script = true,
	template = true,
}
local RAW: { [string]: boolean } = {
	title = true,
	textarea = true,
	style = true,
	script = true,
	xmp = true,
	iframe = true,
	noembed = true,
	noframes = true,
	plaintext = true,
}
local BLOCK: { [string]: boolean } = {
	address = true,
	article = true,
	aside = true,
	blockquote = true,
	details = true,
	div = true,
	dl = true,
	fieldset = true,
	figcaption = true,
	figure = true,
	footer = true,
	form = true,
	h1 = true,
	h2 = true,
	h3 = true,
	h4 = true,
	h5 = true,
	h6 = true,
	header = true,
	hgroup = true,
	hr = true,
	main = true,
	menu = true,
	nav = true,
	ol = true,
	p = true,
	pre = true,
	section = true,
	table = true,
	ul = true,
}
local FORMATTING: { [string]: boolean } = {
	a = true,
	b = true,
	big = true,
	code = true,
	em = true,
	font = true,
	i = true,
	nobr = true,
	s = true,
	small = true,
	strike = true,
	strong = true,
	tt = true,
	u = true,
}
local TABLE_ALLOWED: { [string]: boolean } = {
	caption = true,
	colgroup = true,
	col = true,
	tbody = true,
	thead = true,
	tfoot = true,
	tr = true,
	td = true,
	th = true,
	style = true,
	script = true,
	template = true,
}
-- References
-- Global Variables
-- Private Functions
local function attribute(element: Element, name: string): string?
	for _, value in element.Attributes do
		if value.SourceName:lower() == name:lower() then
			return value.Value
		end
	end
	return nil
end
local function integration(element: Element): boolean
	local name = element.SourceName:lower()
	return (element.Namespace == "SVG" and (name == "foreignobject" or name == "desc" or name == "title"))
		or (
			element.Namespace == "MathML"
			and (
				name == "mi"
				or name == "mo"
				or name == "mn"
				or name == "ms"
				or name == "mtext"
				or (
					name == "annotation-xml"
					and (
						attribute(element, "encoding") == "text/html"
						or attribute(element, "encoding") == "application/xhtml+xml"
					)
				)
			)
		)
end
-- Class
local Document = {}
function Document.parse(text: string): Types.DocumentResult
	local result: Types.DocumentResult = { Success = false, Children = {}, Diagnostics = {} }
	if #text > MAX_BYTES then
		table.insert(result.Diagnostics, {
			Severity = "Error",
			Issue = "Limit",
			Message = "Document exceeds 1 MiB",
			Location = { Offset = 1, Line = 1, Column = 1 },
		})
		return result
	end
	local source = newSource(text, result.Diagnostics)
	local valid, invalid = utf8.len(text)
	if not valid then
		source.Report("Error", "Syntax", "Expected UTF-8 input", invalid or 1)
		return result
	end
	local reader = tokenize(source)
	local stack: { Element } = {}
	local html: Element? = nil
	local head: Element? = nil
	local body: Element? = nil
	-- Before head, in head, after head, in body, after body, after html.
	local stage, count = 0, 0
	local stopped = false
	local formOpen = false
	local stripNewline = false
	local function append(children: { Node }, node: Node)
		local last = children[#children]
		if node.Kind == "Text" and last and last.Kind == "Text" then
			last.Text ..= node.Text
			return
		end
		count += 1
		if count > MAX_NODES then
			source.Report(
				"Error",
				"Limit",
				"Document exceeds 20000 nodes",
				if node.Location then node.Location.Offset else 1
			)
			stopped = true
			return
		end
		table.insert(children, node)
	end
	local function create(
		name: string,
		namespace: Types.DocumentNamespace,
		attributes: { Types.DocumentAttribute },
		offset: number?
	): Element
		local sourceName = if namespace == "SVG" then Names.SVGTag(name) else name
		for _, attr in attributes do
			if namespace == "SVG" then
				attr.SourceName = Names.SVGAttribute(attr.SourceName)
			elseif namespace == "MathML" and attr.SourceName == "definitionurl" then
				attr.SourceName = "definitionURL"
			end
			attr.Name = Names.Pascal(attr.SourceName)
		end
		return {
			Kind = "Element",
			Tag = Names.Pascal(sourceName),
			SourceName = sourceName,
			Namespace = namespace,
			Attributes = attributes,
			Children = {},
			Location = if offset then source.Locate(offset) else nil,
		}
	end
	local function root(): Element
		if not html then
			local element = create("html", "HTML", {}, nil)
			html = element
			append(result.Children, element)
		end
		return assert(html)
	end
	local function ensureHead(): Element
		if not head then
			local element = create("head", "HTML", {}, nil)
			head = element
			append(root().Children, element)
		end
		return assert(head)
	end
	local function ensureBody(): Element
		ensureHead()
		if not body then
			local element = create("body", "HTML", {}, nil)
			body = element
			append(root().Children, element)
		end
		return assert(body)
	end
	local function merge(element: Element, attributes: { Types.DocumentAttribute })
		for _, attr in attributes do
			if attribute(element, attr.SourceName) == nil then
				table.insert(element.Attributes, attr)
			end
		end
	end
	local function find(name: string): number?
		for index = #stack, 1, -1 do
			if stack[index].SourceName:lower() == name then
				return index
			end
		end
		return nil
	end
	local function pop(index: number)
		while #stack >= index do
			table.remove(stack)
		end
	end
	local function closeParagraph()
		for index = #stack, 1, -1 do
			local current = stack[index]
			if current.Namespace ~= "HTML" or current.SourceName == "td" or current.SourceName == "th" then
				break
			end
			if current.SourceName == "p" then
				pop(index)
				break
			end
		end
	end
	local function enterBody()
		stack = { root(), ensureBody() }
		stage = 3
	end
	while not stopped do
		local parent = stack[#stack]
		local foreign = parent ~= nil and parent.Namespace ~= "HTML" and not integration(parent)
		local token = reader.Next(foreign)
		if not token then
			break
		end
		local name = token.Name
		local space = token.Kind == "Text" and token.Text:match("^[ \t\r\n\f]*$") ~= nil
		if token.Kind ~= "Text" then
			stripNewline = false
		end
		if token.Kind == "Doctype" then
			if not html and #result.Children == 0 then
				append(result.Children, { Kind = "Doctype", Name = name, Location = source.Locate(token.Start) })
			elseif not html then
				local exists = false
				for _, node in result.Children do
					if node.Kind == "Doctype" then
						exists = true
					end
				end
				if not exists then
					append(result.Children, { Kind = "Doctype", Name = name, Location = source.Locate(token.Start) })
				end
			else
				source.Report("Warning", "Syntax", "Doctype outside document preamble ignored", token.Start)
			end
			if name ~= "html" then
				source.Report(
					"Error",
					"Unsupported",
					"Only HTML doctypes are supported; quirks layout is not implemented",
					token.Start
				)
			end
			continue
		end
		if token.Kind == "Comment" then
			local children = if not html or stage == 5
				then result.Children
				elseif stage == 4 then root().Children
				elseif parent then parent.Children
				else root().Children
			append(children, { Kind = "Comment", Text = token.Text, Location = source.Locate(token.Start) })
			continue
		end
		if stage == 0 and space then
			continue
		end
		if token.Kind == "Element" and name == "html" and not token.Closing then
			local element = root()
			merge(element, token.Attributes)
			element.Location = source.Locate(token.Start)
			if #stack == 0 then
				stack = { element }
			end
			continue
		end
		if stage == 0 then
			root()
			local element = ensureHead()
			stack = { root(), element }
			stage = 1
			if token.Kind == "Element" and name == "head" and not token.Closing then
				merge(element, token.Attributes)
				element.Location = source.Locate(token.Start)
				continue
			end
		end
		if stage == 1 and #stack == 2 then
			if token.Kind == "Element" and token.Closing and name == "head" then
				stack = { root() }
				stage = 2
				continue
			end
			if not space and not (token.Kind == "Element" and not token.Closing and HEAD[name]) then
				stack = { root() }
				stage = 2
			end
		end
		if stage == 2 then
			if space then
				append(root().Children, { Kind = "Text", Text = token.Text, Location = source.Locate(token.Start) })
				continue
			end
			enterBody()
			if token.Kind == "Element" and name == "body" and not token.Closing then
				local element = ensureBody()
				merge(element, token.Attributes)
				element.Location = source.Locate(token.Start)
				continue
			end
		end
		if stage >= 4 then
			if token.Kind == "Element" and token.Closing and name == "html" then
				stage = 5
				continue
			end
			if not space then
				source.Report("Warning", "Syntax", "Content after body moved into body", token.Start)
			end
			enterBody()
		end
		parent = stack[#stack]
		if not parent then
			enterBody()
			parent = stack[#stack]
		end
		assert(parent)
		foreign = parent.Namespace ~= "HTML" and not integration(parent)
		if token.Kind == "Text" then
			local value = token.Text
			if stripNewline and value:sub(1, 1) == "\n" then
				value = value:sub(2)
			end
			stripNewline = false
			if
				not space
				and (parent.SourceName == "table" or parent.SourceName == "tbody" or parent.SourceName == "tr")
			then
				source.Report("Error", "Unsupported", "Table foster parenting is not implemented", token.Start)
			end
			if value ~= "" then
				append(parent.Children, { Kind = "Text", Text = value, Location = source.Locate(token.Start) })
			end
			continue
		end
		if token.Closing then
			if not foreign and name == "body" then
				stage = 4
				continue
			end
			if not foreign and name == "html" then
				stage = 5
				continue
			end
			local index = find(name)
			if index then
				if FORMATTING[name] and index < #stack then
					source.Report(
						"Error",
						"Unsupported",
						"Misnested formatting requires the HTML adoption-agency algorithm",
						token.Start
					)
				end
				pop(index)
				if name == "form" then
					formOpen = false
				end
			elseif name == "p" and not foreign then
				append(parent.Children, create("p", "HTML", {}, token.Start))
				source.Report(
					"Warning",
					"Syntax",
					"Unmatched paragraph end tag creates an empty paragraph",
					token.Start
				)
			elseif name == "br" and not foreign then
				append(parent.Children, create("br", "HTML", {}, token.Start))
			else
				source.Report("Warning", "Syntax", "Unmatched closing tag ignored: " .. name, token.Start)
			end
			continue
		end
		if not foreign then
			if name == "head" then
				source.Report("Warning", "Syntax", "Repeated head ignored", token.Start)
				continue
			end
			if name == "body" then
				merge(ensureBody(), token.Attributes)
				continue
			end
			if name == "template" or name == "noscript" then
				source.Report(
					"Error",
					"Unsupported",
					"Template/noscript insertion modes are not implemented",
					token.Start
				)
			end
			if name == "form" and formOpen then
				source.Report("Warning", "Syntax", "Nested form ignored", token.Start)
				continue
			end
			if name == "form" then
				formOpen = true
			end
			if BLOCK[name] then
				closeParagraph()
			end
			if name == "li" or name == "dt" or name == "dd" then
				for index = #stack, 1, -1 do
					local previous = stack[index].SourceName
					if
						previous == name or ((name == "dt" or name == "dd") and (previous == "dt" or previous == "dd"))
					then
						pop(index)
						break
					end
					if previous == "ul" or previous == "ol" or previous == "dl" or previous == "body" then
						break
					end
				end
				closeParagraph()
			end
			if name:match("^h[1-6]$") and stack[#stack].SourceName:match("^h[1-6]$") then
				table.remove(stack)
			end
			if name == "option" and stack[#stack].SourceName == "option" then
				table.remove(stack)
			end
			if name == "optgroup" then
				if stack[#stack].SourceName == "option" then
					table.remove(stack)
				end
				if stack[#stack].SourceName == "optgroup" then
					table.remove(stack)
				end
			end
			if name == "a" and find("a") then
				source.Report("Error", "Unsupported", "Nested anchors require formatting reconstruction", token.Start)
			end
			if
				name == "td"
				or name == "th"
				or name == "tr"
				or name == "tbody"
				or name == "thead"
				or name == "tfoot"
			then
				for index = #stack, 1, -1 do
					local previous = stack[index].SourceName
					if previous == "table" then
						break
					end
					local cell = previous == "td" or previous == "th"
					local row = name ~= "td" and name ~= "th" and previous == "tr"
					local section = (name == "tbody" or name == "thead" or name == "tfoot")
						and (previous == "tbody" or previous == "thead" or previous == "tfoot")
					if cell or row or section then
						pop(index)
					end
				end
			end
		end
		parent = stack[#stack] or ensureBody()
		local namespace: Types.DocumentNamespace = if foreign
			then parent.Namespace
			elseif name == "svg" then "SVG"
			elseif name == "math" then "MathML"
			else "HTML"
		if namespace == "HTML" then
			if
				(parent.SourceName == "table" or parent.SourceName == "tbody" or parent.SourceName == "tr")
				and not TABLE_ALLOWED[name]
			then
				source.Report("Error", "Unsupported", "Table foster parenting is not implemented", token.Start)
			end
			if name == "tr" and parent.SourceName == "table" then
				local implicit = create("tbody", "HTML", {}, nil)
				append(parent.Children, implicit)
				table.insert(stack, implicit)
				parent = implicit
			end
			if (name == "td" or name == "th") and (parent.SourceName == "tbody" or parent.SourceName == "table") then
				if parent.SourceName == "table" then
					local section = create("tbody", "HTML", {}, nil)
					append(parent.Children, section)
					table.insert(stack, section)
					parent = section
				end
				local implicit = create("tr", "HTML", {}, nil)
				append(parent.Children, implicit)
				table.insert(stack, implicit)
				parent = implicit
			end
		end
		local element = create(name, namespace, token.Attributes, token.Start)
		append(parent.Children, element)
		if namespace ~= "HTML" and token.SelfClosing then
			continue
		end
		if namespace == "HTML" and VOID[name] then
			continue
		end
		if token.SelfClosing and namespace == "HTML" then
			source.Report("Warning", "Syntax", "Self-closing flag ignored on non-void HTML element", token.Start)
		end
		if #stack >= MAX_DEPTH then
			source.Report("Error", "Limit", "Document exceeds 128 nested elements", token.Start)
			stopped = true
			break
		end
		table.insert(stack, element)
		if namespace == "HTML" then
			if RAW[name] then
				reader.Raw(name)
			end
			stripNewline = name == "pre" or name == "textarea" or name == "listing"
		end
	end
	ensureBody()
	result.Success = not stopped
	for _, problem in result.Diagnostics do
		if problem.Severity == "Error" then
			result.Success = false
		end
	end
	return result
end

function Document.stylesheets(document: Types.DocumentResult): { Types.DocumentStyleSource }
	local styles: { Types.DocumentStyleSource } = {}
	local function visit(nodes: { Node })
		for _, node in nodes do
			if node.Kind ~= "Element" then
				continue
			end
			if node.Namespace == "HTML" then
				local name = node.SourceName
				local media = attribute(node, "media")
				if name == "link" then
					local rel = " " .. (attribute(node, "rel") or ""):lower():gsub("%s+", " ") .. " "
					local href = attribute(node, "href")
					if href and rel:find(" stylesheet ", 1, true) then
						table.insert(styles, { Href = href, Media = media, Location = node.Location })
					end
				elseif name == "style" then
					local pieces: { string } = {}
					for _, child in node.Children do
						if child.Kind == "Text" then
							table.insert(pieces, child.Text)
						end
					end
					table.insert(styles, { Text = table.concat(pieces), Media = media, Location = node.Location })
				end
			end
			visit(node.Children)
		end
	end
	visit(document.Children)
	return styles
end
Document.attribute = attribute
return Document
