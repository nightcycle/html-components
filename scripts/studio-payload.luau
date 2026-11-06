--!strict
-- Export a detached test tree; no HTTP, uploads, or changes to the open place.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local place = roblox.deserializePlace(fs.readFile("build/html-components-demo.rbxl"))
type Record = { Id: number, Parent: number, Name: string, Source: string? }
local records: { Record } = {}
local function visit(instance: roblox.Instance, parent: number, depth: number)
	local source: string? = nil
	if instance:IsA("ModuleScript") then
		source = ((instance :: unknown) :: { Source: string }).Source:gsub(
			"game%.ReplicatedStorage%.Packages",
			"script" .. string.rep(".Parent", depth) .. ".Packages"
		)
		source = assert(source):gsub('game:GetService%("ReplicatedStorage"%)', "script" .. string.rep(".Parent", depth))
	end
	local id = #records + 1
	table.insert(records, { Id = id, Parent = parent, Name = instance.Name, Source = source })
	for _, child in instance:GetChildren() do
		visit(child, id, depth + 1)
	end
end
local storage = assert(place:FindFirstChild("ReplicatedStorage"))
for _, name in { "Packages", "DevPackages", "Stories", "Demo", "Tests" } do
	visit(assert(storage:FindFirstChild(name)), 0, 1)
end
fs.writeDir(".tools/studio")
local batches, batch, size = 0, {} :: { Record }, 0
local function flush()
	if #batch == 0 then
		return
	end
	batches += 1
	fs.writeFile(`.tools/studio/{batches}.json`, serde.encode("json", batch))
	batch, size = {}, 0
end
for _, record in records do
	local bytes = #(record.Source or "")
	if size + bytes > 120000 then
		flush()
	end
	table.insert(batch, record)
	size += bytes
end
flush()
print(`Exported {#records} detached instances in {batches} batches.`)
