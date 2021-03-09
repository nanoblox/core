return {
   ["Health"] = function(player)
        local humanoid = getHumanoid(player)
        local props = {}
        if humanoid then
            props = {humanoid.MaxHealth, humanoid.Health}
        end
        return props
    end,

    ["WalkSpeed"] = function(player)
        local humanoid = getHumanoid(player)
        local props = {}
        if humanoid then
            props = {humanoid.WalkSpeed}
        end
        return props
    end,

    ["JumpPower"] = function(player)
        local humanoid = getHumanoid(player)
        local props = {}
        if humanoid then
            props = {humanoid.JumpPower}
        end
        return props
    end,

    ["BodyTransparency"] = function(player)
        local character = player.Character
        local props = {}
        if character then
            for _, basePart in pairs(character:GetDescendants()) do
                if basePart:IsA("BasePart") then
                    table.insert(props, basePart)
                end
            end
        end
        return props
    end,

    ["BodyGroupTransparency"] = function(player, value)
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
    end,

    ["BodyClassTransparency"] = function()

    end,

    ["BodyMaterial"] = function()

    end,

    ["BodyReflectance"] = function()

    end,

    ["Shirt"] = function()

    end,

    ["Pants"] = function()

    end,

    ["Face"] = function()

    end,

    ["HumanoidDescription"] = function()

    end,
}