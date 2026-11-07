--!strict
-- Packages
-- Modules
local Decoration = require(script.Parent.Parent.React.Render.Decoration)
local Flow = require(script.Parent.Flow)
local Metrics = require(script.Parent.Metrics)
local Types = require(script.Parent.Parent.Types)
-- Types
export type Input = {
	Tag: Types.Tag,
	Style: Types.Style,
	Layout: boolean,
	Size: UDim2?,
	AutomaticSize: Enum.AutomaticSize?,
	TextTransparency: number?,
	TextStrokeTransparency: number?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	IntrinsicSize: Vector2?,
}
type Entry = {
	Host: GuiObject,
	Input: Input,
	Fragments: { TextLabel },
	Connections: { RBXScriptConnection },
	Alive: boolean,
}
type Box = {
	Entry: Entry,
	X: number,
	Y: number,
	Width: number,
	Height: number,
	Baseline: number,
	CollapsedBottom: number?,
	PaintInlineBox: boolean?,
	Children: { Box },
	Text: { Flow.Fragment },
}
type Bounds = { Left: number, Top: number, Right: number, Bottom: number }
-- Constants
local TEXT_SERVICE = game:GetService("TextService")
local ZERO: Flow.Insets = { Top = 0, Right = 0, Bottom = 0, Left = 0 }
-- References
-- Global Variables
local entries: { [GuiObject]: Entry } = {}
local pending: { [Entry]: boolean } = {}
local widths: { [string]: number } = {}
local cacheSize = 0
local running = false
local revision = 0
-- Private Functions
local function display(entry: Entry): Types.Display
	return entry.Input.Style.Display or "Block"
end

local function flex(entry: Entry): boolean
	return display(entry) == "Flex" or display(entry) == "InlineFlex"
end

local function positioned(entry: Entry): boolean
	return entry.Input.Style.Position == "Absolute" or entry.Input.Style.Position == "Fixed"
end

local function children(entry: Entry): { Entry }
	local result: { Entry } = {}
	for _, child in entry.Host:GetChildren() do
		if child:IsA("GuiObject") then
			local found = entries[child]
			if found and found.Alive and child.Visible then
				table.insert(result, found)
			end
		end
	end
	-- GetChildren order is retained for ties. Importers should assign LayoutOrder.
	local order: { [Entry]: number } = {}
	for index, child in result do
		order[child] = index
	end
	table.sort(result, function(a, b)
		if a.Host.LayoutOrder == b.Host.LayoutOrder then
			return order[a] < order[b]
		end
		return a.Host.LayoutOrder < b.Host.LayoutOrder
	end)
	return result
end

local function insets(style: Types.Style, basis: number, margin: boolean, inlinePadding: boolean?): Flow.Insets
	if margin then
		return {
			Top = Metrics.length(style.MarginTop or style.Margin, basis, 0),
			Right = Metrics.length(style.MarginRight or style.Margin, basis, 0),
			Bottom = Metrics.length(style.MarginBottom or style.Margin, basis, 0),
			Left = Metrics.length(style.MarginLeft or style.Margin, basis, 0),
		}
	end
	if style.Display == "Inline" and not inlinePadding then
		return ZERO
	end
	local border = style.BorderWidth or 0
	return {
		Top = Metrics.length(style.PaddingTop or style.Padding, basis, 0) + border,
		Right = Metrics.length(style.PaddingRight or style.Padding, basis, 0) + border,
		Bottom = Metrics.length(style.PaddingBottom or style.Padding, basis, 0) + border,
		Left = Metrics.length(style.PaddingLeft or style.Padding, basis, 0) + border,
	}
end

local function margins(style: Types.Style, basis: number, width: number): Flow.Insets
	local result = insets(style, basis, true)
	local function auto(value: Types.Length?): boolean
		return value == "Auto" or value == "auto"
	end
	if style.Display ~= "InlineBlock" and style.Display ~= "InlineFlex" and style.Display ~= "Inline" then
		local left, right = auto(style.MarginLeft or style.Margin), auto(style.MarginRight or style.Margin)
		local remaining = math.max(0, basis - width - result.Left - result.Right)
		if left then
			result.Left = remaining / (if right then 2 else 1)
		end
		if right then
			result.Right = remaining / (if left then 2 else 1)
		end
	end
	return result
