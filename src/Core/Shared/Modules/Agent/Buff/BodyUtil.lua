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
                if child.Name == additionalString and connections then
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
                    local function setupFakePart(partToCopy, forcedProperties)
                        local updateSize
                        local isAHead = partToCopy.Name == "Head"
                        if isAHead and not partToCopy:IsA("MeshPart") then
                            fakePart = main.shared.Assets.FakeHead:Clone()
                            updateSize = function()
                                fakePart.Size = Vector3.new(partToCopy.Size.X/2, partToCopy.Size.Y, partToCopy.Size.Z)*1.2
                            end
                        else
                            fakePart = partToCopy:Clone()
                            fakePart:ClearAllChildren()
                            updateSize = function()
                                local ADDITIONAL_SIZE = 0.02 --0.01
                                fakePart.Size = partToCopy.Size + Vector3.new(ADDITIONAL_SIZE, ADDITIONAL_SIZE, ADDITIONAL_SIZE)
                            end
                        end
                        if isAHead then
                            local face = partToCopy:FindFirstChild("face") or partToCopy:FindFirstChildOfClass("Decal")
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

                        fakePart.CFrame = partToCopy.CFrame
                        fakePart.Name = partToCopy.Name
                        fakePart.CanCollide = false
                        fakePart.Material = partToCopy.Material
                        fakePart.Color = partToCopy.Color
                        fakePart.Transparency = partToCopy.Transparency
                        fakePart.Reflectance = partToCopy.Reflectance
                        if forcedProperties then
                            for propertName, value in pairs(forcedProperties) do
                                fakePart[propertName] = value
                            end
                        end
                        updateSize()
                        --
                        local weld = Instance.new("Weld")
                        weld.Part0 = partToCopy
                        weld.Part1 = fakePart
                        weld.C0 = partToCopy.CFrame:Inverse()
                        weld.C1 = fakePart.CFrame:Inverse()
                        weld.Parent = partToCopy
                        --
                        table.insert(connections, partToCopy:GetPropertyChangedSignal("Material"):Connect(function()
                            fakePart.Material = partToCopy.Material
                        end))
                        table.insert(connections, partToCopy:GetPropertyChangedSignal("Color"):Connect(function()
                            fakePart.Color = partToCopy.Color
                        end))
                        table.insert(connections, partToCopy:GetPropertyChangedSignal("Transparency"):Connect(function()
                            fakePart.Transparency = partToCopy.Transparency
                        end))
                        table.insert(connections, partToCopy:GetPropertyChangedSignal("Reflectance"):Connect(function()
                            fakePart.Reflectance = partToCopy.Reflectance
                        end))
                        table.insert(connections, partToCopy:GetPropertyChangedSignal("Size"):Connect(function()
                            updateSize()
                        end))
                        table.insert(connections, partToCopy:GetPropertyChangedSignal("Parent"):Connect(function()
                            main.RunService.Heartbeat:Wait()
                            if partToCopy.Parent == nil and fakeFolder.Parent ~= nil and fakePart.Parent ~= nil then
                                fakePart:Destroy()
                            end
                        end))
                        table.insert(connections, fakePart:GetPropertyChangedSignal("Parent"):Connect(function()
                            if fakePart.Parent == nil and fakeFolder.Parent ~= nil then
                                local correspondingPart = character:FindFirstChild(part.Name)
                                if correspondingPart then
                                    setupFakePart(correspondingPart, {
                                        Material = fakePart.Material,
                                        Reflectance = fakePart.Reflectance,
                                    })
                                end
                            end
                        end))
                        fakePart.Parent = fakeFolder
                    end
                    setupFakePart(part)
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

function BodyUtil.getHumanoidDescriptionProperties()
    return {
        "BackAccessory",
        "FaceAccessory",
        "FrontAccessory",
        "HairAccessory",
        "HatAccessory",
        "NeckAccessory",
        "ShouldersAccessory",
        "WaistAccessory",
        "BodyTypeScale",
        "DepthScale",
        "HeadScale",
        "HeightScale",
        "ProportionScale",
        "WidthScale",
        "ClimbAnimation",
        "FallAnimation",
        "IdleAnimation",
        "JumpAnimation",
        "RunAnimation",
        "SwimAnimation",
        "WalkAnimation",
        "Face",
        "Head",
        "LeftArm",
        "LeftLeg",
        "RightArm",
        "RightLeg",
        "Torso",
        "GraphicTShirt",
        "Pants",
        "Shirt",
        "HeadColor",
        "LeftArmColor",
        "LeftLegColor",
        "RightArmColor",
        "RightLegColor",
        "TorsoColor",
    }
end



return BodyUtil