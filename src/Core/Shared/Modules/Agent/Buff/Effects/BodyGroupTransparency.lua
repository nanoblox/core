local bodyGroups = require(script.Parent.Parent.BodyGroups)

local function getHumanoid(player)
    local char = player and player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
end

return function(player, value)
    local character = player.Character
    local humanoid = getHumanoid(player)
    local props = {}
    if character and humanoid then
        local bodyGroupName = value[1]
        local bodyGroup = bodyGroups[bodyGroupName]
        if bodyGroup.Accessories then
            for _, accessory in pairs(character:GetDescendants()) do
                if accessory:IsA("Accessory") then
                    for _, basePart in pairs(accessory:GetDescendants()) do
                        if basePart:IsA("BasePart") then
                            table.insert(props, basePart)
                        end
                    end
                end
            end
            return props
        end
        local partNames = bodyGroup[tostring(humanoid.RigType)]
        if partNames then
            for _, partName in pairs(partNames) do
                local correspondingPart = character:FindFirstChild(partName)
                if correspondingPart and correspondingPart:IsA("BasePart") then
                    table.insert(props, correspondingPart)
                end
            end
        end
    end
    return props, value[2]
end