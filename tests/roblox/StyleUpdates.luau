--!strict
local storage = script.Parent.Parent
local HTML = require(storage.Packages.HTMLComponents)
local React = require(storage.Packages.React)
local ReactRoblox = require(storage.DevPackages.ReactRoblox)
local e = React.createElement

return function(): string
	local target = Instance.new("Folder")
	local root = ReactRoblox.createRoot(target)
	local renders: { [string]: number } = {}
	local commits: { [string]: number } = {}
	-- React 17 concurrent roots enable StrictMode, which invokes render twice in
	-- development while committing one update. Keep both counts explicit.
	local passes = if _G.__DEV__ then 2 else 1
	local function record(name: string)
		renders[name] = (renders[name] or 0) + 1
		React.useLayoutEffect(function()
			commits[name] = (commits[name] or 0) + 1
		end)
	end
	-- Invoke the production component in the counted fiber so its hook updates
	-- count actual renders, rather than renders of an unsubscribed wrapper.
	local function text(props: HTML.PProperties): React.ReactNode
		local name = props.Name or ""
		record(name)
		return HTML.P(props)
	end
	local function panel(props: HTML.DivProperties): React.ReactNode
		local name = props.Name or ""
		record(name)
		return HTML.Div(props)
	end
	local children = {
		Panel = e(panel, { Name = "Panel", ClassName = "panel" }, {
			Match = e(text, { Name = "Match", ClassName = "target", Text = "Matching class" }),
			Inherited = e(text, { Name = "Inherited", Text = "Inherited typography" }),
			Fixed = e(text, { Name = "Fixed", CSS = { Color = "purple" }, Text = "Inline override" }),
			Nested = e(HTML.StyleProvider, { CSS = { [".nested"] = { Color = "green" } } }, {
				Text = e(text, { Name = "Nested", ClassName = "nested", Text = "Nested override" }),
			}),
		}),
		Other = e(text, { Name = "Other", ClassName = "other", Text = "Independent branch" }),
	}
	local function render(css: HTML.StyleMap)
		table.clear(renders)
		table.clear(commits)
		ReactRoblox.act(function()
			root:render(e(HTML.StyleProvider, { CSS = css }, children))
		end)
	end
	local function expect(name: string, count: number)
		assert(
			(renders[name] or 0) == count * passes,
			`{name}: expected {count * passes} render invocations, got {renders[name] or 0}`
		)
		assert((commits[name] or 0) == count, `{name}: expected {count} commits, got {commits[name] or 0}`)
	end
	local ok, problem = pcall(function()
		render({ [".panel"] = { Color = "red" }, [".target"] = { BackgroundColor = "red" } })
		local match = target:FindFirstChild("Match", true) :: TextLabel
		local inherited = target:FindFirstChild("Inherited", true) :: TextLabel
		local fixed = target:FindFirstChild("Fixed", true) :: TextLabel
		local nested = target:FindFirstChild("Nested", true) :: TextLabel
		assert(match.TextColor3 == Color3.fromRGB(255, 0, 0), "Initial inheritance")
		render({ [".panel"] = { Color = "red" }, [".target"] = { BackgroundColor = "blue" } })
		expect("Match", 1)
		for _, name in { "Panel", "Inherited", "Fixed", "Nested", "Other" } do
			expect(name, 0)
		end
		assert(match.BackgroundColor3 == Color3.fromRGB(0, 0, 255), "Matching host changed")
		render({
			[".panel"] = { Color = "red" },
			[".target"] = { BackgroundColor = "blue" },
			[".unused"] = { FontSize = 32 },
		})
		assert(next(renders) == nil, "Unmatched rules must not render components")
		render({
			[".unused"] = { FontSize = 32 },
			[".target"] = { BackgroundColor = "blue" },
			[".panel"] = { Color = "red" },
		})
		assert(next(renders) == nil, "Equivalent CSS must not render components")
		render({ [".panel"] = { Color = "blue" }, [".target"] = { BackgroundColor = "blue" } })
		for _, name in { "Panel", "Match", "Inherited" } do
			expect(name, 1)
		end
		for _, name in { "Fixed", "Nested", "Other" } do
			expect(name, 0)
		end
		assert(inherited.TextColor3 == Color3.fromRGB(0, 0, 255), "Changed inheritance")
		assert(fixed.TextColor3 == Color3.fromRGB(128, 0, 128), "Inline override retained")
		assert(nested.TextColor3 == Color3.fromRGB(0, 128, 0), "Nested override retained")
		render({ [".panel"] = { Color = "blue", BackgroundColor = "red" }, [".target"] = { BackgroundColor = "blue" } })
		expect("Panel", 1)
		for _, name in { "Match", "Inherited", "Fixed", "Nested", "Other" } do
			expect(name, 0)
		end
		assert(target:FindFirstChild("Match", true) == match, "Updates must preserve host identity")
		local reports: { { HTML.Diagnostic } } = {}
		local function receive(diagnostics: { HTML.Diagnostic })
			table.insert(reports, diagnostics)
		end
		local properties: HTML.StyleProviderProperties = {
			StyleSheet = HTML.CSS.parse("p { unknown-property: 1; color:red }"),
			CSS = { ["Button:Unsupported"] = { Color = "blue" } },
			OnDiagnostics = receive,
		}
		local function renderDiagnostics(props: HTML.StyleProviderProperties)
			ReactRoblox.act(function()
				root:render(e(HTML.StyleProvider, props))
			end)
		end
		renderDiagnostics(properties)
		assert(#reports == 1 and #reports[1] == 2, "Callback receives both map and stylesheet diagnostics")
		assert(reports[1][2].Source == "unknown-property: 1", "Callback preserves full diagnostic source")
		renderDiagnostics(properties)
		assert(#reports == 1, "Unchanged inputs do not repeat diagnostic delivery")
		renderDiagnostics({ OnDiagnostics = receive })
		assert(#reports == 2 and #reports[2] == 0, "Clearing styles clears diagnostics")
		local replacementCalls = 0
		renderDiagnostics({
			OnDiagnostics = function(diagnostics: { HTML.Diagnostic })
				replacementCalls += 1
				assert(#diagnostics == 0, "Replacement callback receives current diagnostics")
			end,
		})
		assert(replacementCalls == 1, "Callback replacement is observed")
	end)
	ReactRoblox.act(function()
		root:unmount()
	end)
	assert(#target:GetChildren() == 0, "Style update test leaked instances")
	target:Destroy()
	assert(ok, tostring(problem))
	return "React render counts passed: class updates render only matches, inherited changes respect overrides, equivalent CSS and unmatched rules render nothing."
end
