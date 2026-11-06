--!strict
-- Packages
-- Modules
local CSS = require(script.Parent.CSS)
local Entities = require(script.Entities)
local Types = require(script.Parent.Types)
local tagName = require(script.Tags)
-- Types
type OpenElement = { Name: string, Node: Types.ContentElement, Offset: number }
-- Constants
local MAX_BYTES = 1024 * 1024
local MAX_DEPTH = 64
local MAX_NODES = 10000
-- References
-- Global Variables
-- Private Functions
local function diagnostic(source: string, offset: number, message: string, path: string?): Types.MarkupDiagnostic
	local prefix = source:sub(1, offset - 1)
	local _, lines = prefix:gsub("\n", "")
	local lastLine = prefix:match(".*\n()") or 1
	return {
		Message = message,
		Source = source:sub(offset, offset + 79),
		Path = path,
		Location = { Offset = offset, Line = lines + 1, Column = offset - lastLine + 1 },
	}
end
-- Class
local Markup = {}
function Markup.parse(source: string): Types.MarkupResult
	local result: Types.MarkupResult = { Success = false, Nodes = {}, Diagnostics = {} }
	local stack: { OpenElement } = {}
	local position, count = 1, 0
	local function reject(message: string, offset: number)
		table.insert(result.Diagnostics, diagnostic(source, offset, message, nil))
	end
	if #source > MAX_BYTES then
		reject(`Markup exceeds {MAX_BYTES} bytes`, 1)
		return result
	end
	local invalid, issue = Entities.validate(source)
	if invalid then
		reject(issue or "Invalid source", invalid)
		return result
	end
	local function siblings(): { Types.ContentNode }
		return if #stack == 0 then result.Nodes else assert(stack[#stack].Node.Children)
	end
	local function append(node: Types.ContentNode)
		if #stack > 0 and stack[#stack].Node.Tag == "Br" and node ~= "" then
			reject("Br cannot contain content", position)
			return
		end
		local nodes = siblings()
		local previous = nodes[#nodes]
		if type(node) == "string" and type(previous) == "string" then
			nodes[#nodes] = previous .. node
			return
		end
		if node == "" then
			return
		end
		count += 1
		if count > MAX_NODES then
			reject(`Markup exceeds {MAX_NODES} nodes`, position)
			return
		end
		table.insert(nodes, node)
	end
	local function decode(value: string, offset: number): string?
		local decoded, at, problem = Entities.decode(value)
		if not decoded then
			reject(problem or "Invalid character reference", offset + (at or 1) - 1)
		end
		return decoded
	end
	local function whitespace(): boolean
		local start = position
		while source:sub(position, position):match("[ \t\r\n]") do
			position += 1
		end
		return position > start
	end
	local function name(): string?
		local value = source:match("^[%a_][%w_.:%-]*", position)
		if value then
			position += #value
		end
		return value
	end
	while position <= #source and #result.Diagnostics == 0 do
		local opening = position
		if source:sub(position, position) ~= "<" then
			local ending = source:find("<", position, true) or (#source + 1)
			local raw = source:sub(position, ending - 1)
			if raw:find("]]>", 1, true) then
				reject("]]> is only valid as a CDATA terminator", position)
				break
			end
			local value = decode(raw, position)
			if value then
				append(value)
			end
			position = ending
		elseif source:sub(position, position + 3) == "<!--" then
			local ending = source:find("-->", position + 4, true)
			if not ending then
				reject("Unclosed comment", opening)
				break
			end
			local body = source:sub(position + 4, ending - 1)
			if body:find("--", 1, true) or body:sub(-1) == "-" then
				reject("A comment cannot contain --", opening)
				break
			end
			position = ending + 3
		elseif source:sub(position, position + 8) == "<![CDATA[" then
			local ending = source:find("]]>", position + 9, true)
			if not ending then
				reject("Unclosed CDATA section", opening)
				break
			end
			append(source:sub(position + 9, ending - 1))
			position = ending + 3
		elseif source:sub(position, position + 1) == "</" then
			position += 2
			local closing = name()
			whitespace()
			if not closing or source:sub(position, position) ~= ">" then
				reject("Expected a closing tag", opening)
				break
			end
			local parent = stack[#stack]
			if not parent or parent.Name ~= closing then
				reject(`Unexpected closing tag </{closing}>`, opening)
				break
			end
			table.remove(stack)
			position += 1
		elseif source:sub(position, position + 1) == "<!" or source:sub(position, position + 1) == "<?" then
			reject("Declarations and processing instructions are outside the markup fragment format", opening)
		else
			position += 1
			local rawName = name()
			local tag: Types.ContentTag? = if rawName then tagName(rawName) else nil
			if not tag or not rawName then
				reject(`Unsupported markup tag: {rawName or "(missing name)"}`, opening)
				break
			end
			local element: Types.ContentElement = { Tag = tag, Children = {} }
			local seen: { [string]: boolean } = {}
			while true do
				local separated = whitespace()
				local char = source:sub(position, position)
				if char == ">" or char == "/" then
					break
				end
				local start = position
				local attribute = if separated then name() else nil
				if not attribute then
					reject("Expected a quoted attribute or the end of the tag", start)
					break
				end
				if seen[attribute] then
					reject(`Duplicate attribute: {attribute}`, start)
					break
				end
				seen[attribute] = true
				whitespace()
				if source:sub(position, position) ~= "=" then
					reject("Attributes require = and a quoted value", position)
					break
				end
				position += 1
				whitespace()
				local quote = source:sub(position, position)
				if quote ~= '"' and quote ~= "'" then
					reject("Attribute values must be quoted", position)
					break
				end
				position += 1
				local valueStart = position
				local ending = source:find(quote, position, true)
				if not ending then
					reject("Unclosed attribute value", valueStart)
					break
				end
				local raw = source:sub(position, ending - 1)
				if raw:find("<", 1, true) then
					reject("Escape < in attribute values as &lt;", valueStart)
					break
				end
				local value = decode(raw, valueStart)
				if not value then
					break
				end
				if attribute == "id" then
					element.Id = value
				elseif attribute == "class" then
					element.ClassName = value
				elseif attribute == "style" then
					local declarations = CSS.declarations(value)
					for _, error in declarations.Diagnostics do
						reject(error.Message, valueStart)
					end
					if next(declarations.Important) then
						reject("Inline !important is not supported by markup; use StyleProvider.StyleSheet", valueStart)
					end
					element.CSS = declarations.Style
				else
					reject(`Unsupported attribute: {attribute}`, start)
				end
				position = ending + 1
			end
			if #result.Diagnostics > 0 then
				break
			end
			local selfClosing = source:sub(position, position + 1) == "/>"
			if not selfClosing and source:sub(position, position) ~= ">" then
				reject("Expected > or />", position)
				break
			end
			if #stack >= MAX_DEPTH then
				reject(`Markup exceeds {MAX_DEPTH} nested elements`, opening)
				break
			end
			position += if selfClosing then 2 else 1
			append(element)
			if not selfClosing then
				table.insert(stack, { Name = rawName, Node = element, Offset = opening })
			end
		end
	end
	if #result.Diagnostics == 0 and #stack > 0 then
		local unclosed = stack[#stack]
		reject(`Unclosed <{unclosed.Name}> tag`, unclosed.Offset)
	end
	-- Failed input never mounts a partially parsed tree.
	result.Success = #result.Diagnostics == 0
	if not result.Success then
		result.Nodes = {}
	end
	return result
end

function Markup.validate(source: unknown): Types.MarkupResult
	local result: Types.MarkupResult = { Success = false, Nodes = {}, Diagnostics = {} }
	local active: { [unknown]: boolean } = {}
	local count = 0
	local bytes = 0
	local function reject(message: string, path: string)
		table.insert(result.Diagnostics, diagnostic("", 1, message, path))
	end
	local function validText(value: string, path: string): boolean
		bytes += #value
		local _, problem = Entities.validate(value)
		if bytes > MAX_BYTES or problem then
			reject(problem or `Content text exceeds {MAX_BYTES} bytes`, path)
			return false
		end
		return true
	end
	local function array(value: unknown, path: string): { unknown }?
		if type(value) ~= "table" then
			reject("Expected an ordered node array", path)
			return nil
		end
		local record = value :: { [unknown]: unknown }
		local length, maximum = 0, 0
		for key in record do
			if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
				reject("Node arrays require contiguous integer keys", path)
				return nil
			end
			length += 1
			maximum = math.max(maximum, key)
		end
		if length ~= maximum then
			reject("Node arrays cannot contain holes", path)
			return nil
		end
		return (value :: unknown) :: { unknown }
	end
	local function visit(value: unknown, path: string, depth: number): Types.ContentNode?
		count += 1
		if count > MAX_NODES then
			reject("Content exceeds the node or nesting limit", path)
			return nil
		end
		if type(value) == "string" then
			return if validText(value, path) then value else nil
		end
		if type(value) ~= "table" then
			reject("Expected text or a ContentElement", path)
			return nil
		end
		if depth > MAX_DEPTH then
			reject("Content exceeds the nesting limit", path)
			return nil
		end
		if active[value] then
			reject("Cyclic content tree", path)
			return nil
		end
		local input = value :: { [string]: unknown }
		local tag: Types.ContentTag? = if type(input.Tag) == "string" then tagName(input.Tag) else nil
		if not tag or tag ~= input.Tag then
			reject("Unsupported Tag; table tags must use PascalCase", path .. ".Tag")
			return nil
		end
		local output: Types.ContentElement = { Tag = tag, Children = {} }
		for key in input do
			if
				key ~= "Tag"
				and key ~= "Id"
				and key ~= "ClassName"
				and key ~= "CSS"
				and key ~= "Text"
				and key ~= "Children"
				and key ~= "Ref"
			then
				reject(`Unsupported element field: {tostring(key)}`, path)
			end
		end
		for _, key in { "Id", "ClassName", "Text" } do
			local field = input[key]
			if field ~= nil and type(field) ~= "string" then
				reject(`{key} must be a string`, path .. "." .. key)
			elseif type(field) == "string" then
				validText(field, path .. "." .. key)
				if key == "Id" then
					output.Id = field
				elseif key == "ClassName" then
					output.ClassName = field
				else
					output.Text = field
				end
			end
		end
		if input.CSS ~= nil then
			local css = CSS.validate(input.CSS)
			output.CSS = css.Style
			for _, problem in css.Diagnostics do
				reject(problem.Message, path .. ".CSS." .. problem.Source)
			end
		end
		local ref = input.Ref
		if type(ref) == "function" then
			output.Ref = ref :: (GuiObject?) -> ()
		elseif type(ref) == "table" then
			local current = (ref :: { [string]: unknown }).current
			if current == nil or (typeof(current) == "Instance" and current:IsA("GuiObject")) then
				output.Ref = (ref :: unknown) :: { current: GuiObject? }
			else
				reject("Ref.current must be a GuiObject or nil", path .. ".Ref")
			end
		elseif ref ~= nil then
			reject("Ref must be a callback or React ref object", path .. ".Ref")
		end
		active[value] = true
		if input.Children ~= nil then
			local children = array(input.Children, path .. ".Children")
			if children then
				for index, child in children do
					local node = visit(child, `{path}.Children[{index}]`, depth + 1)
					if node then
						table.insert(assert(output.Children), node)
					end
					if #result.Diagnostics > 0 then
						break
					end
				end
			end
		end
		active[value] = nil
		if tag == "Br" and ((output.Text and output.Text ~= "") or #assert(output.Children) > 0) then
			reject("Br cannot contain content", path)
		end
		return output
	end
	local nodes = array(source, "Nodes")
	if nodes then
		for index, node in nodes do
			local checked = visit(node, `Nodes[{index}]`, 1)
			if checked then
				table.insert(result.Nodes, checked)
			end
			if #result.Diagnostics > 0 then
				break
			end
		end
	end
	result.Success = #result.Diagnostics == 0
	if not result.Success then
		result.Nodes = {}
	end
	return result
end
return Markup
