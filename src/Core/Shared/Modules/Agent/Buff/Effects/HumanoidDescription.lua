local isClient = game:GetService("RunService"):IsClient()
if isClient then
    warn(("'%s' buff effect cannnot be applied to player characters on the client due to security limitations."):format(script.Name))
end
local BodyUtil = require(script.Parent.Parent.BodyUtil)

return function(player, property)
    local char = player and player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    local humanoidDesc = humanoid and humanoid:FindFirstChild("HumanoidDescription")
    local instancesAndProps = {}
    local isNil = tostring(property) == "nil"
    if humanoidDesc then
        if isNil then
            -- This applies the whole HumanoidDescription
            local humanoidDescriptionProperties = BodyUtil.getHumanoidDescriptionProperties()
            instancesAndProps = {}
            for _, propertyName in pairs(humanoidDescriptionProperties) do
                table.insert(instancesAndProps, {humanoidDesc, propertyName})
            end
        elseif not isNil then
            -- This applies individual properties
            instancesAndProps = {{humanoidDesc, property}}
        end
    end
    return instancesAndProps
end