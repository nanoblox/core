local Core = {}



-- This sets-up the necessary diectories in relavent locations whilst accounting for players who may join the game early before
-- all server scripts have initialised
function Core.init(loader)
    local client = script.Client
    local server = script.Server
    local shared = script.Shared
    local starterPlayer = client.StarterPlayer
    local Directory = require(shared.Modules.Directory)

    -- It's important to setup the source of networking before the modules are initialised
    -- Rojo doesn't accurately build empty folders therefore we create it here
    local remotesContainer = Instance.new("Folder")
    remotesContainer.Name = "Remotes"
    remotesContainer.Parent = shared

    -- This transfers extension items such as commands within the loader directly into the core
    local extensions = loader and loader:FindFirstChild("Extensions")
    if extensions then
        for _, extensionGroup in pairs(extensions:GetChildren()) do
            local groupName = extensionGroup.Name
            local destination = server.Extensions:FindFirstChild(groupName)
            if not destination then
                destination = Instance.new("Folder")
                destination.Name = groupName
                destination.Parent = server.Extensions
            end
            if groupName == "Core" then
                -- The Extensions/Core is merged from the top of the real Core
                local extensionsCoreServer = extensionGroup:FindFirstChild("Server")
                local redundantExtensions = extensionsCoreServer and extensionsCoreServer:FindFirstChild("Extensions")
                if redundantExtensions then
                    redundantExtensions:Destroy()
                end
                Directory.merge(extensionGroup, script, false, true)
            else
                -- Everything else is merged into realCore/Server/Extensions
                local dontDestroyTarget = (groupName == "Commands" and true) or false
                for _, item in pairs(extensionGroup:GetChildren()) do
                    Directory.move(item, destination, dontDestroyTarget)
                end
                extensionGroup:Destroy()
            end
        end
    end

    -- This splits up the core into its key areas
    Directory.createDirectory("ServerStorage.Nanoblox", {server})
    Directory.createDirectory("ReplicatedStorage.Nanoblox", {shared, client})
    Directory.createDirectory("StarterCharacterScripts", starterPlayer.StarterCharacterScripts:GetChildren())

   -- This sets-up the server datamodel reference (i.e. game.Nanoblox)
    local pathwayModule = shared.Assets.__forceReplicate.Nanoblox:Clone()
    pathwayModule.Parent = game
    require(pathwayModule).initiate(loader)

    -- It's important to call this *after* the server has initiated
    Directory.createDirectory("StarterPlayerScripts", starterPlayer.StarterPlayerScripts:GetChildren())
end



return Core
