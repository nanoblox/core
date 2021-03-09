local effects = {}
for _, module in pairs(script.Parent:GetChildren()) do
    if module:IsA("ModuleScript") then
        local effect = require(module)
        table.insert(effects, effect)
    end
end
return effects