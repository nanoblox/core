local Core = {}



-- This sets-up the necessary diectories in relavent locations whilst accounting for players who may join the game early before
-- all server scripts have initialised
function Core.init(loader)
    local client = script.Client
    local server = script.Server
    local shared = script.Shared
    local starterPlayer = client.StarterPlayer
    local Directory = require(shared.Assets.Directory)

    -- This transfers extension items such as commands within the loader directly into the core
    local extensionsToMove = {
        Commands = server.Modules.Commands,
        Core = true,
    }
    local extensions = loader and loader:FindFirstChild("Extensions")
    if extensions then
        for _, extensionGroup in pairs(extensions:GetChildren()) do
            local destination = extensionsToMove[extensionGroup.Name]
            if destination then
                if extensionGroup.Name == "Core" then
                    Directory.merge(extensionGroup, script, false, true)
                else
                    for _, item in pairs(extensionGroup:GetChildren()) do
                        Directory.move(item, destination)
                    end
                    extensionGroup:Destroy()
                end
            end
        end
    end--]]

    -- This splits up the core into its key areas
    Directory.createDirectory("ServerStorage.Nanoblox", {server})
    Directory.createDirectory("ReplicatedStorage.Nanoblox", {shared, client})
    Directory.createDirectory("StarterCharacterScripts", starterPlayer.StarterCharacterScripts:GetChildren())

   -- This sets-up the server datamodel reference (i.e. game.Nanoblox)
    local pathwayModule = shared.Assets.Nanoblox:Clone()
    pathwayModule.Parent = game
    require(pathwayModule).initiate(loader)

    -- It's important to call this *after* the server has initiated
    Directory.createDirectory("StarterPlayerScripts", starterPlayer.StarterPlayerScripts:GetChildren())
end



return Core