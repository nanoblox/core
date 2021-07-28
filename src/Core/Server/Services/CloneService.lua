local main = require(game.Nanoblox)
local CloneService = {}



function CloneService.start()
    local Clone = main.modules.Clone
    
    local workspaceStorage = Instance.new("Folder")
    workspaceStorage.Name = Clone.storageName
    workspaceStorage.Parent = main.workspaceFolder
    Clone.workspaceStorage = workspaceStorage

    local replicatedStorage = Instance.new("Folder")
    replicatedStorage.Name = Clone.storageName
    replicatedStorage.Parent = main.ReplicatedStorage.Nanoblox
    Clone.replicatedStorage = replicatedStorage
end



return CloneService
