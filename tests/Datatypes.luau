--!strict
-- Lune's published typedefs omit its Roblox value constructors. Describe the
-- narrow interface used by the portable tests without weakening runtime types.
local roblox = require("@lune/roblox")
return (roblox :: unknown) :: {
	Color3: { fromRGB: (number, number, number) -> unknown },
	UDim: { new: (number, number) -> unknown },
	UDim2: unknown,
}
