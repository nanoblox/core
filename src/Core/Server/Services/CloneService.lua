local main = require(game.Nanoblox)
local CloneService = {}



function CloneService.start()
    local Clone = main.modules.Clone
    
    local workspaceStorage = Instance.new("Folder")
    workspaceStorage.Name = Clone.storageName
    workspaceStorage.Parent = workspace
    Clone.workspaceStorage = workspaceStorage

    local replicatedStorage = Instance.new("Folder")
    replicatedStorage.Name = Clone.storageName
    replicatedStorage.Parent = main.ReplicatedStorage
    Clone.replicatedStorage = replicatedStorage
end



return CloneService
