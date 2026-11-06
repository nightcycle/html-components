--!strict
-- Packages
local fs = require("@lune/fs")
-- Modules
local Fixtures = require("../tests/visual/FlowFixtures")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
local function escape(value: string): string
	return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end
local function render(node: Fixtures.Node): string
	local tag = node.Tag:lower()
	if tag == "br" then
		return '<br id="' .. node.Id .. '">'
	end
	local content = escape(node.Text or "")
	local children: { Fixtures.Node } = node.Children or {}
	for _, child in children do
		content ..= render(child)
	end
	return `<{tag} id="{node.Id}">{content}</{tag}>`
end
-- Class
local panes: { string } = {}
for index, width in Fixtures.Widths do
	table.insert(
		panes,
		`<section class="Pane" id="Pane{index}" style="left:{if index == 1 then 24 else 308}px;width:{width}px"><header>{width}px container</header>{render(
			Fixtures.Node
		)}</section>`
	)
end
fs.writeDir("build/visual")
fs.writeFile(
	"build/visual/flow.html",
	[[<!doctype html><meta charset="utf-8"><title>Inline layout comparison</title><style>
@font-face { font-family: ReferenceSans; src:url(fonts/SourceSansPro-Regular.ttf); }
@font-face { font-family: ReferenceSans; src:url(fonts/SourceSansPro-Bold.ttf); font-weight:700; }
@font-face { font-family: ReferenceSans; src:url(fonts/SourceSansPro-It.ttf); font-style:italic; }
* {box-sizing:border-box; margin:0; padding:0; border:0 solid;}
body {width:772px; height:484px; background:#e2e9f4; color:#182033; font:16px/24px ReferenceSans;}
.Pane {position:absolute; top:64px; height:420px;}
header {position:absolute; top:-32px; font-weight:bold;}
]]
		.. Fixtures.CSS
		.. "</style>"
		.. table.concat(panes)
)
print("Wrote build/visual/flow.html from the shared layout fixtures.")
