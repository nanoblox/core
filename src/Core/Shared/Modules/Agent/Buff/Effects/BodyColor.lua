local BodyUtil = require(script.Parent.Parent.BodyUtil)
local isClient = game:GetService("RunService"):IsClient()

return function(player, additional)
    local instancesAndProps = {}
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local desc = humanoid and humanoid:FindFirstChildOfClass("HumanoidDescription")
    if desc then
        if isClient then
            local parts = BodyUtil.getPartsByBodyGroup(player, additional)
            for _, basePart in pairs(parts) do
                table.insert(instancesAndProps, {basePart, "Color"})
            end
        else
            if tostring(additional) ~= "nil" then
                local group = BodyUtil.bodyGroups[additional]
                if group and group.R15 and group.R6 then
                    table.insert(instancesAndProps, {desc, additional.."Color"})
                end
            else
                for groupName, group in pairs(BodyUtil.bodyGroups) do
                    if group.R15 and group.R6 then
                        table.insert(instancesAndProps, {desc, groupName.."Color"})
                    end
                end
                local parts = BodyUtil.getPartsByBodyGroup(player, "Accessories")
                for _, basePart in pairs(parts) do
                    table.insert(instancesAndProps, {basePart, "Color"})
                end
            end
        end
    end
    return instancesAndProps
end