local effects = {}
for _, module in pairs(script:GetChildren()) do
    if module:IsA("ModuleScript") then
        local effectModule = module
        effects[module.Name] = effectModule
    end
end
return effects