end

local function font(entry: Entry): (Font, number)
	local host = entry.Host
	if host:IsA("TextLabel") or host:IsA("TextButton") or host:IsA("TextBox") then
		return host.FontFace, host.TextSize
	end
	local style = entry.Input.Style
	return Metrics.face(style), Metrics.text(style)
end

local function measure(entry: Entry, text: string): number
	if text == "" then
		return 0
	end
	local face, size = font(entry)
	local key = `{face.Family}:{face.Weight.Name}:{face.Style.Name}:{size}:{text}`
	local cached = widths[key]
	if cached then
		return cached
	end
	local params = Instance.new("GetTextBoundsParams")
	-- Measure at the rendered size: font hinting makes scaled measurements differ.
	params.Font, params.Size, params.Text, params.Width = face, size, text, 1000000
	local bounds = TEXT_SERVICE:GetTextBoundsAsync(params)
	params:Destroy()
	if cacheSize >= 2048 then
		table.clear(widths)
		cacheSize = 0
	end
	widths[key] = bounds.X
	cacheSize += 1
	return bounds.X
end

local function text(entry: Entry): string?
	local host = entry.Host
	if host:IsA("TextLabel") or host:IsA("TextButton") then
		-- ContentText strips only the markup introduced by Paint (or native RichText).
		return if host.RichText then host.ContentText else host.Text
	end
	return nil
end

