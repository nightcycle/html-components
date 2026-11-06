--!strict
local Tag = require(script.Parent.Parent.Tag)
local Types = require(script.Parent.Parent.Types)
local Values = require(script.Parent.Values)
local Selector = {}

function Selector.parse(source: string, pascalCase: boolean?): Types.Selector?
	local tokens: { string } = {}
	for token in source:gsub(">", " > "):gmatch("%S+") do
		table.insert(tokens, token)
	end
	local parts: { Types.SelectorPart } = {}
	local specificity: Types.Specificity = { Ids = 0, Classes = 0, Tags = 0 }
	local relation: Types.SelectorRelation? = nil
	for _, token in tokens do
		if token == ">" then
			if #parts == 0 or relation == "Child" then
				return nil
			end
			relation = "Child"
		else
			local part: Types.SelectorPart = { Classes = {}, States = {}, Relation = relation }
			local rest = token
			local tag = rest:match("^([%a][%w%-]*)") or rest:match("^(%*)")
			if tag then
				part.Tag = if tag == "*" then nil else Tag(tag)
				if tag ~= "*" and (not part.Tag or (pascalCase and tag ~= part.Tag)) then
					return nil
				end
				specificity.Tags += if tag == "*" then 0 else 1
				rest = rest:sub(#tag + 1)
			end
			while rest ~= "" do
				local prefix, name = rest:match("^([%.#:])([%w_%-]+)")
				if not prefix or not name then
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
					local states = if pascalCase
						then { "Hover", "Active", "Focus", "Disabled" }
						else { "hover", "active", "focus", "disabled" }
					if not table.find(states, name) then
						return nil
					end
					table.insert(part.States, Values.pascal(name) :: Types.SelectorState)
					specificity.Classes += 1
				end
				rest = rest:sub(#name + 2)
			end
			table.insert(parts, part)
			relation = "Descendant"
		end
	end
	if #parts == 0 or relation == "Child" or Values.trim(source) == "" then
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
	local function visit(partIndex: number, ancestorIndex: number): boolean
		if partIndex == 0 then
			return true
		end
		local childPart = parts[partIndex + 1]
		if childPart.Relation == "Child" then
			return ancestorIndex > 0
				and matchesPart(parts[partIndex], ancestors[ancestorIndex])
				and visit(partIndex - 1, ancestorIndex - 1)
		end
		for index = ancestorIndex, 1, -1 do
			if matchesPart(parts[partIndex], ancestors[index]) and visit(partIndex - 1, index - 1) then
				return true
			end
		end
		return false
	end
	return matchesPart(parts[#parts], node) and visit(#parts - 1, #ancestors)
end

return Selector
