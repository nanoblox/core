-- LOCAL
local main = require(game.Nanoblox)
local ProductUtil = {}



-- METHODS
function ProductUtil.getProductInfo(assetId, infoType)
	return main.modules.Promise.defer(function(resolve, reject)
		local success, productInfo = pcall(function() return main.MarketplaceService:GetProductInfo(assetId, infoType) end)
		if success then
			resolve(productInfo)
		end
		reject(productInfo)
	end)
end

function ProductUtil.getAssetTypeAsync(assetId, infoType)
	local assetType = 0
	local promise = ProductUtil.getProductInfo(assetId, infoType)
	local success, productInfo = promise:await()
	if success then
		assetType = productInfo.AssetTypeId
	end
	return assetType
end



return ProductUtil