--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
-- Components
local App = require(ReplicatedStorage.Demo)
local RobloxComponents = require(ReplicatedStorage.Packages.RobloxComponents)
-- Packages
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
-- Hooks
-- Contexts
-- Types
-- Constants
-- Variables
-- References
local player = Players.LocalPlayer
local root = ReactRoblox.createRoot(player:WaitForChild("PlayerGui"))
-- Private Functions
-- Class
root:render(React.createElement(RobloxComponents.ScreenGui({
	Name = "HTMLComponentsDemo",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, {}, { App = React.createElement(App) })))
script.Destroying:Connect(function()
	root:unmount()
end)
