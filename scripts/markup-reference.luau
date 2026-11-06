--!strict
-- Packages
local fs = require("@lune/fs")
-- Modules
local Fixtures = require("../tests/visual/MarkupFixtures")
-- Types
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
local panes: { string } = {}
for row, width in Fixtures.Widths do
	for column, mode in Fixtures.Modes do
		table.insert(
			panes,
			`<section class="Pane" id="Pane{row}{column}" style="left:{20 + (column - 1) * 328}px;top:{56 + (row - 1) * 344}px;width:{width}px"><header>{mode} / {width}px</header><div id="Card" class="Card">{Fixtures.Markup}</div></section>`
		)
	end
end
fs.writeDir("build/visual")
fs.writeFile(
	"build/visual/markup.html",
	[[<!doctype html><meta charset="utf-8"><title>Markup, table and React comparison</title><style>
@font-face {font-family:ReferenceSans;src:url(fonts/SourceSansPro-Regular.ttf);}
@font-face {font-family:ReferenceSans;src:url(fonts/SourceSansPro-Bold.ttf);font-weight:700;}
@font-face {font-family:ReferenceSans;src:url(fonts/SourceSansPro-It.ttf);font-style:italic;}
* {box-sizing:border-box;margin:0;padding:0;border:0 solid;}
body {width:1008px;height:744px;background:#e2e9f4;color:#182033;font:16px/24px ReferenceSans;}
.Pane {position:absolute;height:300px;}
header {position:absolute;top:-30px;}
mark {color:inherit;}
]]
		.. Fixtures.CSS
		.. "</style>"
		.. table.concat(panes)
)
print("Wrote build/visual/markup.html from the shared markup fixtures.")
