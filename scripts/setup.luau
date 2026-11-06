--!strict
local fs = require("@lune/fs")
local net = require("@lune/net")
local run = require("./shared/run")
run("lune", { "setup" })
run("wally", { "install" })
run("rojo", { "sourcemap", "dev.project.json", "--output", "sourcemap.json" })
run("wally-package-types", { "--sourcemap", "sourcemap.json", "Packages", "DevPackages" })
local revision = "bd4a2ab3a78df82569fb7c2c8fa63d222b4346e0"
local path = `.tools/globalTypes-{revision}.d.luau`
if not fs.isFile(path) then
	local response =
		net.request(`https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{revision}/scripts/globalTypes.d.luau`)
	assert(response.ok, "Could not download pinned Roblox definitions")
	fs.writeDir(".tools")
	fs.writeFile(path, response.body)
end
