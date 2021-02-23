local ClientCommands = {}
local main = require(game.Nanoblox)



if main.isClient then
    for _, module in pairs(script:GetChildren()) do
        if module:IsA("ModuleScript") then
            local reference = require(module)
            local UID = module.Name
            ClientCommands[UID] = reference
        end
    end
end



return ClientCommands