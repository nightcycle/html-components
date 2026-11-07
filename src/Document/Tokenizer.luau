--!strict
-- Packages
-- Modules
local Names = require(script.Parent.Names)
local Source = require(script.Parent.SourceText)
local Types = require(script.Parent.Parent.Types)
local decode = require(script.Parent.Entities)
-- Types
export type Token = {
	Kind: Types.DocumentNodeKind,
	Name: string,
	Text: string,
	Attributes: { Types.DocumentAttribute },
	Closing: boolean,
	SelfClosing: boolean,
	Start: number,
	Finish: number,
}
export type Tokenizer = { Next: (boolean) -> Token?, Raw: (string) -> () }
-- Constants
local REPLACEMENT = utf8.char(0xFFFD)
-- References
-- Global Variables
-- Private Functions
local function whitespace(value: string): boolean
	return value:match("^[ \t\r\n\f]$") ~= nil
end
local function normalize(value: string): string
	return (value:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("%z", REPLACEMENT))
end
-- Class
return function(source: Source.Source): Tokenizer
	local text, position, raw = source.Text, 1, ""
	local lower = string.lower(text)
	local function make(kind: Types.DocumentNodeKind, start: number, value: string): Token
		return {
			Kind = kind,
			Name = "",
			Text = value,
			Attributes = {},
			Closing = false,
			SelfClosing = false,
			Start = start,
			Finish = position,
		}
	end
	local function warn(message: string, offset: number)
		source.Report("Warning", "Syntax", message, offset)
	end
	local function spaces()
		while whitespace(text:sub(position, position)) do
			position += 1
		end
	end
	local function nextToken(foreign: boolean): Token?
		if position > #text then
			return nil
		end
		local start = position
		if raw ~= "" then
			local ending = position
			if raw == "plaintext" then
				ending = #text + 1
			else
				while true do
					local found = lower:find("</" .. raw, ending, true)
					if not found then
						ending = #text + 1
						break
					end
					local after = text:sub(found + #raw + 2, found + #raw + 2)
					if after == ">" or after == "/" or whitespace(after) then
						ending = found
						break
					end
					ending = found + 2
				end
			end
			local mode = raw
			raw = ""
			if ending > position then
				local value = normalize(text:sub(position, ending - 1))
				position = ending
				if mode == "script" and value:find("<!--", 1, true) then
					source.Report("Error", "Unsupported", "Escaped script-data states are not implemented", start)
				end
				return make(
					"Text",
					start,
					if mode == "title" or mode == "textarea" then decode(value, false) else value
				)
			end
		end
		if text:sub(position, position) ~= "<" then
			position = text:find("<", position, true) or (#text + 1)
			return make("Text", start, decode(normalize(text:sub(start, position - 1)), false))
		end
		if text:sub(position, position + 3) == "<!--" then
			local bodyStart = position + 4
			local closing = text:find("-->", bodyStart, true)
			local alternate = text:find("--!>", bodyStart, true)
			if alternate and (not closing or alternate < closing) then
				position = alternate + 4
				warn("Incorrectly closed comment", start)
				return make("Comment", start, normalize(text:sub(bodyStart, alternate - 1)))
			end
			if text:sub(bodyStart, bodyStart) == ">" then
				position = bodyStart + 1
				warn("Abruptly closed comment", start)
				return make("Comment", start, "")
			end
			position = if closing then closing + 3 else #text + 1
			if not closing then
				warn("Unclosed comment", start)
			end
			return make("Comment", start, normalize(text:sub(bodyStart, (closing or (#text + 1)) - 1)))
		end
		if foreign and text:sub(position, position + 8) == "<![CDATA[" then
			local closing = text:find("]]>", position + 9, true)
			position = if closing then closing + 3 else #text + 1
			return make("Text", start, normalize(text:sub(start + 9, (closing or (#text + 1)) - 1)))
		end
		if lower:sub(position, position + 8) == "<!doctype" then
			position += 9
			spaces()
			local nameStart = position
			while
				position <= #text
				and not whitespace(text:sub(position, position))
				and text:sub(position, position) ~= ">"
			do
				position += 1
			end
			local name = lower:sub(nameStart, position - 1)
			spaces()
			if text:sub(position, position) ~= ">" then
				source.Report("Error", "Unsupported", "Legacy or incomplete doctypes are not implemented", start)
			end
			local quote = ""
			while position <= #text do
				local character = text:sub(position, position)
				position += 1
				if quote ~= "" then
					if character == quote then
						quote = ""
					end
				elseif character == '"' or character == "'" then
					quote = character
				elseif character == ">" then
					break
				end
			end
			local token = make("Doctype", start, "")
			token.Name = name
			return token
		end
		if text:sub(position + 1, position + 1) == "!" or text:sub(position + 1, position + 1) == "?" then
			if text:sub(position + 1, position + 1) == "?" then
				source.Report("Error", "Unsupported", "Processing instructions are not implemented", start)
			end
			local bodyStart = position + (if text:sub(position + 1, position + 1) == "!" then 2 else 1)
			local closing = text:find(">", bodyStart, true)
			position = if closing then closing + 1 else #text + 1
			warn("Unrecognized declaration treated as a comment", start)
			return make("Comment", start, normalize(text:sub(bodyStart, (closing or (#text + 1)) - 1)))
		end
		local closing = text:sub(position + 1, position + 1) == "/"
		local nameStart = position + (if closing then 2 else 1)
		if not text:sub(nameStart, nameStart):match("[a-zA-Z]") then
			position += 1
			return make("Text", start, "<")
		end
		position = nameStart
		while position <= #text and not text:sub(position, position):match("[ \t\r\n\f/>]") do
			position += 1
		end
		local token = make("Element", start, "")
		token.Name, token.Closing = normalize(lower:sub(nameStart, position - 1)), closing
		local seen: { [string]: boolean } = {}
		while position <= #text do
			spaces()
			local character = text:sub(position, position)
			if character == ">" then
				position += 1
				token.Finish = position
				return token
			end
			if text:sub(position, position + 1) == "/>" then
				position += 2
				token.SelfClosing = true
				token.Finish = position
				return token
			end
			if character == "/" then
				position += 1
				warn("Unexpected / in attributes", position - 1)
				continue
			end
			local attributeStart = position
			while position <= #text and not text:sub(position, position):match("[ \t\r\n\f/=>]") do
				position += 1
			end
			if position == attributeStart then
				position += 1
				warn("Invalid attribute name", attributeStart)
				continue
			end
			local name = normalize(lower:sub(attributeStart, position - 1))
			spaces()
			local value = ""
			if text:sub(position, position) == "=" then
				position += 1
				spaces()
				local quote = text:sub(position, position)
				if quote == '"' or quote == "'" then
					position += 1
					local ending = text:find(quote, position, true)
					if not ending then
						warn("Unclosed attribute value", attributeStart)
						position = #text + 1
						return nil
					end
					value = text:sub(position, ending - 1)
					position = ending + 1
				else
					local valueStart = position
					while position <= #text and not text:sub(position, position):match("[ \t\r\n\f>]") do
						position += 1
					end
					value = text:sub(valueStart, position - 1)
				end
			end
			if seen[name] then
				warn("Duplicate attribute ignored: " .. name, attributeStart)
			else
				seen[name] = true
				table.insert(token.Attributes, {
					Name = Names.Pascal(name),
					SourceName = name,
					Value = decode(normalize(value), true),
					Location = source.Locate(attributeStart),
				})
			end
		end
		warn("Unclosed tag discarded at end of input", start)
		return nil
	end
	return {
		Next = nextToken,
		Raw = function(name)
			raw = name
		end,
	}
end
