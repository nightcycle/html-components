--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("./Datatypes")
-- A small module loader runs the unchanged production CSS implementation in Lune.
-- `any` is confined to the dynamic module-loader boundary, as in require itself.
return function(): (string) -> any
	local cache: { [string]: any } = { React = {}, RobloxComponents = {} }
	local compiled: { [string]: () -> any } = {}
	local function load(name: string): any
		if cache[name] then
			return cache[name]
		end
		local result = assert(compiled[name], `Missing module {name}`)()
		cache[name] = result
		return result
	end
	for _, path in
		{
			"src/Tag.luau",
			"src/Types.luau",
			"src/Layout/Flow.luau",
			"src/CSS/init.luau",
			"src/CSS/Values.luau",
			"src/CSS/Selector.luau",
			"src/CSS/Escape.luau",
			"src/CSS/Variables.luau",
			"src/CSS/Calculation.luau",
			"src/React/Context/StyleStore.luau",
			"src/React/Render/Decoration.luau",
			"src/Markup/init.luau",
			"src/Markup/Entities.luau",
			"src/Markup/Tags.luau",
			"src/Document/init.luau",
			"src/Document/Names.luau",
			"src/Document/SourceText.luau",
			"src/Document/Entities.luau",
			"src/Document/NamedEntities.luau",
			"src/Document/Tokenizer.luau",
		}
	do
		local name = path:gsub("/init%.luau$", ""):gsub("%.luau$", "")
		local source = fs.readFile(path):gsub("require%((script[%w%.]*)%)", function(expression: string): string
			local parts = string.split(name, "/")
			for index, member in string.split(expression, ".") do
				if index == 1 then
					continue
				end
				if member == "Parent" then
					table.remove(parts)
				else
					table.insert(parts, member)
				end
			end
			return string.format("require(%q)", table.concat(parts, "/"))
		end)
		compiled[name] = luau.load(source, {
			environment = { require = load, Color3 = roblox.Color3, UDim = roblox.UDim, UDim2 = roblox.UDim2 },
			injectGlobals = true,
			debugName = path,
		})
	end
	return load
end
