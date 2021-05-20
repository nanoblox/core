local ClientCommands = {}
local main = require(game.Nanoblox)



local lowercaseNameToClientModule = {}
for _, module in pairs(script:GetChildren()) do
    if module:IsA("ModuleScript") then
        lowercaseNameToClientModule[module.Name:lower()] = module
    end
end

function ClientCommands.get(name)
    local module = lowercaseNameToClientModule[name:lower()]
    if module then
        return require(module)
    end
end



return ClientCommands