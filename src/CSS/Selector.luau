--!strict
local Tag = require(script.Parent.Parent.Tag)
local Types = require(script.Parent.Parent.Types)
local Values = require(script.Parent.Values)
local escape = require(script.Parent.Escape)
local Selector = {}

local function identifier(source: string, start: number): (string?, number)
	local pieces: { string } = {}
	local index = start
	while index <= #source do
		local char = source:sub(index, index)
		if char == "\\" then
			local decoded, after = escape(source, index)
			if not decoded then
				return nil, after
			end
			table.insert(pieces, decoded)
			index = after
		elseif char:match("[%w_%-]") or string.byte(char) >= 128 then
			table.insert(pieces, char)
			index += 1
		else
			break
		end
	end
	return if #pieces > 0 then table.concat(pieces) else nil, index
end

function Selector.parse(source: string, pascalCase: boolean?): Types.Selector?
	local tokens: { string } = {}
	local start, index = 1, 1
	while index <= #source do
		local char = source:sub(index, index)
		if char == "\\" then
			local decoded, after = escape(source, index)
			if not decoded then
				return nil
			end
			index = after
		elseif char:match("%s") or char == ">" or char == "+" or char == "~" then
			if index > start then
				table.insert(tokens, source:sub(start, index - 1))
			end
			if char == ">" or char == "+" or char == "~" then
				table.insert(tokens, char)
			end
			index += 1
			start = index
		else
			index += 1
		end
	end
	if start <= #source then
		table.insert(tokens, source:sub(start))
	end
	local parts: { Types.SelectorPart } = {}
	local specificity: Types.Specificity = { Ids = 0, Classes = 0, Tags = 0 }
	local relation: Types.SelectorRelation? = nil
	for _, token in tokens do
		if token == ">" or token == "+" or token == "~" then
			if #parts == 0 or relation ~= "Descendant" then
				return nil
			end
			relation = if token == ">" then "Child" elseif token == "+" then "AdjacentSibling" else "SubsequentSibling"
		else
			local part: Types.SelectorPart = { Classes = {}, States = {}, Relation = relation }
			local cursor = 1
			local tag: string? = nil
			local first = token:sub(1, 1)
			if first == "*" then
				tag, cursor = "*", 2
			elseif first:match("[%a_%-]") or first == "\\" or string.byte(first) >= 128 then
				tag, cursor = identifier(token, cursor)
				if not tag then
					return nil
				end
			end
			if tag then
				part.Tag = if tag == "*" then nil else Tag(tag)
				if tag ~= "*" and (not part.Tag or (pascalCase and tag ~= part.Tag)) then
					return nil
				end
				specificity.Tags += if tag == "*" then 0 else 1
			end
			while cursor <= #token do
				local prefix = token:sub(cursor, cursor)
				if prefix ~= "." and prefix ~= "#" and prefix ~= ":" then
					return nil
				end
				local name, after = identifier(token, cursor + 1)
				if not name then
					return nil
				end
				if prefix == "#" then
					if part.Id then
						return nil
					end
					part.Id = name
					specificity.Ids += 1
				elseif prefix == "." then
					table.insert(part.Classes, name)
					specificity.Classes += 1
				else
					if
						name == (if pascalCase then "Not" else "not")
						and token:sub(after, after + 9) == (if pascalCase then "([Hidden])" else "([hidden])")
					then
						table.insert(part.States, "NotHidden")
						specificity.Classes += 1
						cursor = after + 10
						continue
					end
					local states = if pascalCase
						then { "Hover", "Active", "Focus", "Disabled" }
						else { "hover", "active", "focus", "disabled" }
					if not table.find(states, name) then
						return nil
					end
					table.insert(part.States, Values.pascal(name) :: Types.SelectorState)
					specificity.Classes += 1
				end
				cursor = after
			end
			table.insert(parts, part)
			relation = "Descendant"
		end
	end
	if #parts == 0 or relation ~= "Descendant" or Values.trim(source) == "" then
		return nil
	end
	return { Parts = parts, Specificity = specificity }
end

local function matchesPart(part: Types.SelectorPart, node: Types.Node): boolean
	if part.Tag and part.Tag ~= node.Tag then
		return false
	end
	if part.Id and part.Id ~= node.Id then
		return false
	end
	for _, class in part.Classes do
		if not table.find(node.Classes, class) then
			return false
		end
	end
	for _, state in part.States do
		if state == "NotHidden" and node.Hidden then
			return false
		end
		if state == "Hover" and not node.Hover then
			return false
		end
		if state == "Active" and not node.Active then
			return false
		end
		if state == "Focus" and not node.Focus then
			return false
		end
		if state == "Disabled" and not node.Disabled then
			return false
		end
	end
	return true
end

function Selector.matches(selector: Types.Selector, node: Types.Node, ancestors: { Types.Node }): boolean
	local parts = selector.Parts
	local function visit(partIndex: number, ancestorIndex: number, current: Types.Node): boolean
		if partIndex == 0 then
			return true
		end
		local childPart = parts[partIndex + 1]
		if childPart.Relation == "AdjacentSibling" or childPart.Relation == "SubsequentSibling" then
			local siblings: { Types.Node } = current.PreviousSiblings or {}
			for index = #siblings, if childPart.Relation == "AdjacentSibling" then #siblings else 1, -1 do
				local sibling = siblings[index]
				if
					sibling
					and matchesPart(parts[partIndex], sibling)
					and visit(partIndex - 1, ancestorIndex, sibling)
				then
					return true
				end
			end
			return false
		end
		if childPart.Relation == "Child" then
			return ancestorIndex > 0
				and matchesPart(parts[partIndex], ancestors[ancestorIndex])
				and visit(partIndex - 1, ancestorIndex - 1, ancestors[ancestorIndex])
		end
		for index = ancestorIndex, 1, -1 do
			if
				matchesPart(parts[partIndex], ancestors[index]) and visit(partIndex - 1, index - 1, ancestors[index])
			then
				return true
			end
		end
		return false
	end
	return matchesPart(parts[#parts], node) and visit(#parts - 1, #ancestors, node)
end

return Selector
