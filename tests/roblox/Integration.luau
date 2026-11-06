--!strict
local Packages = script.Parent.Parent.Packages
local HTML = require(Packages.HTMLComponents)
local React = require(Packages.React)
local ReactRoblox = require(script.Parent.Parent.DevPackages.ReactRoblox)
local e = React.createElement

return function(): string
	local container = Instance.new("Folder")
	local root = ReactRoblox.createRoot(container)
	local ref = React.createRef()
	local components = (HTML.Tags :: unknown) :: { [string]: React.ElementType }
	local ok, problem = pcall(function()
		for _, entry in HTML.Catalog do
			ReactRoblox.act(function()
				root:render(e(components[entry.Tag], { Name = "Sample", Text = "<safe & text>", Ref = ref }))
			end)
			local host = assert(container:FindFirstChild("Sample"), `Missing host for {entry.Tag}`)
			assert(host:IsA("GuiObject"), entry.Tag)
			assert(ref.current == host, `Ref did not reach {entry.Tag}`)
		end
		local function render(css: string, disabled: boolean?)
			ReactRoblox.act(function()
				root:render(e(HTML.StyleProvider, { CSS = css }, {
					Panel = e(
						HTML.Div,
						{
							Id = "panel",
							Css = {
								Padding = 12,
								BorderRadius = 10,
								BorderTopRightRadius = 2,
								BoxShadow = "0px 4px 8px #00000040",
							},
						} :: HTML.ContainerProperties,
						{
							Title = e(
								HTML.P,
								{ Id = "title", Text = "Inherited", Ref = ref, Size = UDim2.fromOffset(240, 40) } :: HTML.TextProperties
							),
							Button = e(
								HTML.Button,
								{ Id = "button", Text = "Action", Disabled = disabled } :: HTML.ButtonProperties
							),
						}
					),
				}))
			end)
		end
		render("#panel { color: #ff0000; } #panel > p { font-size: 24px; }")
		local panel = container:FindFirstChild("panel") :: Frame
		local title = panel:FindFirstChild("title") :: TextLabel
		assert(title.TextColor3 == Color3.fromRGB(255, 0, 0) and math.abs(title.TextSize - 24 * 1.257) <= 0.5)
		assert(title.Size == UDim2.fromOffset(240, 40) and ref.current == title)
		local corner = panel:FindFirstChildWhichIsA("UICorner") :: UICorner
		assert(corner.TopLeftRadius.Offset == 10 and corner.TopRightRadius.Offset == 2)
		assert(panel:FindFirstChildWhichIsA("UIShadow"), "Native shadow missing")
		render("#panel { color: #0000ff; } button:disabled { background-color: #555555; }", true)
		assert(title.TextColor3 == Color3.fromRGB(0, 0, 255), "Context update did not propagate")
		local button = panel:FindFirstChild("button") :: TextButton
		assert(not button.Interactable and button.BackgroundColor3 == Color3.fromRGB(85, 85, 85))
		ReactRoblox.act(function()
			root:render(e(HTML.Progress, { Value = 250, Min = 0, Max = 100, Name = "Meter" } :: HTML.MeterProperties))
		end)
		local meter = container:FindFirstChild("Meter") :: Frame
		assert((meter:FindFirstChild("Fill") :: Frame).Size.X.Scale == 1)
		ReactRoblox.act(function()
			root:render(e(HTML.Input, { Name = "Input", Value = "controlled" } :: HTML.InputProperties))
		end)
		local input = container:FindFirstChild("Input") :: TextBox
		assert(input.TextYAlignment == Enum.TextYAlignment.Center, "Single-line input should center text")
		ReactRoblox.act(function()
			input.Text = "edit"
		end)
		assert(input.Text == "controlled", "Controlled text must be restored when caller rejects edits")
		local nestedChildren: React.ReactNode =
			e(HTML.Button, { Name = "NestedButton", Text = "Typed children" } :: HTML.ButtonProperties)
		local parentProperties: HTML.DivProperties = { Name = "ChildrenContainer", Children = nestedChildren }
		ReactRoblox.act(function()
			root:render(e(
				HTML.StyleProvider,
				{
					CSS = "button { color: #ff0000; }",
					Children = e(HTML.Div, parentProperties),
				} :: HTML.StyleProviderProperties
			))
		end)
		local nestedButton = container:FindFirstChild("NestedButton", true) :: TextButton
		assert(
			nestedButton and nestedButton.TextColor3 == Color3.fromRGB(255, 0, 0),
			"PascalCase Children must preserve context"
		)
		assert(nestedButton.TextYAlignment == Enum.TextYAlignment.Center, "Buttons should center text")
		ReactRoblox.act(function()
			root:render(
				e(
					HTML.Input,
					{ Name = "NativeOverride", TextSize = 18, TextYAlignment = Enum.TextYAlignment.Bottom } :: HTML.InputProperties
				)
			)
		end)
		local nativeInput = container:FindFirstChild("NativeOverride") :: TextBox
		assert(
			nativeInput.TextSize == 18 and nativeInput.TextYAlignment == Enum.TextYAlignment.Bottom,
			"Native typography overrides CSS"
		)
	end)
	ReactRoblox.act(function()
		root:unmount()
	end)
	assert(#container:GetChildren() == 0 and ref.current == nil, "Unmount leaked instances or refs")
	container:Destroy()
	assert(ok, tostring(problem))
	return `Mounted {#HTML.Catalog} tags; cascade, context updates, refs, root props, corners, shadows, disabled state, controlled input, meters and cleanup passed.`
end
