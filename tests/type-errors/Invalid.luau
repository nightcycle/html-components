--!strict
local HTML = require(game.ReplicatedStorage.Packages.HTMLComponents)
HTML.Div({ Size = "large" }) -- EXPECT_ERROR
HTML.P({ TextSize = "16px" }) -- EXPECT_ERROR
HTML.Button({ Disabled = "true" }) -- EXPECT_ERROR
HTML.Input({ OnInput = function(_value: number) end }) -- EXPECT_ERROR
HTML.Img({ Src = 123 }) -- EXPECT_ERROR
HTML.Div({ Css = { Display = "grid" } }) -- EXPECT_ERROR
HTML.Video({ Volume = "loud" }) -- EXPECT_ERROR
HTML.Progress({ Value = "half" }) -- EXPECT_ERROR
local _tag: HTML.Tag = "div" -- EXPECT_ERROR
local _display: HTML.Display = "flex" -- EXPECT_ERROR
local _align: HTML.AlignItems = "Start" -- EXPECT_ERROR
local _properties: HTML.DivProperties = { Css = { FontWeight = "heavy" } } -- EXPECT_ERROR
local _input: HTML.TextareaProperties = { Value = 123 } -- EXPECT_ERROR
local _weight: HTML.FontWeight = "bold" -- EXPECT_ERROR
return {}
