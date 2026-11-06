--!strict
-- Packages
-- Modules
local Types = require(script.Parent.Parent.Types)
-- Types
export type Insets = { Top: number, Right: number, Bottom: number, Left: number }
export type Item = {
	Display: Types.Display,
	Width: number,
	Height: number,
	Baseline: number,
	LineHeight: number,
	VerticalAlign: Types.VerticalAlign?,
	Margin: Insets,
	Text: string?,
	WhiteSpace: Types.WhiteSpace?,
	Measure: ((string) -> number)?,
	Break: boolean?,
}
export type Fragment = { Item: number, X: number, Y: number, Width: number, Height: number, Text: string? }
export type Options = {
	Width: number,
	LineHeight: number,
	Baseline: number,
	XHeight: number,
	TextAlign: Types.TextAlign?,
	Gap: number?,
}
export type Result = { Fragments: { Fragment }, Height: number, Width: number }
type Piece = {
	Item: number,
	Width: number,
	Text: string?,
	Height: number,
	Above: number,
	Below: number,
	Align: Types.VerticalAlign,
}
-- Constants
-- References
-- Global Variables
-- Private Functions
local function collapsed(a: number, b: number): number
	return math.max(0, a, b) + math.min(0, a, b)
end
-- Class
local Flow = {}
function Flow.layout(items: { Item }, options: Options): Result
	local fragments: { Fragment } = {}
	local line: { Piece } = {}
	local run: { Piece } = {}
	local pending: Piece? = nil
	local x, y, maximum = 0, 0, 0
	local lastMargin = 0
	local previousBlock = false
	local function flushLine(force: boolean?)
		if #line == 0 and not force then
			return
		end
		local above, below = options.Baseline, options.LineHeight - options.Baseline
		local edgeHeight = 0
		for _, piece in line do
			if piece.Align == "Top" or piece.Align == "Bottom" then
				edgeHeight = math.max(edgeHeight, piece.Height)
			else
				above, below = math.max(above, piece.Above), math.max(below, piece.Below)
			end
		end
		local height = math.max(above + below, edgeHeight)
		local start = if options.TextAlign == "Center"
			then (options.Width - x) / 2
			elseif options.TextAlign == "Right" then options.Width - x
			else 0
		local offset = math.max(0, start)
		for _, piece in line do
			local top = if piece.Align == "Top"
				then 0
				elseif piece.Align == "Bottom" then height - piece.Height
				else above - piece.Above
			local item = items[piece.Item]
			local insetY = if piece.Text then (item.LineHeight - item.Height) / 2 else item.Margin.Top
			local fragment: Fragment = {
				Item = piece.Item,
				X = offset,
				Y = y + top + insetY,
				Width = piece.Width,
				Height = item.Height,
				Text = piece.Text,
			}
			if not piece.Text then
				fragment.X += item.Margin.Left
				fragment.Width = item.Width
			end
			local prior = fragments[#fragments]
			if
				prior
				and prior.Item == fragment.Item
				and prior.Text
				and fragment.Text
				and math.abs(prior.Y - fragment.Y) < 0.001
				and math.abs(prior.X + prior.Width - fragment.X) < 0.001
			then
				prior.Text ..= fragment.Text
				prior.Width += fragment.Width
			else
				table.insert(fragments, fragment)
			end
			offset += piece.Width
		end
		maximum = math.max(maximum, x)
		y += height
		x = 0
		table.clear(line)
	end
	local function push(piece: Piece)
		table.insert(line, piece)
		x += piece.Width
	end
	local function flushRun(wrap: boolean)
		if #run == 0 then
			return
		end
		local width = 0
		for _, piece in run do
			width += piece.Width
		end
		if wrap and #line > 0 and x + (if pending then pending.Width else 0) + width > options.Width + 0.001 then
			flushLine()
			pending = nil
		end
		if pending and #line > 0 then
			push(pending)
		end
		pending = nil
		for _, piece in run do
			push(piece)
		end
		table.clear(run)
	end
	local function textPiece(index: number, text: string): Piece
		local item = items[index]
		local height = item.LineHeight
		local above = item.Baseline + (height - item.Height) / 2
		local align: Types.VerticalAlign = item.VerticalAlign or "Baseline"
		if align == "Middle" then
			above = height / 2 + options.XHeight / 2
		end
		return {
			Item = index,
			Width = assert(item.Measure)(text),
			Text = text,
			Height = height,
			Above = above,
			Below = height - above,
			Align = align,
		}
	end
	for index, item in items do
		if item.Display == "None" then
			continue
		end
		if item.Display == "Block" or item.Display == "Flex" then
			flushRun(true)
			pending = nil
			flushLine()
			if previousBlock then
				y += collapsed(lastMargin, item.Margin.Top) - lastMargin + (options.Gap or 0)
			else
				y += item.Margin.Top
			end
			table.insert(
				fragments,
				{ Item = index, X = item.Margin.Left, Y = y, Width = item.Width, Height = item.Height }
			)
			y += item.Height + item.Margin.Bottom
			maximum = math.max(maximum, item.Width + item.Margin.Left + item.Margin.Right)
			lastMargin, previousBlock = item.Margin.Bottom, true
		elseif item.Break then
			flushRun(true)
			pending = nil
			flushLine(true)
			previousBlock = false
		elseif item.Display == "Inline" and item.Text and item.Measure then
			previousBlock = false
			local mode = item.WhiteSpace or "Normal"
			local preserve = mode == "Pre" or mode == "PreWrap"
			local wrap = mode ~= "Pre" and mode ~= "Nowrap"
			local source = item.Text:gsub("\r\n", "\n"):gsub("\r", "\n")
			local position = 1
			while position <= #source do
				local whitespace = source:match("^[ \t\n\f]+", position)
				if whitespace then
					flushRun(wrap)
					if preserve then
						for character in whitespace:gmatch(".") do
							if character == "\n" then
								pending = nil
								flushLine(true)
							else
								push(textPiece(index, if character == "\t" then "    " else " "))
							end
						end
					elseif not pending then
						pending = textPiece(index, " ")
					end
					position += #whitespace
				else
					local word = assert(source:match("^[^ \t\n\f]+", position))
					table.insert(run, textPiece(index, word))
					position += #word
				end
			end
			-- Keep adjacent differently styled text in one unbreakable word until
			-- an actual whitespace boundary, atomic box, or explicit break occurs.
			if not wrap then
				flushRun(false)
			end
		else
			flushRun(true)
			local width = item.Width + item.Margin.Left + item.Margin.Right
			if #line > 0 and x + (if pending then pending.Width else 0) + width > options.Width + 0.001 then
				flushLine()
				pending = nil
			end
			if pending and #line > 0 then
				push(pending)
			end
			pending = nil
			local height = item.Height + item.Margin.Top + item.Margin.Bottom
			local above = item.Baseline + item.Margin.Top
			local align: Types.VerticalAlign = item.VerticalAlign or "Baseline"
			if align == "Middle" then
				above = height / 2 + options.XHeight / 2
			end
			push({ Item = index, Width = width, Height = height, Above = above, Below = height - above, Align = align })
			previousBlock = false
		end
	end
	flushRun(true)
	flushLine()
	return { Fragments = fragments, Height = y, Width = maximum }
end
return Flow
