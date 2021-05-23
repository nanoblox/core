local BodyUtil = require(script.Parent.Parent.BodyUtil)
local isClient = game:GetService("RunService"):IsClient()

return function(player, additional)
    local instancesAndProps = {}
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local desc = humanoid and humanoid:FindFirstChildOfClass("HumanoidDescription")
    if desc then
        if isClient then
            for _, basePart in pairs(character:GetDescendants()) do
                if basePart:IsA("BasePart") then
                    table.insert(instancesAndProps, {basePart, "Color"})
                end
            end
        else
            for groupName, group in pairs(BodyUtil.bodyGroups) do
                if group.R15 and group.R6 then
                    table.insert(instancesAndProps, {desc, groupName.."Color"})
                end
            end
        end
    end
    return instancesAndProps
end