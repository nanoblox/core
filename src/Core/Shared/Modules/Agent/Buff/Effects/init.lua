local effects = {}
for _, module in pairs(script:GetChildren()) do
    if module:IsA("ModuleScript") then
        local effect = require(module)
        effects[module.Name] = effect
    end
end
return effects