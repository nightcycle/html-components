--!strict
-- Packages
-- Modules
-- Types
-- Constants
local MARKUP =
	[[<p id="Copy">Read <strong id="Strong" class="Accent">bold <em id="Em">nested italic</em></strong> &amp; <u id="Underline">underlined <s id="Both">and struck</s></u> text.<br/><span id="Literal">&lt;strong&gt;literal&lt;/strong&gt;</span> <mark id="Mark">highlighted words</mark></p><p id="Boxes">A <strong id="Badge" class="Badge" style="width:88px">BADGE</strong> next to <em id="Sized" class="Sized">sized text</em> stays independent.</p>]]
local CSS = [[
.Card { padding:16px; background-color:white; border-width:1px; border-color:#cbd5e1; font-size:16px; line-height:24px; color:#182033; }
#Copy { margin-bottom:20px; }
.Accent { color:#315fe8; }
.Badge { display:inline-block; height:42px; padding:8px; background-color:#dbeafe; text-align:center; border-radius:6px; vertical-align:middle; }
.Sized { display:inline-block; width:104px; height:56px; padding:8px; font-size:18px; background-color:#f3e8ff; vertical-align:bottom; }
mark { background-color:#fff1a6; }
]]
-- References
-- Global Variables
-- Private Functions
-- Class
return { Markup = MARKUP, CSS = CSS, Widths = { 300, 220 }, Modes = { "Markup", "Table", "React" } }
