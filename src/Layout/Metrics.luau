--!strict
-- Packages
-- Modules
local Types = require(script.Parent.Parent.Types)
local Values = require(script.Parent.Parent.CSS.Values)
-- Types
-- Constants
local FONT_METRICS = {
	SansSerif = { Height = 1.257, Ascent = 0.984, XHeight = 0.486 },
	Serif = { Height = 1.257, Ascent = 0.984, XHeight = 0.555 },
	Monospace = { Height = 2701 / 2048, Ascent = 2146 / 2048, XHeight = 1082 / 2048 },
}
-- References
-- Global Variables
-- Private Functions
-- Class
local Metrics = {}
function Metrics.length(value: Types.Length?, basis: number, fallback: number): number
	local dimension = if value ~= nil then Values.length(value) else nil
	return if dimension then dimension.Scale * basis + dimension.Offset else fallback
end

function Metrics.text(style: Types.Style, textSize: number?): (number, number, number, number)
	local metric = FONT_METRICS[style.FontFamily or "SansSerif"]
	local size = textSize or math.round((style.FontSize or 16) * metric.Height)
	local em = size / metric.Height
	local value = style.LineHeight
	local line = if type(value) == "number"
		then value * (style.FontSize or 16)
		elseif value and value ~= "Normal" then Metrics.length(value, style.FontSize or 16, size)
		else size
	return size, line, em * metric.Ascent, em * metric.XHeight
end
return Metrics
