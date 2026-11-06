--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")
local run = require("./shared/run")
run("lune", { "run", "scripts/generate", "--check" })
run("lune", { "run", "tests/run" })
run("lune", { "run", "tests/style-updates" })
run("lune", { "run", "tests/flow" })
run("lune", { "run", "tests/markup" })
run("lune", { "run", "tests/release" })
run("stylua", { "--check", "src", "stories", "demo", "scripts", "tests" })
run("luau-lsp", {
	"analyze",
	"--platform",
	"standard",
	"scripts",
	"tests/run.luau",
	"tests/style-updates.luau",
	"tests/flow.luau",
	"tests/markup.luau",
	"tests/release.luau",
	"tests/load.luau",
	"tests/Datatypes.luau",
})
run("rojo", { "sourcemap", "dev.project.json", "--output", "sourcemap.json" })
local args = {
	"analyze",
	"--platform",
	"roblox",
	"--sourcemap",
	"sourcemap.json",
	"--definitions",
	".tools/globalTypes-bd4a2ab3a78df82569fb7c2c8fa63d222b4346e0.d.luau",
	"--ignore",
	"Packages/**",
	"--ignore",
	"DevPackages/**",
}
local valid = table.clone(args)
for _, path in { "src", "stories", "demo", "tests/roblox" } do
	table.insert(valid, path)
end
run("luau-lsp", valid)
table.insert(args, "tests/type-errors/Invalid.luau")
local result = process.exec("luau-lsp", args)
assert(not result.ok, "Invalid properties unexpectedly typechecked")
local diagnostics = result.stdout .. result.stderr
assert(not diagnostics:find("Unknown require", 1, true), diagnostics)
for lineNumber, line in string.split(fs.readFile("tests/type-errors/Invalid.luau"), "\n") do
	if line:find("EXPECT_ERROR", 1, true) then
		assert(diagnostics:find(`({lineNumber},`, 1, true), `Expected type error on line {lineNumber}:\n{diagnostics}`)
	end
end
print("Strict Roblox analysis, negative type fixtures, formatting and regression checks passed.")
