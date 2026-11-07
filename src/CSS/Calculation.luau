--!strict
-- Packages
-- Modules
-- Types
type Quantity = { Value: number, Unit: string }
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
-- Deliberately limited to scalar arithmetic and compatible px/% dimensions.
return function(source: string): string?
	if source:sub(1, 5) ~= "calc(" then
		return source
	end
	local text = source:gsub("calc%(", "(")
	local cursor, depth = 1, 0
	local expression: () -> Quantity?
	local function skip()
		while text:sub(cursor, cursor):match("%s") do
			cursor += 1
		end
	end
	local function primary(): Quantity?
		skip()
		local sign = 1
		local char = text:sub(cursor, cursor)
		if char == "+" or char == "-" then
			sign = if char == "-" then -1 else 1
			cursor += 1
			skip()
		end
		local value: Quantity?
		if text:sub(cursor, cursor) == "(" then
			depth += 1
			if depth > 32 then
				return nil
			end
			cursor += 1
			value = expression()
			skip()
			if text:sub(cursor, cursor) ~= ")" then
				return nil
			end
			cursor += 1
			depth -= 1
		else
			local number = text:sub(cursor):match("^%d*%.?%d+")
			if not number then
				return nil
			end
			cursor += #number
			local unit = text:sub(cursor):match("^px") or text:sub(cursor):match("^%%") or ""
			cursor += #unit
			value = { Value = tonumber(number) or 0, Unit = unit }
		end
		if value then
			value.Value *= sign
		end
		return value
	end
	local function product(): Quantity?
		local left = primary()
		while left do
			skip()
			local op = text:sub(cursor, cursor)
			if op ~= "*" and op ~= "/" then
				break
			end
			cursor += 1
			local right = primary()
			if not right then
				return nil
			end
			if op == "*" then
				if left.Unit ~= "" and right.Unit ~= "" then
					return nil
				end
				left.Value *= right.Value
				if left.Unit == "" then
					left.Unit = right.Unit
				end
			else
				if right.Unit ~= "" or right.Value == 0 then
					return nil
				end
				left.Value /= right.Value
			end
		end
		return left
	end
	expression = function(): Quantity?
		local left = product()
		while left do
			skip()
			local op = text:sub(cursor, cursor)
			if op ~= "+" and op ~= "-" then
				break
			end
			cursor += 1
			local right = product()
			if not right or left.Unit ~= right.Unit then
				return nil
			end
			left.Value += right.Value * (if op == "-" then -1 else 1)
		end
		return left
	end
	local result = expression()
	skip()
	if not result or cursor <= #text or result.Value ~= result.Value or math.abs(result.Value) == math.huge then
		return nil
	end
	return tostring(result.Value) .. result.Unit
end
