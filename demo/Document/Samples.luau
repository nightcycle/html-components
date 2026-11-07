--!strict
-- Packages
-- Modules
-- Types
export type Asset = { Width: number, Height: number, Data: string }
export type Sample = { Name: string, HTML: string, Stylesheets: { [string]: string }, Assets: { [string]: Asset }? }
-- Constants
local EXAMPLE: Sample = {
	Name = "Example document",
	HTML = [[<!doctype html>
<html><head><title>Document preview</title><link rel="stylesheet" href="preview.css"></head>
<body><main class="Card">
<span class="Eyebrow">HTML + CSS / REACT LUAU</span>
<h1 id="Heading">A document, brought to life.</h1>
<p>Real HTML becomes <strong>native Roblox UI</strong>, with <em>mixed text</em> and styles from a linked CSS file.</p>
<div class="Callout"><h2>Keep every element.</h2><p>Headings, paragraphs, buttons, and inline formatting retain their structure.</p></div>
<button class="Action">A native button</button>
<p class="Footnote">Explore Structure and Diagnostics to see what was imported.</p>
</main></body></html>]],
	Stylesheets = {
		["preview.css"] = [[
body { margin: 0px; color: #22304a; font-size: 18px; font-family: sans-serif; }
.Card { padding: 28px; gap: 18px; background-color: #f4f6ff; border-radius: 18px; }
.Eyebrow { color: #6552d8; font-size: 13px; font-weight: bold; }
h1 { margin: 0px; margin-bottom: 14px; font-size: 34px; color: #18213b; }
h2 { margin: 0px; margin-bottom: 8px; font-size: 22px; }
p { margin: 0px; line-height: 1.5; }
.Callout { padding: 20px; margin-top: 18px; margin-bottom: 18px; background-color: #e5eaff; border-radius: 12px; }
.Action { width: 210px; height: 44px; background-color: #6552d8; color: white; border-radius: 8px; }
.Footnote { margin-top: 12px; color: #5a6880; font-size: 14px; }
]],
	},
}
-- References
-- Global Variables
-- Private Functions
-- Class
return EXAMPLE
