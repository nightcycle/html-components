--!strict
-- Packages
local React = require(script.Parent.Parent.React)
-- Types
type Properties = { Children: React.ReactNode? }
-- Class
-- React inserts its reserved lowercase children key when createElement receives
-- a third argument. Keep that adaptation outside the public property types.
return function(props: Properties): React.ReactNode?
	local record = (props :: unknown) :: { [string]: React.ReactNode }
	if record.children ~= nil then
		return record.children
	end
	return props.Children
end
