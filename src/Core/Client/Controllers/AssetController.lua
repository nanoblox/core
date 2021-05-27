local main = require(game.Nanoblox)
local AssetController = {
    remotes = {}
}
local cachedAssets = {}
local cachedCommandAssets = {}
local commandNameToClientCommandModule = {}



-- START
function AssetController.start()

    local getClientAssets = main.modules.Remote.new("getClientAssets")
    AssetController.remotes.getClientAssets = getClientAssets
    
    local getCommandClientAssets = main.modules.Remote.new("getCommandClientAssets")
    AssetController.remotes.getCommandClientAssets = getCommandClientAssets

    local getClientCommandAssetsOrClientPermittedAssets = main.modules.Remote.new("getClientCommandAssetsOrClientPermittedAssets")
    AssetController.remotes.getClientCommandAssetsOrClientPermittedAssets = getClientCommandAssetsOrClientPermittedAssets
    
end



-- METHODS
function AssetController.getLocationFolder(location)
    local folder = main[location] and main[location].Assets
    if not folder then
        local clientCommandModule = commandNameToClientCommandModule[location]
        if not clientCommandModule then
            clientCommandModule = main.shared.Modules.ClientCommands:FindFirstChild(location)
            if clientCommandModule then
                commandNameToClientCommandModule[location] = clientCommandModule
            end
        end
        folder = clientCommandModule
    end
    return folder
end

function AssetController.cacheAsset(asset, location)
    local locationFolder = AssetController.getLocationFolder(location)
    local assetName = asset.Name
    local commandName = (location ~= "shared" and location ~= "client") and location
    if not AssetController.getCachedAsset(commandName, assetName) and locationFolder then
        local cachedAsset = asset:Clone()
        if commandName then
            cachedCommandAssets[assetName] = cachedAsset
        else
            cachedAssets[assetName] = cachedAsset
        end
        cachedAsset.Parent = locationFolder
    end
end

function AssetController.cacheAssets(assets, locations)
    for i, asset in pairs(assets) do
        local location = locations[i]
        AssetController.cacheAsset(asset, location)
    end
end

function AssetController.getCachedAsset(commandName, assetName)
    if not commandName then
        return cachedAssets[assetName]
    else
        return cachedCommandAssets[assetName]
    end
end

function AssetController._getAssets(remote, commandName, ...)
    local assetNamesArray = table.pack(...)
    local firstIndex = assetNamesArray[1]
    if typeof(firstIndex) == "table" then
        assetNamesArray = firstIndex
    end
    local cachedCount = 0
    for _, assetName in pairs(assetNamesArray) do
        local cachedAsset = cachedAssets[assetName]
        if cachedAsset then
            cachedCount += 1
        end
    end
    if cachedCount == #assetNamesArray then
        return main.modules.Promise.new(function(resolve)
            local assets = {}
            for _, assetName in pairs(assetNamesArray) do
                local asset = cachedAssets[assetName]:Clone()
                table.insert(assets, asset)
            end
            resolve(assets)
        end)
    end
    local finalArgsToPass = (commandName and {commandName, assetNamesArray}) or {assetNamesArray}
    return remote:invokeServer(unpack(finalArgsToPass))
        :andThen(function(success, assetsOrWarning, locations)
            return main.modules.Promise.new(function(resolve, reject)
                if success then
                    AssetController.cacheAssets(assetsOrWarning, locations)
                    resolve(assetsOrWarning)
                end
                reject(assetsOrWarning)
            end)
        end)
end

function AssetController.getAsset(assetName)
    -- Returns a promise which returns a client-permitted asset
    return AssetController.getAssets(assetName)
        :andThen(function(assets)
            return assets[1]
        end)
end

function AssetController.getAssets(...)
    -- Returns a promise which returns an array of client-permitted assets
    return AssetController._getAssets(AssetController.remotes.getClientAssets, false, ...)
end

function AssetController.getCommandAsset(commandName, assetName)
    -- Returns a promise which returns a command client asset
    return AssetController.getCommandAssets(commandName, assetName)
        :andThen(function(assets)
            return assets[1]
        end)
end

function AssetController.getCommandAssets(commandName, ...)
    -- Returns a promise which returns an array of command client assets
    return AssetController._getAssets(AssetController.remotes.getCommandClientAssets, commandName, ...)
end

function AssetController.getClientCommandAssetOrClientPermittedAsset(commandName, assetName)
    -- First checks if assetName is a client command asset. If successful, Returns a promise which returns, else checks and Returns a promise which returns if is a client-permitted asset.
    return AssetController.getClientCommandAssetsOrClientPermittedAssets(commandName, assetName)
        :andThen(function(assets)
            return assets[1]
        end)
end

function AssetController.getClientCommandAssetsOrClientPermittedAssets(commandName, ...)
    -- Same as above but for multiple assets
    return AssetController._getAssets(AssetController.remotes.getClientCommandAssetsOrClientPermittedAssets, commandName, ...)
end



return AssetController
