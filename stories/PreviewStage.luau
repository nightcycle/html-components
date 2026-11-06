--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Packages.React)
local RobloxComponents = require(script.Parent.Parent.Packages.RobloxComponents)
-- Modules
-- Components
-- Hooks
-- Contexts
-- Types
export type Properties = {
	Size: Vector2,
	Inset: number?,
	AspectRatio: number?,
	Children: React.ReactNode?,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(props: Properties)
	local inset = props.Inset or 0
	return React.createElement(RobloxComponents.Frame({
		Name = "PreviewStage",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {}, {
		Bounds = React.createElement(RobloxComponents.UISizeConstraint({ MaxSize = props.Size }, {})),
		Aspect = props.AspectRatio and React.createElement(RobloxComponents.UIAspectRatioConstraint({
			AspectRatio = props.AspectRatio,
			AspectType = Enum.AspectType.FitWithinMaxSize,
		}, {})),
		Content = React.createElement(
			React.Fragment,
			nil,
			((props :: unknown) :: { [string]: React.ReactNode }).children or props.Children
		),
	}))
end
