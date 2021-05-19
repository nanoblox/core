local BodyUtil = {}
local main = require(game.Nanoblox)



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
BodyUtil.bodyGroups = bodyGroups

local FAKE_GROUP_NAME = "AgentFakeBodyParts"



-- METHODS
function BodyUtil.getPartsByBodyGroup(player, bodyGroupName)
    local character = player and player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local parts = {}
    if character and humanoid then
        local bodyGroup = bodyGroups[bodyGroupName]
        if bodyGroupName == "nil" or bodyGroupName == nil then
            for _, basePart in pairs(character:GetDescendants()) do
                if basePart:IsA("BasePart") and basePart.Name ~= "HumanoidRootPart" and basePart.Parent.Name ~= FAKE_GROUP_NAME then
                    table.insert(parts, basePart)
                end
            end
        elseif bodyGroup then
            local className = bodyGroup and bodyGroup.ClassName
            if className == "Accessories" then
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
            local rigName = humanoid.RigType.Name
            local partNames = bodyGroup[rigName]
            if partNames then
                for _, partName in pairs(partNames) do
                    local correspondingPart = character:FindFirstChild(partName)
                    if correspondingPart and correspondingPart:IsA("BasePart") then
                        table.insert(parts, correspondingPart)
                    end
                end
            end
        end
    end
    return parts
end

function BodyUtil.getOrSetupFakeBodyParts(player, parts, effect, additional)
    local additionalString = tostring(additional)
    local fakeParts = {}
    local connections = {}
    if #parts > 0 then
        local character = player.Character
        local fakeFolder = character:FindFirstChild(FAKE_GROUP_NAME)
        if not fakeFolder then
            fakeFolder = Instance.new("Folder")
            fakeFolder.Name = FAKE_GROUP_NAME
            fakeFolder.Parent = character
            local tagGroup = Instance.new("Folder")
            tagGroup.Name = "Effects"
            tagGroup.Parent = fakeFolder
        end
        local tagGroup = fakeFolder.Effects
        local effectTag = tagGroup:FindFirstChild(effect)
        if not effectTag then
            effectTag = Instance.new("Folder")
            effectTag.Name = effect
            effectTag.Parent = tagGroup
        end
        local additionalTag = effectTag:FindFirstChild(additionalString)
        local firstTimeApplying = false
        if not additionalTag then
            firstTimeApplying = true
            additionalTag = Instance.new("Folder")
            additionalTag.Name = additionalString
            additionalTag.Parent = effectTag
            table.insert(connections, effectTag.ChildRemoved:Connect(function(child)
                if child.Name == additionalString then
                    for _, connection in pairs(connections) do
                        connection:Disconnect()
                    end
                    connections = nil
                    additionalTag:Destroy()
                    ---
                    for _, fakePart in pairs(fakeParts) do
                        local appliedCount = fakePart:GetAttribute("AppliedCount")
                        if appliedCount == 1 then
                            fakePart:Destroy()
                        else
                            fakePart:SetAttribute("AppliedCount", appliedCount-1)
                        end
                    end
                    ---
                    if #effectTag:GetChildren() == 0 then
                        effectTag:Destroy()
                        if #tagGroup:GetChildren() == 0 then
                            fakeFolder:Destroy()
                        end
                    end
                end
            end))
        end
        local ignoreParts = {
            HumanoidRootPart = true,
            Handle = true,
        }
        for _, part in pairs(parts) do
            if not ignoreParts[part.Name] then
                local fakePart = fakeFolder:FindFirstChild(part.Name)
                if not fakePart then
                    local updateSize

                    local isAHead = part.Name == "Head"
                    if isAHead and not part:IsA("MeshPart") then
                        fakePart = main.shared.Assets.FakeHead:Clone()
                        updateSize = function()
                            fakePart.Size = Vector3.new(part.Size.X/2, part.Size.Y, part.Size.Z)*1.2
                        end
                    else
                        fakePart = part:Clone()
                        fakePart:ClearAllChildren()
                        updateSize = function()
                            fakePart.Size = part.Size + Vector3.new(0.001, 0.001, 0.001)
                        end
                    end
                    if isAHead then
                        local face = part:FindFirstChild("face") or part:FindFirstChildOfClass("Decal")
                        if face then
                            local fakeFace = face:Clone()
                            fakeFace.Parent = fakePart
                            table.insert(connections, face:GetPropertyChangedSignal("Texture"):Connect(function()
                                fakeFace.Texture = face.Texture
                            end))
                            table.insert(connections, face:GetPropertyChangedSignal("Transparency"):Connect(function()
                                fakeFace.Transparency = face.Transparency
                            end))
                        end
                    end

                    fakePart.CFrame = part.CFrame
                    fakePart.Name = part.Name
                    fakePart.CanCollide = false
                    fakePart.Material = part.Material
                    fakePart.Color = part.Color
                    fakePart.Transparency = part.Transparency
                    updateSize()
                    --
                    local weld = Instance.new("Weld")
                    weld.Part0 = part
                    weld.Part1 = fakePart
                    weld.C0 = part.CFrame:Inverse()
                    weld.C1 = fakePart.CFrame:Inverse()
                    weld.Parent = fakePart
                    --
                    table.insert(connections, part:GetPropertyChangedSignal("Material"):Connect(function()
                        fakePart.Material = part.Material
                    end))
                    table.insert(connections, part:GetPropertyChangedSignal("Color"):Connect(function()
                        fakePart.Color = part.Color
                    end))
                    table.insert(connections, part:GetPropertyChangedSignal("Transparency"):Connect(function()
                        fakePart.Transparency = part.Transparency
                    end))
                    table.insert(connections, part:GetPropertyChangedSignal("Size"):Connect(function()
                        updateSize()
                    end))
                    fakePart.Parent = fakeFolder
                end
                if firstTimeApplying then
                    local appliedCount = fakePart:GetAttribute("AppliedCount") or 0
                    local originalCount = appliedCount
                    fakePart:SetAttribute("AppliedCount", appliedCount+1)
                end
                table.insert(fakeParts, fakePart)
            end
        end
    end
    return fakeParts
end

function BodyUtil.clearFakeBodyParts(player, effect, additionalString)
    local character = player.Character
    local fakeFolder = character and character:FindFirstChild(FAKE_GROUP_NAME)
    local effectTag = fakeFolder and fakeFolder.Effects:FindFirstChild(effect)
    local additionalTag = effectTag and effectTag:FindFirstChild(additionalString)
    if additionalTag then
        additionalTag:Destroy()
    end
end



return BodyUtil