local function intrinsic(entry: Entry, available: number): number
	local style = entry.Input.Style
	if entry.Input.Size then
		return entry.Input.Size.X.Scale * available + entry.Input.Size.X.Offset
	end
	if style.Width and style.Width ~= "Auto" and style.Width ~= "auto" then
		return Metrics.length(style.Width, available, 0)
	end
	local own = text(entry)
	if entry.Input.IntrinsicSize then
		local size = entry.Input.IntrinsicSize
		return if style.Height and style.Height ~= "Auto"
			then Metrics.length(style.Height, available, size.Y) * size.X / math.max(1, size.Y)
			else size.X
	end
	local width, line = 0, 0
	if own then
		if style.WhiteSpace ~= "Pre" and style.WhiteSpace ~= "PreWrap" then
			own = own:gsub("%s+", " ")
			if not own:find("%S") then
				own = ""
			elseif entry.Host.Name ~= "#text" then
				own = own:gsub("^%s+", ""):gsub("%s+$", "")
			end
		end
		for value in own:gmatch("[^\n]+") do
			-- Flow shapes words separately. Use the same advances for intrinsic
			-- sizing so kerning/rounding cannot wrap a max-content flex item.
			local advance = if value:match("^%s") then measure(entry, " ") else 0
			for word, space in value:gmatch("(%S+)(%s*)") do
				advance += measure(entry, word) + (if space and space ~= "" then measure(entry, space) else 0)
			end
			width = math.max(width, advance)
		end
		line = width
	end
	for _, child in children(entry) do
		if positioned(child) then
			continue
		end
		local value = intrinsic(child, available)
		local margin = insets(child.Input.Style, available, true)
		value += margin.Left + margin.Right
		if flex(entry) and entry.Input.Style.FlexDirection ~= "Column" then
			line += value
		elseif
			display(child) == "Block"
			or display(child) == "Flex"
			or display(child) == "Grid"
			or child.Input.Tag == "Br"
		then
			width, line = math.max(width, line, value), 0
		else
			line += value
		end
	end
	local padding = insets(style, available, false)
	local gap = if flex(entry) and style.FlexDirection ~= "Column"
		then math.max(0, #children(entry) - 1) * Metrics.length(style.Gap, available, 0)
		else 0
	return math.clamp(
		math.ceil(math.max(width, line)) + padding.Left + padding.Right + gap,
		style.MinWidth or 0,
		math.max(style.MinWidth or 0, style.MaxWidth or math.huge)
	)
end

local function layout(entry: Entry, available: number, parentHeight: number, forcedWidth: number?): Box
	local style, native = entry.Input.Style, entry.Input.Size
	local mode = display(entry)
	local outerMargin = insets(style, available, true)
	local width = Metrics.length(
		style.Width,
		available,
		if mode == "InlineBlock"
				or mode == "InlineFlex"
				or entry.Input.IntrinsicSize ~= nil
			then math.min(available, intrinsic(entry, available))
			else available - outerMargin.Left - outerMargin.Right
	)
	if native then
		width = native.X.Scale * available + native.X.Offset
	end
	if forcedWidth then
		width = forcedWidth
	end
	width = math.clamp(width, style.MinWidth or 0, math.max(style.MinWidth or 0, style.MaxWidth or math.huge))
	local padding = insets(style, width, false)
	local contentWidth = math.max(0, width - padding.Left - padding.Right)
	local _, size = font(entry)
	local glyphHeight, lineHeight, baseline, xHeight = Metrics.text(style, size)
	local box: Box = { Entry = entry, X = 0, Y = 0, Width = width, Height = 0, Baseline = 0, Children = {}, Text = {} }
	local height = 0
	if not entry.Input.Layout then
		for _, child in children(entry) do
			table.insert(box.Children, layout(child, contentWidth, entry.Host.AbsoluteSize.Y))
		end
		height = if entry.Input.IntrinsicSize
			then width * entry.Input.IntrinsicSize.Y / math.max(1, entry.Input.IntrinsicSize.X)
			else glyphHeight
	elseif flex(entry) or mode == "Grid" then
		local members: { Entry } = {}
		for _, child in children(entry) do
			local own = text(child)
			if child.Host.Name == "#text" and own and own:match("^%s*$") then
				continue
			end
			if not positioned(child) then
				table.insert(members, child)
			end
		end
		local horizontalGap = Metrics.length(style.ColumnGap or style.Gap, contentWidth, 0)
		local verticalGap = Metrics.length(style.RowGap or style.Gap, contentWidth, 0)
		if mode == "Grid" then
			local columns = math.max(1, style.GridTemplateColumns or 1)
			local track = math.max(0, (contentWidth - (columns - 1) * horizontalGap) / columns)
			local cursor, rowHeight, y = 0, 0, 0
			local row: { Box } = {}
			local function finish()
				for _, child in row do
					local ownStyle = child.Entry.Input.Style
					local align = ownStyle.PlaceSelf or ownStyle.AlignSelf or style.AlignItems or "Stretch"
					local margin = insets(ownStyle, contentWidth, true)
					margin.Bottom = math.max(margin.Bottom, child.CollapsedBottom or 0)
					local remaining = rowHeight - child.Height - margin.Top - margin.Bottom
					if align == "Center" then
						child.Y += remaining / 2
					elseif align == "FlexEnd" then
						child.Y += remaining
					elseif align == "Stretch" and not ownStyle.Height then
						child.Height = rowHeight
					end
				end
				y += rowHeight + verticalGap
				cursor, rowHeight = 0, 0
				table.clear(row)
			end
			for _, child in members do
				local span = math.clamp(child.Input.Style.GridColumn or 1, 1, columns)
				if cursor + span > columns then
					finish()
				end
				local slot = track * span + horizontalGap * (span - 1)
				local ownStyle = child.Input.Style
				local inset = insets(ownStyle, slot, true)
				local centered = ownStyle.PlaceSelf == "Center"
				local ownWidth = if centered
					then math.min(slot, intrinsic(child, slot))
					else slot - inset.Left - inset.Right
				local childBox = layout(child, slot, parentHeight, Metrics.length(ownStyle.Width, slot, ownWidth))
				local margin = margins(ownStyle, slot, childBox.Width)
				margin.Bottom = math.max(margin.Bottom, childBox.CollapsedBottom or 0)
				local autoMargin = ownStyle.MarginLeft == "Auto"
					or ownStyle.MarginRight == "Auto"
					or ownStyle.Margin == "Auto"
				childBox.X = cursor * (track + horizontalGap)
					+ (if centered and not autoMargin then (slot - childBox.Width) / 2 else margin.Left)
				childBox.Y = y + margin.Top
				table.insert(box.Children, childBox)
				table.insert(row, childBox)
				rowHeight = math.max(rowHeight, childBox.Height + margin.Top + margin.Bottom)
				cursor += span
			end
			if #row > 0 then
				finish()
			end
			height = math.max(0, y - verticalGap)
		else
			local horizontal = style.FlexDirection ~= "Column"
			local base: { number } = {}
			local total, shrink, grow = math.max(0, #members - 1) * horizontalGap, 0, 0
			for index, child in members do
				local ownStyle = child.Input.Style
				base[index] = math.min(
					ownStyle.MaxWidth or math.huge,
					Metrics.length(ownStyle.Width, contentWidth, intrinsic(child, contentWidth))
				)
				local margin = insets(ownStyle, contentWidth, true)
				total += base[index] + margin.Left + margin.Right
				shrink += base[index] * (ownStyle.FlexShrink or 1)
				grow += ownStyle.FlexGrow or 0
			end
			local x, y, rowHeight = 0, 0, 0
			local row: { Box } = {}
			local function finish()
				if #row == 0 then
					return
				end
				local extra = math.max(0, contentWidth - x + horizontalGap)
				local offset = if style.JustifyContent == "Center"
					then extra / 2
					elseif style.JustifyContent == "FlexEnd" then extra
					else 0
				local between = if style.JustifyContent == "SpaceBetween" and #row > 1 then extra / (#row - 1) else 0
				if style.JustifyContent == "SpaceEvenly" then
					between = extra / (#row + 1)
					offset = between
				end
				if style.JustifyContent == "SpaceAround" then
					between = extra / #row
					offset = between / 2
				end
				local rowBaseline, descent = 0, 0
				for _, child in row do
					local ownStyle = child.Entry.Input.Style
					if (ownStyle.AlignSelf or style.AlignItems) == "Baseline" then
						local margin = insets(ownStyle, contentWidth, true)
						rowBaseline = math.max(rowBaseline, margin.Top + child.Baseline)
						descent = math.max(descent, child.Height - child.Baseline + margin.Bottom)
					end
				end
				rowHeight = math.max(rowHeight, rowBaseline + descent)
				for index, child in row do
					child.X += offset + (index - 1) * between
					local align = child.Entry.Input.Style.AlignSelf or style.AlignItems or "Stretch"
					if align == "Baseline" then
						child.Y = y + rowBaseline - child.Baseline
					elseif align == "Center" then
						child.Y += (rowHeight - child.Height) / 2
					elseif align == "FlexEnd" then
						child.Y += rowHeight - child.Height
					elseif align == "Stretch" and not child.Entry.Input.Style.Height then
						child.Height = rowHeight
					end
					if index == 1 and box.Baseline == 0 then
						box.Baseline = child.Y + child.Baseline + padding.Top
					end
				end
				y += rowHeight + verticalGap
				x, rowHeight = 0, 0
				table.clear(row)
			end
			for index, child in members do
				local ownStyle = child.Input.Style
				local margin = insets(ownStyle, contentWidth, true)
				local ownWidth = base[index]
				if horizontal and style.FlexWrap ~= "Wrap" then
					if total > contentWidth and shrink > 0 then
						ownWidth -= (total - contentWidth) * base[index] * (ownStyle.FlexShrink or 1) / shrink
					elseif total < contentWidth and grow > 0 then
						ownWidth += (contentWidth - total) * (ownStyle.FlexGrow or 0) / grow
					end
				elseif not horizontal then
					local align = ownStyle.AlignSelf or style.AlignItems or "Stretch"
					if align == "Stretch" and not ownStyle.Width then
						ownWidth = contentWidth - margin.Left - margin.Right
					end
				end
				local childBox = layout(child, contentWidth, parentHeight, math.max(0, ownWidth))
				margin.Bottom = math.max(margin.Bottom, childBox.CollapsedBottom or 0)
				if horizontal then
					if
						style.FlexWrap == "Wrap"
						and x > 0
						and x + childBox.Width + margin.Left + margin.Right > contentWidth
					then
						finish()
					end
					childBox.X, childBox.Y = x + margin.Left, y + margin.Top
					x += childBox.Width + margin.Left + margin.Right + horizontalGap
					rowHeight = math.max(rowHeight, childBox.Height + margin.Top + margin.Bottom)
					table.insert(row, childBox)
				else
					local align = ownStyle.AlignSelf or style.AlignItems
					childBox.X = if align == "Center"
						then (contentWidth - childBox.Width) / 2
						elseif align == "FlexEnd" then contentWidth - childBox.Width
						else margin.Left
					childBox.Y = y + margin.Top
					y += childBox.Height + margin.Top + margin.Bottom + verticalGap
				end
				table.insert(box.Children, childBox)
			end
			if horizontal then
				finish()
			end
			height = math.max(0, y - verticalGap)
		end
	else
		local items: { Flow.Item } = {}
		local owners: { Box } = {}
		local inline: { [Box]: boolean } = {}
		local inlinePadding: { [Box]: Flow.Insets } = {}
		local bounds: { [Box]: Bounds } = {}
		local parents: { [Box]: Box } = {}
		local function addText(owner: Box)
			local value = text(owner.Entry)
			if not value or value == "" then
				return
			end
			local _, nativeSize = font(owner.Entry)
			local ownStyle = owner.Entry.Input.Style
			local h, line, base = Metrics.text(ownStyle, nativeSize)
			table.insert(items, {
				Display = "Inline",
				Width = 0,
				Height = h,
				Baseline = base,
				LineHeight = line,
				Margin = ZERO,
				Text = value,
				WhiteSpace = ownStyle.WhiteSpace,
				VerticalAlign = ownStyle.VerticalAlign,
				Measure = function(valueToMeasure)
					return measure(owner.Entry, valueToMeasure)
				end,
			})
			table.insert(owners, owner)
		end
		local function collect(parent: Box)
			addText(parent)
			for _, child in children(parent.Entry) do
				if positioned(child) then
					continue
				end
				local childMode: Types.Display = display(child)
				local isInline = childMode == "Inline" and child.Input.Layout
				local childBox: Box = if isInline
					then { Entry = child, X = 0, Y = 0, Width = 0, Height = 0, Baseline = 0, Children = {}, Text = {} }
					else layout(child, contentWidth, parentHeight)
				table.insert(parent.Children, childBox)
				parents[childBox] = parent
				if isInline then
					inline[childBox] = true
					local inset = insets(child.Input.Style, contentWidth, false, true)
					local margin = insets(child.Input.Style, contentWidth, true)
					local decorated = inset.Top ~= 0 or inset.Right ~= 0 or inset.Bottom ~= 0 or inset.Left ~= 0
					local function edge(width: number, left: number, right: number)
						table.insert(items, {
							Display = "InlineBlock",
							Width = width,
							Height = 0,
							Baseline = 0,
							LineHeight = 0,
							Margin = { Top = 0, Right = right, Bottom = 0, Left = left },
						})
						table.insert(owners, childBox)
					end
					if decorated then
						inlinePadding[childBox] = inset
						edge(inset.Left, margin.Left, 0)
					end
					collect(childBox)
					if decorated then
						edge(inset.Right, 0, margin.Right)
					end
				else
					local margin = margins(child.Input.Style, contentWidth, childBox.Width)
					margin.Bottom = math.max(margin.Bottom, childBox.CollapsedBottom or 0)
					table.insert(items, {
						Display = childMode,
						Width = childBox.Width,
						Height = childBox.Height,
						Baseline = childBox.Baseline,
						LineHeight = childBox.Height,
						Margin = margin,
						VerticalAlign = child.Input.Style.VerticalAlign,
						Break = child.Input.Tag == "Br",
					})
					table.insert(owners, childBox)
				end
			end
		end
		collect(box)
		local result = Flow.layout(items, {
			Width = contentWidth,
			LineHeight = lineHeight,
			Baseline = baseline + (lineHeight - glyphHeight) / 2,
			XHeight = xHeight,
			TextAlign = style.TextAlign,
			Gap = Metrics.length(style.Gap, contentWidth, 0),
		})
		for _, fragment in result.Fragments do
			local owner = owners[fragment.Item]
			if fragment.Text then
				table.insert(owner.Text, fragment)
			else
				owner.X, owner.Y = fragment.X, fragment.Y
			end
			local ancestor: Box? = owner
			while ancestor and ancestor ~= box do
				local prior = bounds[ancestor]
				if prior then
					prior.Left = math.min(prior.Left, fragment.X)
					prior.Top = math.min(prior.Top, fragment.Y)
					prior.Right = math.max(prior.Right, fragment.X + fragment.Width)
					prior.Bottom = math.max(prior.Bottom, fragment.Y + fragment.Height)
				else
					bounds[ancestor] = {
						Left = fragment.X,
						Top = fragment.Y,
						Right = fragment.X + fragment.Width,
						Bottom = fragment.Y + fragment.Height,
					}
				end
				ancestor = parents[ancestor]
			end
			box.Baseline = math.max(box.Baseline, fragment.Y + items[fragment.Item].Baseline + padding.Top)
		end
		for owner in inline do
			local bound = bounds[owner]
			if bound then
				owner.X, owner.Y, owner.Width, owner.Height =
					bound.Left, bound.Top, bound.Right - bound.Left, bound.Bottom - bound.Top
				local inset = inlinePadding[owner]
				local _, ownSize = font(owner.Entry)
				local _, ownLine = Metrics.text(owner.Entry.Input.Style, ownSize)
				if inset and owner.Height <= math.max(ownSize, ownLine) + 0.01 then
					-- Padding paints outside a single inline line box without
					-- increasing its line height, as for a padded text link.
					owner.Y -= inset.Top
					owner.Height += inset.Top + inset.Bottom
					owner.PaintInlineBox = true
				end
			end
		end
		-- Shared line coordinates become local coordinates without losing the native ancestry/ref.
		local function localize(parent: Box, originX: number, originY: number)
			for _, child in parent.Children do
				local x, y = child.X, child.Y
				if inline[child] then
					for _, fragment in child.Text do
						fragment.X -= x
						fragment.Y -= y
					end
					localize(child, x, y)
				end
				child.X -= originX
				child.Y -= originY
			end
		end
		localize(box, 0, 0)
		height = result.Height
		-- A final block margin escapes an auto-height block with no bottom
		-- border/padding. Carry it into the parent's margin-collapse calculation.
		if mode == "Block" and padding.Bottom == 0 and not style.Height and style.Overflow ~= "Hidden" then
			for index = #items, 1, -1 do
				local item = items[index]
				if item.Text and item.Text:match("^%s*$") then
					continue
				end
				if item.Display == "Block" or item.Display == "Flex" or item.Display == "Grid" then
					box.CollapsedBottom = item.Margin.Bottom
					height -= item.Margin.Bottom
				end
				break
			end
		end
	end
	height += padding.Top + padding.Bottom
	if style.Height and style.Height ~= "Auto" and style.Height ~= "auto" then
		height = Metrics.length(style.Height, parentHeight, height)
	end
	if native then
		local automatic = entry.Input.AutomaticSize
		if automatic ~= Enum.AutomaticSize.Y and automatic ~= Enum.AutomaticSize.XY then
			height = native.Y.Scale * parentHeight + native.Y.Offset
		end
	end
	box.Height = math.clamp(height, style.MinHeight or 0, math.max(style.MinHeight or 0, style.MaxHeight or math.huge))
	for _, child in children(entry) do
		if positioned(child) then
			local childBox = layout(child, contentWidth, box.Height)
			local ownStyle = child.Input.Style
			childBox.X = Metrics.length(
				ownStyle.Left,
				contentWidth,
				if ownStyle.Right
					then contentWidth - Metrics.length(ownStyle.Right, contentWidth, 0) - childBox.Width
					else 0
			)
			childBox.Y = Metrics.length(
				ownStyle.Top,
				box.Height,
				if ownStyle.Bottom
					then box.Height - Metrics.length(ownStyle.Bottom, box.Height, 0) - childBox.Height
					else 0
			)
			table.insert(box.Children, childBox)
		end
	end
	if box.Baseline == 0 or style.Overflow == "Hidden" then
		box.Baseline = box.Height
	end
	return box
end

local function inlineBackground(entry: Entry): (Color3, number)
	local current: Entry? = entry
	while current and display(current) == "Inline" do
		if (current.Input.BackgroundTransparency or 1) < 1 then
			return current.Input.BackgroundColor or Color3.new(), current.Input.BackgroundTransparency or 1
		end
		local parent = current.Host.Parent
		current = if parent and parent:IsA("GuiObject") then entries[parent] else nil
	end
	return Color3.new(), 1
end

local function setTransparency(host: GuiObject, textTransparency: number, stroke: number)
	if host:IsA("TextLabel") then
		host.TextTransparency, host.TextStrokeTransparency = textTransparency, stroke
	elseif host:IsA("TextButton") then
		host.TextTransparency, host.TextStrokeTransparency = textTransparency, stroke
	end
end

local function paint(box: Box, position: boolean)
	local entry, host = box.Entry, box.Entry.Host
	if not entry.Alive then
		return
	end
	if position then
		host.AnchorPoint = Vector2.zero
		local desired = UDim2.fromOffset(box.X, box.Y)
		if host.Position ~= desired then
			host.Position = desired
		end
	end
	local size = UDim2.fromOffset(box.Width, box.Height)
	if host.Size ~= size then
		host.Size = size
	end
	if host.AutomaticSize ~= Enum.AutomaticSize.None then
		host.AutomaticSize = Enum.AutomaticSize.None
	end
	local managedText = (host:IsA("TextLabel") or host:IsA("TextButton"))
		and entry.Input.Layout
		and not flex(entry)
		and not host.TextScaled
	local inline = display(entry) == "Inline" and entry.Input.Layout
	host.BackgroundTransparency = if inline and not box.PaintInlineBox
		then 1
		else entry.Input.BackgroundTransparency or 1
	if managedText and (host:IsA("TextLabel") or host:IsA("TextButton")) then
		setTransparency(host, 1, 1)
		for index, fragment in box.Text do
			local label = entry.Fragments[index]
			if not label then
				local created = Instance.new("TextLabel")
				created.Name = "HTMLInlineFragment"
				created.BackgroundTransparency, created.BorderSizePixel = 1, 0
				created.TextXAlignment, created.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
				created.Parent = host
				entry.Fragments[index] = created
				label = created
			end
			label.Text = fragment.Text or ""
			label.RichText = false
			label.FontFace, label.TextSize = host.FontFace, host.TextSize
			label.TextColor3, label.TextStrokeColor3 = host.TextColor3, host.TextStrokeColor3
			label.TextTransparency = entry.Input.TextTransparency or 0
			label.TextStrokeTransparency = entry.Input.TextStrokeTransparency or 1
			label.ZIndex = host.ZIndex
			if inline then
				label.BackgroundColor3, label.BackgroundTransparency = inlineBackground(entry)
			else
				label.BackgroundTransparency = 1
			end
			label.Position = UDim2.fromOffset(fragment.X, fragment.Y)
			label.Size = UDim2.fromOffset(fragment.Width + 1, fragment.Height)
			label.Text, label.RichText = Decoration.markup(label.Text, entry.Input.Style.TextDecoration)
		end
	end
	for index = #entry.Fragments, (if managedText then #box.Text else 0) + 1, -1 do
		entry.Fragments[index]:Destroy()
		table.remove(entry.Fragments, index)
	end
	if not managedText and (host:IsA("TextLabel") or host:IsA("TextButton")) then
		setTransparency(host, entry.Input.TextTransparency or 0, entry.Input.TextStrokeTransparency or 1)
	end
	for _, child in box.Children do
		paint(child, entry.Input.Layout)
	end
end

local function top(entry: Entry): Entry
	local parent = entry.Host.Parent
	while parent and parent:IsA("GuiObject") do
		local owner = entries[parent]
		if not owner or not owner.Input.Layout then
			break
		end
		entry, parent = owner, parent.Parent
	end
	return entry
end

local function enqueue(entry: Entry)
	if not entry.Alive then
		return
	end
	pending[top(entry)] = true
	revision += 1
	if running then
		return
	end
	running = true
	task.defer(function()
		while next(pending) do
			local batch = pending
			pending = {}
			for root in batch do
				if not root.Alive or not root.Host.Parent then
					continue
				end
				local before = revision
				local ok, problem = pcall(function()
					local parent = root.Host.Parent
					local area = if parent and parent:IsA("GuiBase2d")
						then parent.AbsoluteSize
						else root.Host.AbsoluteSize
					local scale = 1
					local ancestor: Instance? = parent
					while ancestor do
						local scaler = ancestor:FindFirstChildWhichIsA("UIScale")
						if scaler then
							scale *= scaler.Scale
						end
						ancestor = ancestor.Parent
					end
					if scale > 0 then
						area /= scale
					end
					-- Offsets are integer-valued. Undoing UIScale can produce
					-- 389.99997 for a 390px viewport; avoid losing an entire pixel.
					local function snap(value: number): number
						local rounded = math.round(value)
						return if math.abs(value - rounded) < 0.001 then rounded else value
					end
					area = Vector2.new(snap(area.X), snap(area.Y))
					local pad = if parent then parent:FindFirstChildWhichIsA("UIPadding") else nil
					if pad then
						area -= Vector2.new(
							pad.PaddingLeft.Offset
								+ pad.PaddingRight.Offset
								+ area.X * (pad.PaddingLeft.Scale + pad.PaddingRight.Scale),
							pad.PaddingTop.Offset
								+ pad.PaddingBottom.Offset
								+ area.Y * (pad.PaddingTop.Scale + pad.PaddingBottom.Scale)
						)
					end
					local box = layout(root, area.X, area.Y)
					if revision == before and root.Alive then
						paint(box, false)
					else
						pending[top(root)] = true
					end
				end)
				if not ok then
					warn(`HTML layout: {tostring(problem)}`)
				end
			end
			if next(pending) then
				task.wait()
			end
		end
		running = false
	end)
end
-- Class
local Host = {}
function Host.attach(host: GuiObject, input: Input): (() -> Input, (Input) -> (), () -> ())
	local entry: Entry = { Host = host, Input = input, Fragments = {}, Connections = {}, Alive = true }
	entries[host] = entry
	local function changed()
		enqueue(entry)
	end
	local parentConnection: RBXScriptConnection? = nil
	local parentSizeConnection: RBXScriptConnection? = nil
	local function bindParent()
		if parentConnection then
			parentConnection:Disconnect()
			parentConnection = nil
		end
		if parentSizeConnection then
			parentSizeConnection:Disconnect()
			parentSizeConnection = nil
		end
		local parent = host.Parent
		if parent and parent:IsA("GuiBase2d") then
			parentConnection = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(changed)
		end
		if parent and parent:IsA("GuiObject") then
			-- AbsoluteSize can be evaluated lazily for an occluded Studio GUI.
			-- A native parent resize must invalidate flow without a repaint first.
			parentSizeConnection = parent:GetPropertyChangedSignal("Size"):Connect(changed)
		end
	end
	local function watchLayout(child: Instance)
		if child:IsA("UIListLayout") then
			table.insert(entry.Connections, child:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(changed))
		end
	end
	for _, property in { "AbsoluteSize", "Visible", "LayoutOrder" } do
		table.insert(entry.Connections, host:GetPropertyChangedSignal(property):Connect(changed))
	end
	table.insert(
		entry.Connections,
		host.AncestryChanged:Connect(function()
			bindParent()
			changed()
		end)
	)
	table.insert(
		entry.Connections,
		host.ChildAdded:Connect(function(child)
			watchLayout(child)
			if child:IsA("GuiObject") and child.Name ~= "HTMLInlineFragment" then
				changed()
			end
		end)
	)
	table.insert(
		entry.Connections,
		host.ChildRemoved:Connect(function(child)
			if child:IsA("GuiObject") and child.Name ~= "HTMLInlineFragment" then
				changed()
			end
		end)
	)
	if host:IsA("TextLabel") or host:IsA("TextButton") then
		for _, property in { "Text", "FontFace", "TextSize", "TextColor3", "TextScaled" } do
			table.insert(entry.Connections, host:GetPropertyChangedSignal(property):Connect(changed))
		end
	end
	bindParent()
	for _, child in host:GetChildren() do
		watchLayout(child)
	end
	enqueue(entry)
	return function()
		return entry.Input
	end, function(nextInput)
		entry.Input = nextInput
		enqueue(entry)
	end, function()
		local owner = top(entry)
		entry.Alive = false
		entries[host] = nil
		pending[entry] = nil
		if parentConnection then
			parentConnection:Disconnect()
		end
		if parentSizeConnection then
			parentSizeConnection:Disconnect()
		end
		for _, connection in entry.Connections do
			connection:Disconnect()
		end
		for _, fragment in entry.Fragments do
			fragment:Destroy()
		end
		if owner ~= entry then
			enqueue(owner)
		end
	end
end
return Host
