--!strict
-- Services
-- Packages
local HTML = require(script.Parent.Parent.Packages.HTMLComponents)
local React = require(script.Parent.Parent.Packages.React)
local ReactRoblox = require(script.Parent.Parent.DevPackages.ReactRoblox)
local UILabs = require(script.Parent.Parent.DevPackages.UILabs)
-- Modules
-- Components
local Preview = require(script.Parent.Preview)
-- Hooks
-- Contexts
-- Types
type SliderControl = typeof(UILabs.Slider(0, 0, 1, 0.01))
type Controls = {
	Dark: boolean,
	Text: string?,
	Placeholder: string?,
	Disabled: boolean?,
	Value: SliderControl?,
	Radius: SliderControl?,
}
-- Constants
local kinds: { [string]: string } = {}
for _, entry in HTML.Catalog do
	kinds[entry.Tag] = entry.Kind
end
-- Variables
-- References
-- Private Functions
-- Class
return function(tag: string)
	local kind = assert(kinds[tag], `Unknown story tag {tag}`)
	local controls: Controls = { Dark = false }
	if kind == "Text" or kind == "Button" then
		controls.Text = if tag == "Pre" then "local greeting = 'Hello'\nprint(greeting)" else "Hello from HTML"
	end
	if kind == "Button" or kind == "Input" then
		controls.Disabled = false
	end
	if kind == "Input" then
		controls.Placeholder = "Type here…"
	end
	if kind == "Meter" then
		controls.Value = UILabs.Slider(0.65, 0, 1, 0.01)
	end
	if kind ~= "Spacer" then
		controls.Radius = UILabs.Slider(8, 0, 32, 1)
	end

	return UILabs.CreateReactStory({
		react = React,
		reactRoblox = ReactRoblox,
		controls = controls,
	}, function(props)
		return React.createElement(
			Preview,
			{
				Tag = tag,
				Text = props.controls.Text,
				Placeholder = props.controls.Placeholder,
				Disabled = props.controls.Disabled,
				Dark = props.controls.Dark,
				Value = props.controls.Value,
				Radius = props.controls.Radius,
				Inset = 24,
			} :: Preview.Properties
		)
	end)
end
