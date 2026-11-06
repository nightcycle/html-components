--!strict
-- Services
-- Packages
local React = require(script.Parent.Parent.Parent.Parent.React)
-- Modules
local StyleStore = require(script.Parent.Parent.Context.StyleStore)
-- Components
-- Hooks
-- Contexts
local StyleContext = require(script.Parent.Parent.Context.Style)
-- Types
local Types = require(script.Parent.Parent.Parent.Types)
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(input: StyleStore.Input): (Types.Style, StyleStore.Scope)
	local parent = React.useContext(StyleContext)
	local scope = React.useMemo(function()
		return StyleStore.create(parent, input)
	end, { parent })
	local _, setRevision = React.useState(0)
	local style = scope.Preview(input)
	local rendered = React.useRef(style)
	-- Publish only committed inputs. An interrupted render must never change
	-- another component's style or install a subscription.
	React.useLayoutEffect(function()
		rendered.current = style
		scope.Update(input)
	end)
	React.useLayoutEffect(function()
		local function check()
			if not StyleStore.equal(scope.GetSnapshot().Style, rendered.current) then
				setRevision(function(revision: number): number
					return revision + 1
				end)
			end
		end
		local unsubscribe = scope.SubscribeStyle(check)
		local disconnect = scope.Connect()
		check()
		return function()
			unsubscribe()
			disconnect()
		end
	end, { scope })
	return style, scope
end
