local main = require(game.Nanoblox)
local AssetController = {
    remotes = {}
}
local cachedAssets = {}



-- START
function AssetController.start()

    local getClientAsset = main.modules.Remote.new("getClientAsset")
    AssetController.remotes.getClientAsset = getClientAsset
    
end



-- METHODS
function AssetController.cacheAsset(asset, location)
    local cachedAsset = asset:Clone()
    cachedAssets[asset.Name] = cachedAsset
    cachedAsset.Parent = main[location].Assets
end

function AssetController.cacheCommandAsset(commandName, asset)

end

function AssetController.getAsset(assetName)
    -- Returns a client-permitted asset
    local cachedAsset = cachedAssets[assetName]
    if cachedAsset then
        return main.modules.Promise.new(function(resolve)
            local asset = cachedAsset:Clone()
            resolve(asset)
        end)
    end
    return AssetController.remotes.getClientAsset:invokeServer(assetName)
        :andThen(function(success, assetOrWarning, location)
            return main.modules.Promise.new(function(resolve, reject)
                if success then
                    AssetController.cacheAsset(assetOrWarning, location)
                    resolve(assetOrWarning)
                end
                reject(assetOrWarning)
            end)
        end)
end

function AssetController.getAssets(assetNamesArray)
    -- Returns an (assetName = asset) dictionary of client-permitted assets
end

function AssetController.getCommandAsset(commandName, assetName)
    -- Returns a command client asset
end

function AssetController.getCommandAssets(commandName, assetNamesArray)
    -- Returns an (assetName = asset) dictionary of command client assets
end

function AssetController.getClientCommandAssetOrClientPermittedAsset(commandName, assetName)
    -- First checks if assetName is a client command asset. If successful, returns, else checks and returns if is a client-permitted asset.
end



return AssetController
