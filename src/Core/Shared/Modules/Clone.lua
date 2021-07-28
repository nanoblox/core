-- LOCAL
local SPAWN_OFFSET = CFrame.new(0, 0, -4) * CFrame.fromEulerAnglesXYZ(0, math.rad(180), 0)
local main = require(game.Nanoblox)
local CollisionUtil = main.modules.CollisionUtil
local Clone = {}
Clone.__index = function(table, index)
    local objectIndex = Clone[index]
    if objectIndex then
        return objectIndex
    end
    --return rawget(table, "clone")
end
Clone.spawnOffset = SPAWN_OFFSET
Clone.storageName = "CloneStorage"
Clone.workspaceStorage = nil
Clone.replicatedStorage = nil



-- CONSTRUCTOR
function Clone.new(playerOrCharacterOrUserId, properties)
	local self = {}
	setmetatable(self, Clone)
	
    local janitor = main.modules.Janitor.new()
    self.janitor = janitor
    self.userId = nil
    self.character = nil
    self.clone = nil
    self.hidden = false
    self.tracks = {}
    self.spawnCFrame = false
    self.forcedRigType = false
    self.animations = {}
    self.tracks = {}
    self.animNamesToTrack = {}
    self.hrp = false
    self.humanoid = false
    self.isDestroyed = false
    self.destroyed = main.modules.Signal.new()
    self.humanoidDescriptionCount = 0
    self.humanoidDescriptionToApply = false
    self.applyingHumanoidDescription = false
    self.humanoidDescriptionQueue = {}
    self.height = 5.2
    self.animateScript = false
    self.animateScriptDisabled = false
    self.transparencyJanitor = false
    self.watchingPlayerOrBasePart = false
    self.displayName = false

    if properties then
        for key, value in pairs(properties) do
            self[key] = value
        end
    end
    
    self:become(playerOrCharacterOrUserId)
    
	return self
end



