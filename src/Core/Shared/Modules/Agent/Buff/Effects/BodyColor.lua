local BodyUtil = require(script.Parent.Parent.BodyUtil)

return function(player, additional)
    local instancesAndProps = {}
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local desc = humanoid and humanoid:FindFirstChildOfClass("HumanoidDescription")
    if desc then
        for groupName, group in pairs(BodyUtil.bodyGroups) do
            if group.R15 and group.R6 then
                table.insert(instancesAndProps, {desc, groupName.."Color"})
            end
        end
    end
    return instancesAndProps
end