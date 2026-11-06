--!strict
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local Host = require(script.Parent.Parent.Parent.Layout.Host)
-- Components
-- Contexts
-- Hooks
-- Types
type Connection = { Update: (Host.Input) -> (), Disconnect: () -> () }
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(input: Host.Input, forwarded: React.Ref<GuiObject>?): (GuiObject?) -> ()
	local instance = React.useRef(nil :: GuiObject?)
	local connection = React.useRef(nil :: Connection?)
	local setRef = React.useMemo(function()
		return function(value: GuiObject?)
			instance.current = value
			if type(forwarded) == "function" then
				forwarded(value)
			elseif forwarded then
				forwarded.current = value
			end
		end
	end, { forwarded })
	React.useLayoutEffect(function(): (() -> ())?
		local host = instance.current
		if not host then
			return nil
		end
		local _, update, disconnect = Host.attach(host, input)
		connection.current = { Update = update, Disconnect = disconnect }
		return function()
			disconnect()
			connection.current = nil
		end
	end, {})
	React.useLayoutEffect(function()
		if connection.current then
			connection.current.Update(input)
		end
	end)
	return setRef
end
