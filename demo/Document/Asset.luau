--!strict
-- Packages
local storage = script.Parent.Parent
local HTML = require(storage.Packages.HTMLComponents)
local React = require(storage.Packages.React)
-- Modules
local Samples = require(script.Parent.Samples)
-- Components
-- Contexts
-- Hooks
-- Types
export type Properties = { Asset: Samples.Asset, Properties: HTML.ImgProperties }
-- Constants
local ASSET_SERVICE = game:GetService("AssetService")
local ENCODING_SERVICE = game:GetService("EncodingService")
-- References
-- Global Variables
-- Private Functions
-- Class
return function(props: Properties): React.ReactNode
	local content, setContent = React.useState(nil :: Content?)
	React.useEffect(function()
		local asset = props.Asset
		assert(
			asset.Width > 0 and asset.Height > 0 and asset.Width <= 1024 and asset.Height <= 1024,
			"Invalid local image dimensions"
		)
		local bytes = ENCODING_SERVICE:Base64Decode(buffer.fromstring(asset.Data))
		-- Lune emits a streaming Zstd frame without a content size. Roblox needs a
		-- bounded frame: declare the known RGBA size and use a single-segment window.
		if buffer.len(bytes) >= 6 and buffer.readu8(bytes, 4) == 0 then
			local framed = buffer.create(buffer.len(bytes) + 3)
			buffer.copy(framed, 0, bytes, 0, 4)
			buffer.writeu8(framed, 4, 0xA0)
			buffer.writeu32(framed, 5, asset.Width * asset.Height * 4)
			buffer.copy(framed, 9, bytes, 6)
			bytes = framed
		end
		local pixels = ENCODING_SERVICE:DecompressBuffer(bytes, Enum.CompressionAlgorithm.Zstd)
		assert(buffer.len(pixels) == asset.Width * asset.Height * 4, "Local image pixel size mismatch")
		local image = ASSET_SERVICE:CreateEditableImage({ Size = Vector2.new(asset.Width, asset.Height) })
		if not image then
			return
		end
		local ok, problem = pcall(function()
			image:WritePixelsBuffer(Vector2.zero, image.Size, pixels)
		end)
		if not ok then
			image:Destroy()
			error(tostring(problem))
		end
		setContent(Content.fromObject(image))
		return function()
			image:Destroy()
		end
	end, { props.Asset })
	local properties = table.clone(props.Properties)
	properties.ImageContent = content
	properties.IntrinsicSize = Vector2.new(props.Asset.Width, props.Asset.Height)
	return React.createElement(HTML.Img, properties)
end
