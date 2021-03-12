local BodyUtil = {}



-- BODY GROUPS
local bodyGroups = {
    ["Head"] = {
        R15 = {"Head"},
        R6 = {"Head"},
    },

    ["Torso"] = {
        R15 = {"UpperTorso", "LowerTorso"},
        R6 = {"Torso"},
    },

    ["LeftArm"] = {
        R15 = {"LeftUpperArm", "LeftLowerArm", "LeftHand"},
        R6 = {"Left Arm"},
    },

    ["RightArm"] = {
        R15 = {"RightUpperArm", "RightLowerArm", "RightHand"},
        R6 = {"Right Arm"},
    },

    ["LeftLeg"] = {
        R15 = {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
        R6 = {"Left Leg"},
    },

    ["RightLeg"] = {
        R15 = {"RightUpperLeg", "RightLowerLeg", "RightFoot"},
        R6 = {"Right Leg"},
    },

    ["Accessories"] = {
        ClassName = "Accessories"
    },
}



-- METHODS
function BodyUtil:getPartsByBodyGroup(player, bodyGroupName)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local parts = {}
    if character and humanoid then
        local bodyGroup = bodyGroups[bodyGroupName]
        if bodyGroup.Accessories then
            for _, accessory in pairs(character:GetDescendants()) do
                if accessory:IsA("Accessory") then
                    for _, basePart in pairs(accessory:GetDescendants()) do
                        if basePart:IsA("BasePart") then
                            table.insert(parts, basePart)
                        end
                    end
                end
            end
            return parts
        end
        local partNames = bodyGroup[tostring(humanoid.RigType)]
        if partNames then
            for _, partName in pairs(partNames) do
                local correspondingPart = character:FindFirstChild(partName)
                if correspondingPart and correspondingPart:IsA("BasePart") then
                    table.insert(parts, correspondingPart)
                end
            end
        end
    end
    return parts
end



return BodyUtil