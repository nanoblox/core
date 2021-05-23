local isClient = game:GetService("RunService"):IsClient()
if isClient then
    warn(("'%s' buff effect cannnot be applied to player characters on the client due to security limitations."):format(script.Name))
end

return function(player, property)
    local char = player and player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    local humanoidDesc = humanoid and humanoid:FindFirstChild("HumanoidDescription")
    local instancesAndProps = {}
    if humanoidDesc and tostring(property) ~= "nil" then
        instancesAndProps = {{humanoidDesc, property}}
    end
    return instancesAndProps
end