-- METHODS
function Clone:become(item)
    --[[ Valid things to become:
        character
        userId
        username
        player
        humanoidDescription
    --]]
    local IsAHumanoidDesc = typeof(item) == "Instance" and item:IsA("HumanoidDescription")
    if typeof(item) == "Instance" and item:IsA("Player") then
        local humanoid = main.modules.PlayerUtil.getHumanoid(item)
        if humanoid and (humanoid.RigType == self.forcedRigType or not self.forcedRigType) then
            item = item.Character
        else
            item = item.UserId
        end
    end
    self.character = typeof(item) == "Instance" and not IsAHumanoidDesc and item
	self.userId = typeof(item) == "number" and item
    self.username = typeof(item) == "string" and item
    self.humanoidDescription = typeof(item) == "Instance" and IsAHumanoidDesc and item
    
    --[[
        if not clone present
            if character then copy character, make archivable, set parent
            elseif userid then copy rig template clone, apply appearance, set parent

        else
            if character then apply description, mimic bodyparts/items
            elseif userid apply appearance
    ]]
    local clone = self.clone
    local function getAndApplyDescription()
        main.modules.Thread.spawn(function()
            if self.humanoidDescription then
                return self:applyHumanoidDescription(self.humanoidDescription)
            end
            local userId = self.userId
            if not userId then
                local success, newUserId = main.modules.PlayerUtil.getUserIdFromName(self.username):await()
                userId = (success and newUserId) or 0
                self.userId = userId
            end
            local success, description = pcall(function() return main.Players:GetHumanoidDescriptionFromUserId(userId) end)
            if success and not self.isDestroyed then
                self:applyHumanoidDescription(description)
                if description.Head == 0 then
                    description.Head = "99"
                end
            end
        end)
    end

    if not clone then
        if self.character then
            local hrp = self.character:FindFirstChild("HumanoidRootPart")
            local archivable = self.character.Archivable
            self.character.Archivable = true
            clone = self.janitor:add(self.character:Clone(), "Destroy")
            self.character.Archivable = archivable
            clone.Archivable = true
            clone.HumanoidRootPart.CFrame = self.spawnCFrame or (hrp and hrp.CFrame * SPAWN_OFFSET) or CFrame.new()
            clone.Name = self.character.Name
            local charHumanoid = self.character:FindFirstChild("Humanoid")
            clone.Humanoid.DisplayName = self.displayName or (charHumanoid and charHumanoid.DisplayName) or self.character.Name
            for _, instance in pairs(clone:GetChildren()) do
                if instance:IsA("Script") or instance:IsA("LocalScript") then
                    instance:Destroy()
                end
            end
            ---
            local player = main.Players:GetPlayerFromCharacter(self.character)
            local agent = player and main.modules.PlayerUtil.getAgent(player)
            if agent then
                local transBuffs = agent:getNonTempBuffsWithEffect("BodyTransparency")
                local transValue = 0
                local firstBuff = transBuffs[1]
                if firstBuff then
                    transValue = firstBuff.value
                end
                self.clone = clone
                self:setTransparency(transValue)
            end
            ---
            
        else
            --local randomPlayer = main.Players:GetPlayers()[1]
            local rigType = self.forcedRigType
            --[[
            if not rigType and randomPlayer then
                local randomChar = randomPlayer.Character
                local randomHumanoid = randomChar and randomChar:FindFirstChildOfClass("Humanoid")
                if randomHumanoid then
                    rigType = randomHumanoid.RigType.Name
                end
            end--]]
            if not rigType then
                rigType = "R15"
            end
            clone = self.janitor:add(main.shared.Assets.Rigs[rigType]:Clone(), "Destroy")
            clone.HumanoidRootPart.CFrame = self.spawnCFrame or CFrame.new()
            if item then
                local inServerPlayer = (self.userId and main.Players:GetPlayerByUserId(self.userId)) or main.Players:FindFirstChild(self.username)
                if inServerPlayer then
                    clone.Name = inServerPlayer.Name.."'s Clone"
                    clone.Humanoid.DisplayName = self.displayName or inServerPlayer.DisplayName
                    self.username = inServerPlayer.Name
                    clone.Name = self.username
                    self.userId = inServerPlayer.UserId
                else
                    main.modules.Thread.spawn(function()
                        local username = self.username
                        if not username and self.userId then
                            local success, newUsername = main.modules.PlayerUtil.getNameFromUserId(self.userId):await()
                            username = (success and newUsername) or "####"
                        end
                        local userId = self.userId
                        if not userId and self.username then
                            local success, newUserId = main.modules.PlayerUtil.getUserIdFromName(username):await()
                            userId = (success and newUserId) or 0
                        end
                        if not self.isDestroyed and username then
                            clone.Humanoid.DisplayName = self.displayName or username
                            clone.Name = username
                        end
                        self.username = username
                        self.userId = userId
                    end)
                end
                clone.Parent = Clone.replicatedStorage
                getAndApplyDescription()
            end

        end 

        clone.Parent = Clone.workspaceStorage
        self.janitor:add(clone:GetPropertyChangedSignal("Parent"):Connect(function()
            if clone.Parent == nil then
                self:destroy()
            end
        end), "Disconnect")
        self.hrp = clone.HumanoidRootPart
        self.humanoid = clone.Humanoid
        self.clone = clone

        -- This destroys the clone if it goes below -500 studs
        local nextHeightCheck = 0
        self.janitor:add(main.RunService.Heartbeat:Connect(function()
            local timeNow = os.clock()
            if timeNow >= nextHeightCheck then
                nextHeightCheck = timeNow + 1
                if self.hrp and self.hrp.Parent and self.hrp.Position.Y < -500 then
                    clone:destroy()
                end
            end
        end), "Disconnect")

        local animateScript = self.janitor:add((main.isClient and main.shared.Assets.AnimateClient:Clone()) or main.server.Assets.AnimateServer:Clone(), "Destroy")
        animateScript.Disabled = true
        self.animateScript = animateScript
        if main.isServer then
            animateScript.Parent = clone
        else
            local CLIENT_ANIMATE_STORAGE_NAME = "NanobloxCloneAnimateStorage"
            local animateStorageLocation = main.localPlayer.PlayerScripts
            local clientAnimateStorage = animateStorageLocation:FindFirstChild(CLIENT_ANIMATE_STORAGE_NAME)
            if not clientAnimateStorage then
                clientAnimateStorage = Instance.new("Folder")
                clientAnimateStorage.Name = CLIENT_ANIMATE_STORAGE_NAME
                clientAnimateStorage.Parent = animateStorageLocation
            end
            animateScript.CloneCharacter.Value = clone
            animateScript.Parent = clientAnimateStorage
        end
        main.modules.Thread.spawn(function()
            self:disableAnimateScript(self.animateScriptDisabled)
        end)
    

    elseif self.clone then
        if self.character then
            local humanoid = self.character:FindFirstChild("Humanoid")
            local description = humanoid and humanoid:GetAppliedDescription()
            if description then
                self:applyHumanoidDescription(description)
                clone.Humanoid.DisplayName = self.displayName or humanoid.DisplayName
            end
            self.clone.Name = self.character.Name
            for _, charChild in pairs(self.character:GetChildren()) do
                local cloneChild = self.clone:FindFirstChild(charChild.Name)
                if not cloneChild then
                    charChild:Clone().Parent = clone
                else
                    if charChild:IsA("BasePart") then
                        cloneChild.Color = charChild.Color
                        cloneChild.Transparency = charChild.Transparency
                        cloneChild.Reflectance = charChild.Reflectance
                        cloneChild.Material = charChild.Material
                        cloneChild.Anchored = charChild.Anchored
                        cloneChild.Massless = charChild.Massless
                    elseif charChild:IsA("Shirt") then
                        cloneChild.ShirtTemplate = charChild.ShirtTemplate
                    elseif charChild:IsA("Pants") then
                        cloneChild.PantsTemplate = charChild.PantsTemplate
                    end
                end
            end

        elseif self.userId or self.username or self.humanoidDescription then
            getAndApplyDescription()
            main.modules.Thread.spawn(function()
                local username = self.username
                if not username and self.userId then
                    local success, newUsername = main.modules.PlayerUtil.getNameFromUserId(self.userId):await()
                    username = (success and newUsername) or "####"
                    self.username = username
                end
                if not self.isDestroyed and username then
                    clone.Name = username
                    clone.Humanoid.DisplayName = self.displayName or username
                end
            end)
        end
    end

    self:_updateHeight()
    
