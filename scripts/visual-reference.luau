--!strict
local Fixtures = require("../tests/visual/Fixtures")
local fs = require("@lune/fs")
local function escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end
local function render(node: Fixtures.Node): string
	local tag = string.lower(node.Tag)
	local attributes = ` id="{node.Id}" data-sample="true"`
	if node.Value then
		attributes ..= ` value="{node.Value}" min="0" max="1"`
	end
	if tag == "input" then
		return `<input{attributes} value="{escape(node.Text or "")}">`
	elseif tag == "img" or tag == "hr" or tag == "br" then
		return `<{tag}{attributes}>`
	end
	local content = escape(node.Text or "")
	local children: { Fixtures.Node } = node.Children or {}
	for _, child in children do
		content ..= render(child)
	end
	return `<{tag}{attributes}>{content}</{tag}>`
end
local cells: { string } = {}
for _, case in Fixtures.Cases do
	table.insert(
		cells,
		`<section class="case"><header>{escape(case.Title)}</header><div class="stage">{render(case.Node)}</div></section>`
	)
end
local source = [=[<!doctype html>
<html lang="en"><meta charset="utf-8"><title>HTML Components — browser reference</title>
<style>
@font-face { font-family: ReferenceSans; src: url(fonts/SourceSansPro-Regular.ttf); }
@font-face { font-family: ReferenceSans; src: url(fonts/SourceSansPro-Bold.ttf); font-weight: 700; }
@font-face { font-family: ReferenceSans; src: url(fonts/SourceSansPro-Semibold.ttf); font-weight: 600; }
* { box-sizing: border-box; margin: 0; padding: 0; border: 0 solid; }
body { background: #e2e9f4; color: #182033; font: 16px/normal ReferenceSans, sans-serif; }
#board { width: 1008px; height: 744px; padding: 28px 20px; display: grid;
grid-template-columns: repeat(3,312px); grid-template-rows: repeat(3,216px); gap: 16px; }
.case { background: white; position: relative; }
.case > header { position: absolute; left: 12px; top: 8px; width: 288px; height: 20px;
font-size: 14px; font-weight: 600; color: #52617c; }
.stage { position: absolute; left: 16px; top: 32px; width: 280px; height: 176px;
display: flex; align-items: center; justify-content: center; }
[data-sample] { flex-shrink: 0; }
article, div[data-sample] { display: flex; flex-direction: column; }
button { width: 100%; height: 38px; background: #315fe8; color: white; padding: 8px;
border-radius: 6px; text-align: center; font: inherit; }
input, textarea { display: block; width: 100%; padding: 8px; border: 1px solid #b4bed1;
background: white; color: inherit; font: inherit; resize: none; }
h2 { font-size: 28px; } h3 { font-size: 24px; } h2, h3 { font-weight: bold; }
p, h2, h3, u { display: block; width: 100%; }
u { text-decoration: underline; }
progress, meter { appearance: none; display: block; width: 100%; border: 0; overflow: hidden; background: #e3e8f2; }
progress::-webkit-progress-bar { background: #e3e8f2; border-radius: inherit; }
progress::-webkit-progress-value { background: #4168e0; border-radius: inherit; }
meter::-webkit-meter-inner-element { display: block; height: 100%; }
meter::-webkit-meter-bar { position: absolute; inset: 0; align-self: stretch; height: 100%;
border: 0; background: #e3e8f2; border-radius: inherit; }
meter::-webkit-meter-optimum-value { height: 100%; background: #4168e0; border-radius: inherit; }
img, video { display: block; }
hr { display: block; width: 100%; height: 1px; background: #b4bed1; }
br { display: block; width: 100%; height: 16px; content: ""; }
#flex { flex-direction: row; }
]=] .. Fixtures.CSS .. '</style><main id="board">' .. table.concat(cells, "\n") .. "</main></html>"
fs.writeDir("build/visual")
fs.writeFile("build/visual/index.html", source)
print("Wrote build/visual/index.html from the shared Studio/browser fixtures.")
