--!strict
-- Packages
-- Modules
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

local function insets(style: Types.Style, basis: number, margin: boolean): Flow.Insets
	if margin then
		return {
			Top = Metrics.length(style.MarginTop or style.Margin, basis, 0),
			Right = Metrics.length(style.MarginRight or style.Margin, basis, 0),
			Bottom = Metrics.length(style.MarginBottom or style.Margin, basis, 0),
			Left = Metrics.length(style.MarginLeft or style.Margin, basis, 0),
		}
	end
	if style.Display == "Inline" then
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
	local family = if style.FontFamily == "Monospace"
		then "RobotoMono"
		elseif style.FontFamily == "Serif" then "Merriweather"
		else "SourceSansPro"
	return Font.new(
		`rbxasset://fonts/families/{family}.json`,
		if style.FontWeight == "Bold" then Enum.FontWeight.Bold else Enum.FontWeight.Regular,
		if style.FontStyle == "Italic" then Enum.FontStyle.Italic else Enum.FontStyle.Normal
	),
		Metrics.text(style)
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
	if host:IsA("TextLabel") then
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
	if style.Width and style.Width ~= "auto" then
		return Metrics.length(style.Width, available, 0)
	end
	local own = text(entry)
	local width, line = 0, 0
	if own then
		for value in own:gmatch("[^\n]+") do
			width = math.max(width, measure(entry, value))
		end
		line = width
	end
	for _, child in children(entry) do
		local value = intrinsic(child, available)
		local margin = insets(child.Input.Style, available, true)
		value += margin.Left + margin.Right
		if display(child) == "Block" or display(child) == "Flex" or child.Input.Tag == "Br" then
			width, line = math.max(width, line, value), 0
		else
			line += value
		end
	end
	local padding = insets(style, available, false)
	return math.max(width, line) + padding.Left + padding.Right
end

local function layout(entry: Entry, available: number, parentHeight: number): Box
	local style, native = entry.Input.Style, entry.Input.Size
	local mode = display(entry)
	local margin = insets(style, available, true)
	local width = Metrics.length(
		style.Width,
		available,
		if mode == "InlineBlock"
				or mode == "InlineFlex"
				or style.Width == "auto"
			then math.min(available, intrinsic(entry, available))
			else available - margin.Left - margin.Right
	)
	if native then
		width = native.X.Scale * available + native.X.Offset
	end
	width = math.clamp(width, style.MinWidth or 0, math.max(style.MinWidth or 0, style.MaxWidth or math.huge))
	local padding = insets(style, width, false)
	local contentWidth = math.max(0, width - padding.Left - padding.Right)
	local _, size = font(entry)
	local glyphHeight, lineHeight, baseline, xHeight = Metrics.text(style, size)
	local box: Box = { Entry = entry, X = 0, Y = 0, Width = width, Height = 0, Baseline = 0, Children = {}, Text = {} }
	local height = 0
	if not entry.Input.Layout or flex(entry) then
		-- Flex continues to use native UIListLayout; controls retain native text rendering.
		for _, child in children(entry) do
			table.insert(box.Children, layout(child, contentWidth, entry.Host.AbsoluteSize.Y))
		end
		local list = entry.Host:FindFirstChildWhichIsA("UIListLayout")
		height = if list then list.AbsoluteContentSize.Y else entry.Host.AbsoluteSize.Y - padding.Top - padding.Bottom
		if height <= 0 then
			height = glyphHeight
		end
	else
		local items: { Flow.Item } = {}
		local owners: { Box } = {}
		local inline: { [Box]: boolean } = {}
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
				local childMode: Types.Display = display(child)
				local isInline = childMode == "Inline" and child.Input.Layout
				local childBox: Box = if isInline
					then { Entry = child, X = 0, Y = 0, Width = 0, Height = 0, Baseline = 0, Children = {}, Text = {} }
					else layout(child, contentWidth, parentHeight)
				table.insert(parent.Children, childBox)
				parents[childBox] = parent
				if isInline then
					inline[childBox] = true
					collect(childBox)
				else
					table.insert(items, {
						Display = childMode,
						Width = childBox.Width,
						Height = childBox.Height,
						Baseline = childBox.Baseline,
						LineHeight = childBox.Height,
						Margin = margins(child.Input.Style, contentWidth, childBox.Width),
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
	end
	height += padding.Top + padding.Bottom
	if style.Height and style.Height ~= "auto" then
		height = Metrics.length(style.Height, parentHeight, height)
	end
	if native then
		local automatic = entry.Input.AutomaticSize
		if automatic ~= Enum.AutomaticSize.Y and automatic ~= Enum.AutomaticSize.XY then
			height = native.Y.Scale * parentHeight + native.Y.Offset
		end
	end
	box.Height = math.clamp(height, style.MinHeight or 0, math.max(style.MinHeight or 0, style.MaxHeight or math.huge))
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
	local managedText = host:IsA("TextLabel") and entry.Input.Layout and not flex(entry) and not host.TextScaled
	local inline = display(entry) == "Inline" and entry.Input.Layout
	host.BackgroundTransparency = if inline then 1 else entry.Input.BackgroundTransparency or 1
	if managedText and host:IsA("TextLabel") then
		host.TextTransparency, host.TextStrokeTransparency = 1, 1
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
			local decoration = entry.Input.Style.TextDecoration
			if decoration == "Underline" or decoration == "LineThrough" then
				local escaped = label.Text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
				local tag = if decoration == "Underline" then "u" else "s"
				label.Text, label.RichText = `<{tag}>{escaped}</{tag}>`, true
			end
		end
	end
	for index = #entry.Fragments, (if managedText then #box.Text else 0) + 1, -1 do
		entry.Fragments[index]:Destroy()
		table.remove(entry.Fragments, index)
	end
	if not managedText and host:IsA("TextLabel") then
		host.TextTransparency = entry.Input.TextTransparency or 0
		host.TextStrokeTransparency = entry.Input.TextStrokeTransparency or 1
	end
	for _, child in box.Children do
		paint(child, entry.Input.Layout and not flex(entry))
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
	local function bindParent()
		if parentConnection then
			parentConnection:Disconnect()
			parentConnection = nil
		end
		local parent = host.Parent
		if parent and parent:IsA("GuiBase2d") then
			parentConnection = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(changed)
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
	if host:IsA("TextLabel") then
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