end

function Clone:setName(name)
    local stringName = tostring(name)
    self.humanoid.DisplayName = stringName
    self.displayName = name
    self.clone.Name = stringName
end

function Clone:disableAnimateScript(bool)
    local disableBool = (bool == true or bool == nil)
    if self.animateScript then
        self.animateScript.Disabled = disableBool
    end
    self.animateScriptDisabled = disableBool
end

function Clone:show()
	self.hidden = false
    self.clone.Parent = Clone.workspaceStorage
end

function Clone:hide()
	self.hidden = true
    self.clone.Parent = Clone.replicatedStorage
end

function Clone:setCFrame(cframe)
    local cloneHRP = self.hrp or self.clone:FindFirstChild("HumanoidRootPart")
    if cloneHRP then
        cloneHRP.CFrame = cframe
    end
end

function Clone:setCollidable(bool)
    local groupName = (bool == false and "NanobloxClones") or "Default"
    CollisionUtil.setCollisionGroup(self.clone, groupName)
end

function Clone:setAnchored(bool)
    for _, part in pairs(self.clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = bool
        end
    end
end

function Clone:anchorHRP(bool)
    local cloneHRP = self.clone:FindFirstChild("HumanoidRootPart")
    if cloneHRP then
        cloneHRP.Anchored = bool
    end
end

function Clone:setTransparency(value)
    local tJanitor = self.transparencyJanitor
    if tJanitor then
        tJanitor:cleanup()
    else
        tJanitor = self.janitor:add(main.modules.Janitor.new(), "Destroy")
        self.transparencyJanitor = tJanitor
    end
    local function changeTransparency(part)
        if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
            part.Transparency = value
            tJanitor:add(part:GetPropertyChangedSignal("Transparency"):Connect(function()
                part.Transparency = value
            end), "Disconnect")
        end
    end
    for _, part in ipairs(self.clone:GetDescendants()) do
        changeTransparency(part)
    end
    tJanitor:add(self.clone.DescendantAdded:Connect(function(descendant)
        main.RunService.Heartbeat:Wait()
        changeTransparency(descendant)
    end), "Disconnect")
end

function Clone:damage(number)
    self.humanoid.Health -= number
end

function Clone:heal(number)
    self.humanoid.Health += number
end

function Clone:regenerate(bool, regenRate, regenStep)
    local regen = bool ~= false
    local regenJanitor = self.regenJanitor
    if not regenJanitor and regen then
        regenJanitor = self.janitor:add(main.modules.Janitor.new(), "Destroy")
        self.regenJanitor = regenJanitor
        local nextStep = os.clock()
        local REGEN_RATE = regenRate or (1/100)
        local REGEN_STEP = regenStep or 1
        regenJanitor:add(main.RunService.Heartbeat:Connect(function()
            local timeNow = os.clock()
            if self.destroyed or self.humanoid.Health >= self.humanoid.MaxHealth then
                regenJanitor:cleanup()
            elseif timeNow >= nextStep then
                nextStep = timeNow + REGEN_STEP
                local dh = REGEN_STEP * REGEN_RATE * self.humanoid.MaxHealth
                self.humanoid.Health = math.min(self.humanoid.Health + dh, self.humanoid.MaxHealth)
            end
        end), "Disconnect")
    elseif regenJanitor and not regen then
        regenJanitor:cleanup()
    end
end

function Clone:loadTrack(animationId, animationName)
	
    local animIdString = tostring(animationId)
    local humanoid = self.clone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end
        local track = self.tracks[animIdString]
        if not track then
            local animation = self.animations[animIdString]
            if not animation then
                animation = self.janitor:add(Instance.new("Animation"), "Destroy")
                animation.AnimationId = "rbxassetid://"..animationId
                if animationName then
                    animation.Name = animationName
                end
                animation.Parent = self.clone
                self.animations[animIdString] = animation
            end
            track = animator:LoadAnimation(animation)
            self.tracks[animIdString] = track
        end
        if animationName then
            self.animNamesToTrack[animationName] = track
        end
        return track
	end
end

function Clone:getTrack(animationName)
	return self.animNamesToTrack[animationName]
end

function Clone:getTracks()
	local tracksArray = {}
    for _, track in pairs(self.tracks) do
        table.insert(tracksArray, track)
    end
    return tracksArray
end

function Clone:face(playerOrBasePart, power, dampening)
    
    local faceJanitor = self.janitor:add(main.modules.Janitor.new(), "Destroy", "faceJanitor")

    local BODY_GYRO_NAME = "NanobloxBodyGyro"
    local DEFAULT_POWER = 800--3000
    local DEFAULT_DAMPENING = 100--500

    --- @type BodyGyro
    local bodyGyro = faceJanitor:add(Instance.new("BodyGyro"), "Destroy")
    bodyGyro.Name = BODY_GYRO_NAME
    bodyGyro.D = dampening or DEFAULT_DAMPENING
    bodyGyro.MaxTorque = Vector3.new(0, power or DEFAULT_POWER, 0)
    bodyGyro.P = power or DEFAULT_POWER
    bodyGyro.Parent = self.hrp

    local basePart
    if playerOrBasePart:IsA("Player") then
        main.modules.Thread.spawn(function()
            local currentChar = playerOrBasePart.Character or playerOrBasePart.CharacterAdded:Wait()
            basePart = currentChar:FindFirstChild("HumanoidRootPart") or currentChar:WaitForChild("HumanoidRootPart", 3)
        end)
        faceJanitor:add(playerOrBasePart.CharacterAdded:Connect(function(newChar)
            basePart = newChar:WaitForChild("HumanoidRootPart", 3)
        end), "Disconnect")
    else
        basePart = playerOrBasePart
    end
    
    local nextCheck = 0
    faceJanitor:add(main.RunService.Heartbeat:Connect(function()
        if not basePart or not basePart.Parent then return end
        bodyGyro.CFrame = CFrame.new(self.hrp.Position, basePart.Position)
        local timeNow = os.clock()
        if timeNow >= nextCheck then
            nextCheck = timeNow + 1
            local stillPresent = basePart:FindFirstAncestorWhichIsA("Workspace") or basePart:FindFirstAncestorWhichIsA("ReplicatedStorage")
            if not stillPresent then
                self.janitor:remove("faceJanitor")
            end
        end
    end), "Disconnect")

    return bodyGyro
end

function Clone:unface()
    self.janitor:remove("faceJanitor")
end

function Clone:watch(playerOrBasePart)
	local isR6  = self.humanoid.RigType == Enum.HumanoidRigType.R6
    local isR15 = not isR6
    local head = self.clone:FindFirstChild("Head")
	local torso = isR6 and self.clone:FindFirstChild("Torso")
    local neck = (isR15 and head and head:FindFirstChild("Neck")) or (isR6 and torso and torso:FindFirstChild("Neck"))
	local waist
    local nextTorsoCheck = os.clock()
    if not neck then return end

    local watchJanitor = self.janitor:add(main.modules.Janitor.new(), "Destroy", "watchJanitor")

    local movementDetails = {
		neck = {YMultiplier = 1.5, Alpha = 0.2, Joint = neck, OriginC0 = neck.C0},
		waist = {YMultiplier = 0.9, Alpha = 0.2},
	}
    if isR6 then
        movementDetails["waist"] = nil
    end

    local basePart
    if playerOrBasePart:IsA("Player") then
        main.modules.Thread.spawn(function()
            local currentChar = playerOrBasePart.Character or playerOrBasePart.CharacterAdded:Wait()
            basePart = currentChar:FindFirstChild("Head") or currentChar:WaitForChild("Head", 3)
        end)
        watchJanitor:add(playerOrBasePart.CharacterAdded:Connect(function(newChar)
            basePart = newChar:WaitForChild("Head", 3)
        end), "Disconnect")
    else
        basePart = playerOrBasePart
    end
    self.watchingPlayerOrBasePart = playerOrBasePart

    watchJanitor:add(main.RunService.Stepped:Connect(function()
        local timeNow = os.clock()
        if timeNow >= nextTorsoCheck then
            nextTorsoCheck = timeNow + 1
            torso = (isR6 and self.clone:FindFirstChild("Torso")) or self.clone:FindFirstChild("UpperTorso")
            if isR15 then
                waist = (torso and torso:FindFirstChild("Waist"))
                local detail = movementDetails.waist
                if waist and detail.Joint ~= waist then
                    detail.Joint = waist
                    detail.OriginC0 = waist.C0
                end
            end
            if basePart then
                local stillPresent = basePart:FindFirstAncestorWhichIsA("Workspace") or basePart:FindFirstAncestorWhichIsA("ReplicatedStorage")
                if not stillPresent then
                    self.janitor:remove("watchJanitor")
                    return
                end
            end
        end
        if (isR15 and not waist) or not basePart then return end
        local point = basePart.Position
        local torsoLookVector = torso.CFrame.LookVector
        local headPosition = head.CFrame.Position
        local distance = (head.CFrame.Position - point).Magnitude
        local difference = head.CFrame.Y - point.Y
        for detailName, detail in pairs(movementDetails) do
            local angle =
            
            (isR6 and {
                X = (math.atan(difference/distance) * 1),
                Y = 0,
                Z = (((headPosition-point).Unit):Cross(torsoLookVector)).Y * detail.YMultiplier,
            })
            
            or 
            
            (isR15 and {
                X = -(math.atan(difference/distance) * 1),
                Y = (((headPosition-point).Unit):Cross(torsoLookVector)).Y * detail.YMultiplier,
                Z = 0,
            })

            local goal = detail.OriginC0 * CFrame.Angles(angle.X, angle.Y, angle.Z)
            detail.Joint.C0 = detail.Joint.C0:Lerp(goal, detail.Alpha)
        end
    end), "Disconnect")
    watchJanitor:add(function()
        for _, detail in pairs(movementDetails) do
            if detail.Joint then
                detail.Joint.C0 = detail.OriginC0
            end
        end
    end, true)
end

function Clone:unwatch()
	self.janitor:remove("watchJanitor")
end

function Clone:modifyHumanoidDescription(propertyName, value)

    self.humanoidDescriptionCount += 1
	local myCount = self.humanoidDescriptionCount
	local humanoid = self.humanoid
	if not self.humanoidDescriptionToApply then
		self.humanoidDescriptionToApply = humanoid:GetAppliedDescription()
	end
    if propertyName then
	    self.humanoidDescriptionToApply[propertyName] = value
    end
	if self.humanoidDescriptionCount == myCount and not self.applyingHumanoidDescription then
        self.applyingHumanoidDescription = true
        main.modules.Thread.spawn(function()
			local iterations = 0
            local appliedDesc
            local watchingPart = self.watchingPlayerOrBasePart
            if watchingPart then
                self:unwatch()
            end
            repeat
				main.RunService.Heartbeat:Wait()
				pcall(function() humanoid:ApplyDescription(self.humanoidDescriptionToApply) end)
				iterations += 1
                appliedDesc = humanoid and humanoid:GetAppliedDescription()
			until propertyName == nil or (appliedDesc and self.humanoidDescriptionToApply and appliedDesc[propertyName] == self.humanoidDescriptionToApply[propertyName]) or iterations == 10
            self.humanoidDescriptionToApply:Destroy()
			self.humanoidDescriptionToApply = false
            self.applyingHumanoidDescription = false
            self:_updateHeight()
            if watchingPart then
                self:watch(watchingPart)
            end
            if #self.humanoidDescriptionQueue > 0 then
                local newDesc = table.remove(self.humanoidDescriptionQueue, 1)
                self.humanoidDescriptionToApply = newDesc
                self:modifyHumanoidDescription()
            end
		end)
	end
end

function Clone:applyHumanoidDescription(newDesc)
    local cloneDesc = newDesc:Clone()
    if self.applyingHumanoidDescription then
        table.insert(self.humanoidDescriptionQueue, cloneDesc)
    else
        self.humanoidDescriptionToApply = cloneDesc
        self:modifyHumanoidDescription()
    end
end

function Clone:_updateHeight()
    local head = self.clone:FindFirstChild("Head")
    if head then
        self.height = self.hrp.Size.Y*2 + (head.Size.Y or 1.2)
    end
end

function Clone:_setScale(propertyName, value)
    local sJanitorName = ("scaleJanitor%s"):format(propertyName)
    local sJanitor = self.janitor:add(main.modules.Janitor.new(), "Destroy", sJanitorName)
    
    local function updateScaleValue()
        self:modifyHumanoidDescription(propertyName, value)
    end

    local function trackHumanoidValueInstance(humanoidValueInstance)
        sJanitor:add(humanoidValueInstance.Changed:Connect(function()
            main.RunService.Heartbeat:Wait()
            updateScaleValue()
        end), "Disconnect")
    end
    local humanoidValueInstance = self.humanoid:FindFirstChild(propertyName) or self.humanoid:FindFirstChild("Body"..propertyName)
    if humanoidValueInstance then
        trackHumanoidValueInstance(humanoidValueInstance)
    end
    sJanitor:add(self.humanoid.ChildAdded:Connect(function(child)
        if child.Name == propertyName or child.Name == "Body"..propertyName then
            trackHumanoidValueInstance(child)
        end
    end), "Disconnect")
    
    updateScaleValue()
end

function Clone:setSize(number)
	self:_setScale("DepthScale", number)
    self:_setScale("HeadScale", number)
    self:_setScale("HeightScale", number)
    self:_setScale("WidthScale", number)
end
Clone.setScale = Clone.setSize
Clone.setBodySize = Clone.setSize
Clone.setBodyScale = Clone.setSize

function Clone:setHeadSize(number)
	self:_setScale("HeadScale", number)
end
Clone.setHeadScale = Clone.setHeadSize

function Clone:setHeight(number)
	self:_setScale("HeightScale", number)
end

function Clone:setWidth(number)
	self:_setScale("WidthScale", number)
end

function Clone:setDepth(number)
	self:_setScale("DepthScale", number)
end

function Clone:setBodyType(number)
	self:_setScale("BodyTypeScale", number)
end

function Clone:setProportion(number)
	self:_setScale("ProportionScale", number)
end

function Clone:moveTo(targetPosition, studsAwayToStop, trackingBasePart)
	
    local pathJanitor = self.janitor:add(main.modules.Janitor.new(), "Destroy", "pathJanitor")
    studsAwayToStop = studsAwayToStop or 0

    local agentHrpSize = self.hrp.Size
    local agentHead = self.clone.Head
    local pathParams = {
        AgentRadius = agentHrpSize.X,
        AgentHeight = (agentHrpSize.Y  *2) + agentHead.Size.Y,
        AgentCanJump = true,
    }
    local path = pathJanitor:add(main.PathfindingService:CreatePath(pathParams), "Destroy")
    local cloneHRP = self.clone.HumanoidRootPart
    local cloneHumanoid = self.humanoid
    
    local waypoints = {}
    local currentWaypointIndex = 1

    local nextCheck = 0
    local previousPosition
    local nextIdleCheck = 0
    pathJanitor:add(main.RunService.Heartbeat:Connect(function()
        -- This prevents the clone completely walking on top of the target position
        local timeNow = os.clock()
        if timeNow >= nextCheck then
            nextCheck = timeNow + 0.2
            local trackingPosition = (trackingBasePart and trackingBasePart.Position) or targetPosition
            local distanceFromClone = self:getDistanceFromClone(trackingPosition)
            local waypointsAway = #waypoints - currentWaypointIndex
            if distanceFromClone <= studsAwayToStop and waypointsAway < math.ceil(studsAwayToStop / 3) then
                self.reachedTarget = true
                self.janitor:remove("pathJanitor")
                cloneHumanoid:MoveTo(self.hrp.Position)
            end
        end
        if timeNow >= nextIdleCheck then
            nextIdleCheck = timeNow + 0.5
            if previousPosition then
                local distanceFromPrevious = (self.hrp.Position - previousPosition).Magnitude
                if distanceFromPrevious < self.humanoid.WalkSpeed/20 then
                    self.humanoid.Jump = true
                end
            end
            previousPosition = self.hrp.Position
        end
    end), "Disconnect")

    self.reachedTarget = false

    local function moveToWaypoint()
        local currentWaypoint = waypoints[currentWaypointIndex]
        if currentWaypoint then
            local newPosition = currentWaypoint.Position
            local hrpHeight = self.hrp.Size.Y
            local stepHeight = newPosition.Y - (self.hrp.Position.Y - (hrpHeight * 1.5))
            cloneHumanoid:MoveTo(currentWaypoint.Position)
            if stepHeight >= 2 then
                cloneHumanoid.Jump = true
            end
        end
    end

    local function computeWaypoints()
        path:ComputeAsync(cloneHRP.Position, targetPosition)
        currentWaypointIndex = 1
        if path.Status == Enum.PathStatus.Success then
            waypoints = path:GetWaypoints()

            --[[
            local r = math.random(1, 255)
            local g = math.random(1, 255)
            local b = math.random(1, 255)
            for i, waypoint in pairs(waypoints) do
                local part = pathJanitor:add(Instance.new("Part"), "Destroy")
                part.Name = "Waypoint"..i
                part.Color = Color3.fromRGB(r, g, b)
                part.Anchored = true
                part.CanCollide = false
                part.Transparency = 0.2
                part.CFrame = CFrame.new(waypoint.Position)
                part.Size = Vector3.new(2,2,2)
                part.Parent = workspace
            end
            ---]]

            moveToWaypoint()
        else
            main.modules.Thread.delay(1, function()
                self.reachedTarget = true
                self.janitor:remove("pathJanitor")
                cloneHumanoid:MoveTo(self.hrp.Position)
            end)
        end
    end

    local function onWaypointReached(reached)
        if currentWaypointIndex == #waypoints then
            self.reachedTarget = true
            self.janitor:remove("pathJanitor")
            return
        end
        if reached then
            currentWaypointIndex +=1
        else
            cloneHumanoid.Jump = true
        end
        moveToWaypoint()
    end

    local function onPathBlocked(blockedWaypointIndex)
        if blockedWaypointIndex > currentWaypointIndex then
            computeWaypoints()
        end
    end

    main.modules.Thread.spawn(computeWaypoints)

    pathJanitor:add(path.Blocked:Connect(onPathBlocked), "Disconnect")
    pathJanitor:add(cloneHumanoid.MoveToFinished:Connect(onWaypointReached), "Disconnect")
end

function Clone:follow(playerOrBasePart, studsAwayToStop)
    local followJanitor = self.janitor:add(main.modules.Janitor.new(), "Destroy", "followJanitor")

	local basePart
    if playerOrBasePart:IsA("Player") then
        main.modules.Thread.spawn(function()
            local currentChar = playerOrBasePart.Character or playerOrBasePart.CharacterAdded:Wait()
            basePart = currentChar:FindFirstChild("HumanoidRootPart") or currentChar:WaitForChild("HumanoidRootPart", 3)
        end)
        followJanitor:add(playerOrBasePart.CharacterAdded:Connect(function(newChar)
            basePart = newChar:WaitForChild("HumanoidRootPart", 3)
        end), "Disconnect")
    else
        basePart = playerOrBasePart
    end

    local targetPosition

    local function stillPresentCheck()
        local stillPresent = basePart:FindFirstAncestorWhichIsA("Workspace") or basePart:FindFirstAncestorWhichIsA("ReplicatedStorage")
        if not stillPresent then
            self.janitor:remove("followJanitor")
            return false
        end
        return true
    end

    local STUDS_AWAY_TO_STOP = 2
    local REACTIVATE_DISTANCE = 1
    local MAXIMUM_DISTANCE_DRIFT = 5
    local finalStudsAwayToStop = studsAwayToStop or STUDS_AWAY_TO_STOP
    local finalReactiveDistance = finalStudsAwayToStop + REACTIVATE_DISTANCE
    followJanitor:add(self.humanoid.MoveToFinished:Connect(function()
        if not stillPresentCheck() then return end
        local newTargetPosition = basePart.Position
        local distanceFromPreviousTarget = (newTargetPosition - targetPosition).Magnitude
        local distanceFromClone = self:getDistanceFromClone(newTargetPosition)
        targetPosition = newTargetPosition

        if (self.reachedTarget and distanceFromClone > finalReactiveDistance) or distanceFromPreviousTarget > MAXIMUM_DISTANCE_DRIFT then
            self:moveTo(targetPosition, finalStudsAwayToStop, basePart)
        elseif self.reachedTarget then
            local nextCheck = 0
            followJanitor:add(main.RunService.Heartbeat:Connect(function()
                local timeNow = os.clock()
                if timeNow >= nextCheck then
                    nextCheck = timeNow + 0.5
                    if not stillPresentCheck() then return end
                    if basePart then
                        newTargetPosition = basePart.Position
                        distanceFromClone = self:getDistanceFromClone(newTargetPosition)
                        if distanceFromClone > finalReactiveDistance then
                            followJanitor:remove("positionChangedChecker")
                            self:moveTo(newTargetPosition, finalStudsAwayToStop, basePart)
                        end
                    end
                end
            end), "Disconnect", "positionChangedChecker")
        end
    end), "Disconnect")

    followJanitor:add(main.modules.Thread.delayUntil(function() return basePart end, function()
        targetPosition = basePart.Position
        self:moveTo(targetPosition)
    end), "Disconnect")
end

function Clone:getDistanceFromClone(positionOfTarget)
    local clonePosition = self.hrp.Position
    local normalisedClonePosition = Vector3.new(clonePosition.X, positionOfTarget.Y, clonePosition.Z)
    local distanceFromClone = (positionOfTarget - normalisedClonePosition).Magnitude
    return distanceFromClone
end

function Clone:unfollow()
	self.janitor:remove("followJanitor")
end

function Clone:destroy()
    if not self.isDestroyed then
        self.isDestroyed = true
        self.janitor:destroy()
        self.destroyed:Fire()
        self.destroyed:Destroy()
    end
end
Clone.Destroy = Clone.destroy



return Clone