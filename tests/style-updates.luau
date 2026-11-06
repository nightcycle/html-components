--!strict
local load = require("./load")()
local CSS = load("src/CSS")
local Store = load("src/React/Context/StyleStore")
local count = 0
local function check(condition: boolean, message: string)
	assert(condition, message)
	count += 1
end
local function input(tag: string, classes: { string }, inline: unknown?, hover: boolean?)
	return { Node = { Tag = tag, Classes = classes, Hover = hover }, Inline = inline }
end
local provider = Store.create(nil, {})
local panel = Store.create(provider, input("Div", { "panel" }))
local copy = Store.create(panel, input("P", { "copy" }))
local fixed = Store.create(panel, input("P", { "copy", "fixed" }, { Color = "purple" }))
local other = Store.create(provider, input("P", { "other" }))
local nested = Store.create(panel, { Sheets = { CSS.parse(".copy { color: green; }") } })
local nestedCopy = Store.create(nested, input("P", { "copy" }))
local changes = { Panel = 0, Copy = 0, Fixed = 0, Other = 0, Nested = 0 }
local cleanups: { () -> () } = {}
local subscribers: {
	[string]: { Connect: () -> () -> (), SubscribeStyle: (() -> ()) -> () -> () },
} =
	{ Panel = panel, Copy = copy, Fixed = fixed, Other = other, Nested = nestedCopy }
for name, scope in subscribers do
	table.insert(cleanups, scope.Connect())
	table.insert(
		cleanups,
		scope.SubscribeStyle(function()
			changes[name] += 1
		end)
	)
end
table.insert(cleanups, nested.Connect())
local function reset()
	for name in changes do
		changes[name] = 0
	end
end
local function update(source: string)
	reset()
	provider.Update({ Sheets = { CSS.parse(source) } })
end
update(".panel { background-color: red; }")
check(changes.Panel == 1 and changes.Copy == 0 and changes.Other == 0, "Only matching styles notify React")
update(".panel { background-color: blue; } .missing { color: orange; }")
check(changes.Panel == 1 and changes.Copy == 0 and changes.Fixed == 0, "Background does not inherit")
update(".panel { background-color: blue; } .missing { color: orange; }")
check(changes.Panel == 0 and changes.Copy == 0 and changes.Other == 0, "Equivalent replacement sheets do not notify")
update(".panel { color: red; }")
check(changes.Panel == 1 and changes.Copy == 1 and changes.Other == 0, "Inherited color stays in its branch")
check(changes.Fixed == 0 and changes.Nested == 0, "Inline and nested stylesheet overrides block inherited changes")
check(copy.GetSnapshot().Style.Color == "red", "Inherited color value")
check(table.isfrozen(copy.GetSnapshot().Style), "Resolved snapshots cannot be mutated by renderers")
check(nestedCopy.GetSnapshot().Style.Color == "green", "Nested provider precedence")
update(".panel { color: blue; } .panel:hover > .copy { font-size: 24px; }")
reset()
local hovered = input("Div", { "panel" }, nil, true)
panel.Update(hovered)
check(
	changes.Panel == 0 and changes.Copy == 1 and changes.Fixed == 1,
	"Ancestor hover reaches matching descendants without rendering parent"
)
check(changes.Nested == 1 and changes.Other == 0, "Provider does not break child selectors")
check(copy.GetSnapshot().Style.FontSize == 24, "Ancestor pseudo selector value")
reset()
panel.Update(input("Div", { "panel" }))
check(changes.Copy == 1 and copy.GetSnapshot().Style.FontSize == 16, "Removing ancestor hover restores inherited value")
update(".copy { color: red !important; } .copy.fixed { color: blue !important; }")
check(
	copy.GetSnapshot().Style.Color == "red" and fixed.GetSnapshot().Style.Color == "blue",
	"Compound classes and important cascade"
)
update(".copy { color: red; } .copy { color: blue; }")
check(copy.GetSnapshot().Style.Color == "blue", "Rule source order")
update(".copy { color: blue; } .copy { color: red; }")
check(changes.Copy == 1 and copy.GetSnapshot().Style.Color == "red", "Reordering rules invalidates winning value")
update("")
check(
	copy.GetSnapshot().Style.Color == "#182033" and fixed.GetSnapshot().Style.Color == "purple",
	"Rule removal restores defaults and overrides"
)
reset()
local preview = panel.Preview(input("Div", { "panel" }, { Color = "orange" }))
check(preview.Color == "orange" and changes.Copy == 0, "Uncommitted render does not publish")
check(copy.GetSnapshot().Style.Color == "#182033", "Uncommitted render leaves descendants unchanged")
local contextChanges = 0
local stopContext = panel.Subscribe(function()
	contextChanges += 1
end)
panel.Update(input("Div", { "panel" }, { BackgroundColor = "pink" }))
check(contextChanges == 0 and changes.Copy == 0, "Local non-inherited change stops at the element")
stopContext()
for _, cleanup in cleanups do
	cleanup()
end
update("* { color: yellow; }")
check(changes.Panel == 0 and changes.Copy == 0 and changes.Other == 0, "Unmount removes every subscription")
local reconnect = panel.Connect()
check(panel.GetSnapshot().Style.Color == "yellow", "Reconnect catches changes while unsubscribed")
reconnect()

local large = Store.create(nil, {})
local renders = 0
for index = 1, 500 do
	local scope = Store.create(large, input("P", { `item-{index}` }))
	table.insert(cleanups, scope.Connect())
	table.insert(
		cleanups,
		scope.SubscribeStyle(function()
			renders += 1
		end)
	)
end
large.Update({ Sheets = { CSS.fromMap({ [".item-237"] = { Color = "red" } }) } })
check(renders == 1, "One changed class among 500 subscribers produces one render notification")
large.Update({ Sheets = { CSS.fromMap({ [".item-237"] = { Color = "red" }, [".unmatched"] = { Color = "blue" } }) } })
check(renders == 1, "Unmatched rule produces zero render notifications")
for _, cleanup in cleanups do
	cleanup()
end
print(`{count} style subscription checks passed, including one notification among 500 elements.`)
