local DUPLICATE_ASSET_WARNING = "Nanoblox: '%s' is a duplicate asset name! Rename to something unique otherwise assets may be retrieved incorrectly."
local main = require(game.Nanoblox)
local AssetService = {
    remotes = {}
}
local assetLocationsAndNames = {
    client = {},
    server = {},
    shared = {},
}
local clientPermittedAssets = {}
local serverPermittedAssets = {}
local commandAssets = {}
local assetNameToLocation = {}



-- INIT
function AssetService.init()
    
    -- This checks for duplicate asset names and warns against them
    local function recordAssetName(location, asset)
        local assetName = asset.Name
        local assetDictionary = assetLocationsAndNames[location]
        local alreadyPresent = assetDictionary[assetName]
        if alreadyPresent then
            warn(DUPLICATE_ASSET_WARNING:format(assetName))
            return
        end
        assetDictionary[assetName] = true
        if location == "server" then
            serverPermittedAssets[assetName] = asset
        elseif location == "client" then
            clientPermittedAssets[assetName] = asset
        elseif location == "shared" then
            serverPermittedAssets[assetName] = asset
            clientPermittedAssets[assetName] = asset
        end
        assetNameToLocation[assetName] = location
    end
    
    -- This moves assets out of ReplicatedStorage into a server location called 'AssetStorage' so that they aren't replicated
    local CLIENT_LOCATIONS = {
        "client",
        "shared"
    }
    local assetStorage = Instance.new("Folder")
    assetStorage.Name = "ClientAssetStorage"
    main.assetStorage = assetStorage
    for _, clientLocation in pairs(CLIENT_LOCATIONS) do
        local assetFolder = main[clientLocation].Assets
        local newAssetFolder = Instance.new("Folder")
        newAssetFolder.Name = clientLocation:sub(1,1):upper()..clientLocation:sub(2)
        newAssetFolder.Parent = assetStorage
        for _, child in pairs(assetFolder:GetChildren()) do
            if child.Name == "__forceReplicate" then
                for _, blockedItem in pairs(child:GetChildren()) do
                    recordAssetName(clientLocation, blockedItem)
                    blockedItem.Parent = assetFolder
                end
                child:Destroy()
            else
                recordAssetName(clientLocation, child)
                child.Parent = newAssetFolder
            end
         end
    end

    -- Ensure assets do not have duplicate names between locations
    for _, serverAsset in pairs(main.server.Assets:GetChildren()) do
        recordAssetName("server", serverAsset)
    end
    for assetName, _ in pairs(assetLocationsAndNames.shared) do
        if assetLocationsAndNames.client[assetName] or assetLocationsAndNames.server[assetName] then
            warn(DUPLICATE_ASSET_WARNING:format(assetName))
        end
    end

    -- Transfer command assets to assetStorage
    local commandsFolder = Instance.new("Folder")
    commandsFolder.Name = "Commands"
    commandsFolder.Parent = assetStorage

    local commandNameToParentFolder = {}
    local function transferCommandAsset(commandNameLower, location, asset)
        local parentFolder = commandNameToParentFolder[commandNameLower]
        local commandAssetTable = commandAssets[commandNameLower]
        if not parentFolder then
            parentFolder = Instance.new("Folder")
            parentFolder.Name = commandNameLower
            parentFolder.Parent = commandsFolder
            commandNameToParentFolder[commandNameLower] = parentFolder
            commandAssetTable = {
                Client = {},
                Server = {},
            }
            commandAssets[commandNameLower] = commandAssetTable
        end
        local locationFolder = parentFolder:FindFirstChild(location)
        if not locationFolder then
            locationFolder = Instance.new("Folder")
            locationFolder.Name = location
            locationFolder.Parent = parentFolder
        end
        commandAssetTable[location][asset.Name] = asset
        asset.Parent = locationFolder
    end

    local function setupCommandAssetStorage(commandModule)
        for _, instance in pairs(commandModule:GetChildren()) do
            if instance:IsA("ModuleScript") then
                local commandName = instance.Name:lower()
                for _, serverAsset in pairs(instance:GetChildren()) do
                    if serverAsset.Name == "Client" and serverAsset:IsA("ModuleScript") then
                        for _, clientAsset in pairs(serverAsset:GetChildren()) do
                            transferCommandAsset(commandName, "Client", clientAsset)
                        end
                    else
                        transferCommandAsset(commandName, "Server", serverAsset)
                    end
                end
            else
                setupCommandAssetStorage(instance)
            end
        end
    end
    setupCommandAssetStorage(main.server.Modules.Commands)

    -- Fin
    assetStorage.Parent = main.server.Parent

end



-- START
function AssetService.start()

    local getClientAsset = main.modules.Remote.new("getClientAsset")
    AssetService.remotes.getClientAsset = getClientAsset
    getClientAsset.onServerInvoke = function(player, assetName)
        print("requesting: ", assetName, clientPermittedAssets[assetName], clientPermittedAssets)
        local asset = clientPermittedAssets[assetName]
        if asset then
            local clonedAsset = asset:Clone()
            clonedAsset.Parent = player.PlayerGui
            main.modules.Thread.spawn(function()
                clonedAsset:Destroy()
            end)
            local location = assetNameToLocation[assetName]
            return true, clonedAsset, location
        end
        return false, ("'%s' is not a valid Client or Shared Asset!"):format(tostring(assetName))
    end
    
    
end



-- METHODS
function AssetService.getAsset(assetName)
    -- Returns a server-permitted asset
end

function AssetService.getAssets(assetNamesArray)
    -- Returns an (assetName = asset) dictionary of server-permitted assets
end

function AssetService.getCommandAsset(assetName)
    -- Returns a command server asset
end

function AssetService.getCommandAssets(assetNamesArray)
    -- Returns an (assetName = asset) dictionary of command server assets
end

function AssetService.getClientCommandAsset(assetName)
    -- Returns a command client asset
end

function AssetService.getClientCommandAssets(assetNamesArray)
    -- Returns an (assetName = asset) dictionary of command client assets
end



return AssetService
