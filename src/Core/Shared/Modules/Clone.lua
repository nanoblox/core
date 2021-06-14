-- LOCAL
local SPAWN_OFFSET = CFrame.new(0, 0, -4) * CFrame.fromEulerAnglesXYZ(0, math.rad(180), 0)
local main = require(game.Nanoblox)
local storageName = ("NanobloxCloneStorage (%s)"):format(main.location)
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
Clone.storageName = "NanobloxCloneStorage"
Clone.workspaceStorage = nil
Clone.replicatedStorage = nil



-- CONSTRUCTOR
function Clone.new(playerOrCharacterOrUserId, spawnCFrame)
	local self = {}
	setmetatable(self, Clone)
	
    local maid = main.modules.Maid.new()
    self._maid = maid
    self.userId = nil
    self.character = nil
    self.clone = nil
    self.hidden = false
    self.tracks = {}
    self.spawnCFrame = spawnCFrame
    self.animations = {}
    self.tracks = {}
    self.animNamesToTrack = {}
    self.hrp = nil
    self.humanoid = nil
    self.destroyed = false
    self.destroyedSignal = main.modules.Signal.new()
    self.humanoidDescriptionCount = 0
    self.humanoidDescriptionToApply = nil
    self.applyingHumanoidDescription = false
    self.humanoidDescriptionQueue = {}
    
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
        item = item.Character
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
            if success and not self.destroyed then
                self:applyHumanoidDescription(description)
            end
        end)
    end

    if not clone then
        if self.character then
            local hrp = self.character:FindFirstChild("HumanoidRootPart")
            local archivable = self.character.Archivable
            self.character.Archivable = true
            clone = self._maid:give(self.character:Clone())
            self.character.Archivable = archivable
            clone.Archivable = true
            clone.HumanoidRootPart.CFrame = self.spawnCFrame or (hrp and hrp.CFrame * SPAWN_OFFSET) or CFrame.new()
            clone.Name = self.character.Name
            local charHumanoid = self.character:FindFirstChild("Humanoid")
            clone.Humanoid.DisplayName = self.displayName or (charHumanoid and charHumanoid.DisplayName) or self.character.Name
            
        else
            local randomPlayer = main.Players:GetPlayers()[1]
            local rigType
            if randomPlayer then
                local randomChar = randomPlayer.Character
                local randomHumanoid = randomChar and randomChar:FindFirstChildOfClass("Humanoid")
                if randomHumanoid then
                    rigType = randomHumanoid.RigType.Name
                end
            end
            if not rigType then
                rigType = "R15"
            end
            clone = self._maid:give(main.shared.Assets.Rigs[rigType]:Clone())
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
                        if not self.destroyed and username then
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
        self._maid:give(clone:GetPropertyChangedSignal("Parent"):Connect(function()
            if clone.Parent == nil then
                self:destroy()
            end
        end))
        self.hrp = clone.HumanoidRootPart
        self.humanoid = clone.Humanoid
        self.clone = clone

        -- This destroys the clone if it goes below -500 studs
        local nextHeightCheck = 0
        self._maid:give(main.RunService.Heartbeat:Connect(function()
            local timeNow = os.clock()
            if timeNow >= nextHeightCheck then
                nextHeightCheck = timeNow + 1
                if self.hrp and self.hrp.Parent and self.hrp.Position.Y < -500 then
                    clone:destroy()
                end
            end
        end))

        local animateScript = (main.isClient and main.shared.Assets.AnimateClient:Clone()) or main.server.Assets.AnimateServer:Clone()
        self._maid:give(animateScript)
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
        animateScript.Disabled = false
    

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
                if not self.destroyed and username then
                    clone.Name = username
                    clone.Humanoid.DisplayName = self.displayName or username
                end
            end)
        end
    end

end

function Clone:setName(name)
    local stringName = tostring(name)
    self.humanoid.DisplayName = stringName
    self.displayName = name
    self.clone.Name = stringName
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
    local cloneHRP = self.clone:FindFirstChild("HumanoidRootPart")
    if cloneHRP then
        cloneHRP.CFrame = cframe
    end
end

function Clone:setCollidable(bool)
    local groupName = (bool == false and CollisionUtil.cloneCollisionGroupName) or "Default"
    CollisionUtil.setCollisionGroup(self.clone, groupName)
end

function Clone:setAnchored(bool)
    local cloneHRP = self.clone:FindFirstChild("HumanoidRootPart")
    if cloneHRP then
        cloneHRP.Anchored = bool
    end
end

function Clone:setTransparency(value)
    local tMaid = self.transparencyMaid
    if tMaid then
        tMaid:clean()
    else
        tMaid = self._maid:give(main.modules.Maid.new())
        self.transparencyMaid = tMaid
    end
    local function changeTransparency(part)
        if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
            part.Transparency = value
            tMaid:give(part:GetPropertyChangedSignal("Transparency"):Connect(function()
                part.Transparency = value
            end))
        end
    end
    for _, part in pairs(self.clone:GetDescendants()) do
        changeTransparency(part)
    end
    tMaid:give(self.clone.DescendantAdded:Connect(function(descendant)
        main.RunService.Heartbeat:Wait()
        changeTransparency(descendant)
    end))
end

function Clone:damage(number)
    self.humanoid.Health -= number
end

function Clone:heal(number)
    self.humanoid.Health += number
end

function Clone:regenerate(bool, regenRate, regenStep)
    local regen = bool ~= false
    local regenMaid = self.regenMaid
    if not regenMaid and regen then
        regenMaid = self._maid:give(main.modules.Maid.new())
        self.regenMaid = regenMaid
        local nextStep = os.clock()
        local REGEN_RATE = regenRate or (1/100)
        local REGEN_STEP = regenStep or 1
        regenMaid:give(main.RunService.Heartbeat:Connect(function()
            local timeNow = os.clock()
            if self.destroyed or self.humanoid.Health >= self.humanoid.MaxHealth then
                regenMaid:clean()
            elseif timeNow >= nextStep then
                nextStep = timeNow + REGEN_STEP
                local dh = REGEN_STEP * REGEN_RATE * self.humanoid.MaxHealth
                self.humanoid.Health = math.min(self.humanoid.Health + dh, self.humanoid.MaxHealth)
            end
        end))
    elseif regenMaid and not regen then
        regenMaid:clean()
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
                animation = self._maid:give(Instance.new("Animation"))
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
    
    local faceMaid = main.modules.Maid.new()
    self._maid.faceMaid = faceMaid

    local BODY_GYRO_NAME = "NanobloxBodyGyro"
    local DEFAULT_POWER = 800--3000
    local DEFAULT_DAMPENING = 100--500
    local bodyGyro = faceMaid:give(Instance.new("BodyGyro"))
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
        faceMaid:give(playerOrBasePart.CharacterAdded:Connect(function(newChar)
            basePart = newChar:WaitForChild("HumanoidRootPart", 3)
        end))
    else
        basePart = playerOrBasePart
    end
    
    local nextCheck = 0
    faceMaid:give(main.RunService.Heartbeat:Connect(function()
        if not basePart or not basePart.Parent then return end
        bodyGyro.CFrame = CFrame.new(self.hrp.Position, basePart.Position)
        local timeNow = os.clock()
        if timeNow >= nextCheck then
            nextCheck = timeNow + 1
            local stillPresent = basePart:FindFirstAncestorWhichIsA("Workspace") or basePart:FindFirstAncestorWhichIsA("ReplicatedStorage")
            if not stillPresent then
                self._maid.faceMaid = nil
            end
        end
    end))

    return bodyGyro
end

function Clone:unface()
    self._maid.faceMaid = nil
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

    local watchMaid = main.modules.Maid.new()
    self._maid.watchMaid = watchMaid

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
        watchMaid:give(playerOrBasePart.CharacterAdded:Connect(function(newChar)
            basePart = newChar:WaitForChild("Head", 3)
        end))
    else
        basePart = playerOrBasePart
    end
    self.watchingPlayerOrBasePart = playerOrBasePart

    watchMaid:give(main.RunService.Stepped:Connect(function()
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
                    self._maid.watchMaid = nil
                    return
                end
            end
        end
        if (isR15 and not waist) or not basePart then return end
        local point = basePart.Position
        local torsoLookVector = torso.CFrame.lookVector
        local headPosition = head.CFrame.p
        local distance = (head.CFrame.p - point).magnitude
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
            detail.Joint.C0 = detail.Joint.C0:lerp(goal, detail.Alpha)
        end
    end))
    watchMaid:give(function()
        for _, detail in pairs(movementDetails) do
            if detail.Joint then
                detail.Joint.C0 = detail.OriginC0
            end
        end
    end)
end

function Clone:unwatch()
	self._maid.watchMaid = nil
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
			self.humanoidDescriptionToApply = nil
            self.applyingHumanoidDescription = false
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

function Clone:_setScale(propertyName, value)
    local sMaidName = ("scaleMaid%s"):format(propertyName)
    local sMaid = main.modules.Maid.new()
    self._maid[sMaidName] = sMaid
    
    local function updateScaleValue()
        self:modifyHumanoidDescription(propertyName, value)
    end

    local function trackHumanoidValueInstance(humanoidValueInstance)
        sMaid:give(humanoidValueInstance.Changed:Connect(function()
            main.RunService.Heartbeat:Wait()
            updateScaleValue()
        end))
    end
    local humanoidValueInstance = self.humanoid:FindFirstChild(propertyName) or self.humanoid:FindFirstChild("Body"..propertyName)
    if humanoidValueInstance then
        trackHumanoidValueInstance(humanoidValueInstance)
    end
    sMaid:give(self.humanoid.ChildAdded:Connect(function(child)
        if child.Name == propertyName or child.Name == "Body"..propertyName then
            trackHumanoidValueInstance(child)
        end
    end))
    
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
	
    local pathMaid = main.modules.Maid.new()
    self._maid.pathMaid = pathMaid
    studsAwayToStop = studsAwayToStop or 0

    local agentHrpSize = self.hrp.Size
    local agentHead = self.clone.Head
    local pathParams = {
        AgentRadius = agentHrpSize.X,
        AgentHeight = (agentHrpSize.Y  *2) + agentHead.Size.Y,
        AgentCanJump = true,
    }
    local path = pathMaid:give(main.PathfindingService:CreatePath(pathParams))
    local cloneHRP = self.clone.HumanoidRootPart
    local cloneHumanoid = self.humanoid
    
    local waypoints = {}
    local currentWaypointIndex = 1

    local nextCheck = 0
    local previousPosition
    local nextIdleCheck = 0
    pathMaid:give(main.RunService.Heartbeat:Connect(function()
        -- This prevents the clone completely walking on top of the target position
        local timeNow = os.clock()
        if timeNow >= nextCheck then
            nextCheck = timeNow + 0.2
            local trackingPosition = (trackingBasePart and trackingBasePart.Position) or targetPosition
            local distanceFromClone = self:getDistanceFromClone(trackingPosition)
            local waypointsAway = #waypoints - currentWaypointIndex
            if distanceFromClone <= studsAwayToStop and waypointsAway < math.ceil(studsAwayToStop / 3) then
                self.reachedTarget = true
                self._maid.pathMaid = nil
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
    end))

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
                local part = pathMaid:give(Instance.new("Part"))
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
                self._maid.pathMaid = nil
                cloneHumanoid:MoveTo(self.hrp.Position)
            end)
        end
    end

    local function onWaypointReached(reached)
        if currentWaypointIndex == #waypoints then
            self.reachedTarget = true
            self._maid.pathMaid = nil
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

    pathMaid:give(path.Blocked:Connect(onPathBlocked))
    pathMaid:give(cloneHumanoid.MoveToFinished:Connect(onWaypointReached))
end

function Clone:follow(playerOrBasePart, studsAwayToStop)
    local followMaid = main.modules.Maid.new()
    self._maid.followMaid = followMaid

	local basePart
    if playerOrBasePart:IsA("Player") then
        main.modules.Thread.spawn(function()
            local currentChar = playerOrBasePart.Character or playerOrBasePart.CharacterAdded:Wait()
            basePart = currentChar:FindFirstChild("HumanoidRootPart") or currentChar:WaitForChild("HumanoidRootPart", 3)
        end)
        followMaid:give(playerOrBasePart.CharacterAdded:Connect(function(newChar)
            basePart = newChar:WaitForChild("HumanoidRootPart", 3)
        end))
    else
        basePart = playerOrBasePart
    end

    local targetPosition

    local function stillPresentCheck()
        local stillPresent = basePart:FindFirstAncestorWhichIsA("Workspace") or basePart:FindFirstAncestorWhichIsA("ReplicatedStorage")
        if not stillPresent then
            self._maid.followMaid = nil
            return false
        end
        return true
    end

    local STUDS_AWAY_TO_STOP = 2
    local REACTIVATE_DISTANCE = 1
    local MAXIMUM_DISTANCE_DRIFT = 5
    local finalStudsAwayToStop = studsAwayToStop or STUDS_AWAY_TO_STOP
    local finalReactiveDistance = finalStudsAwayToStop + REACTIVATE_DISTANCE
    followMaid:give(self.humanoid.MoveToFinished:Connect(function()
        if not stillPresentCheck() then return end
        local newTargetPosition = basePart.Position
        local distanceFromPreviousTarget = (newTargetPosition - targetPosition).Magnitude
        local distanceFromClone = self:getDistanceFromClone(newTargetPosition)
        targetPosition = newTargetPosition

        if (self.reachedTarget and distanceFromClone > finalReactiveDistance) or distanceFromPreviousTarget > MAXIMUM_DISTANCE_DRIFT then
            self:moveTo(targetPosition, finalStudsAwayToStop, basePart)
        elseif self.reachedTarget then
            local nextCheck = 0
            followMaid.positionChangedChecker = main.RunService.Heartbeat:Connect(function()
                local timeNow = os.clock()
                if timeNow >= nextCheck then
                    nextCheck = timeNow + 0.5
                    if not stillPresentCheck() then return end
                    if basePart then
                        newTargetPosition = basePart.Position
                        distanceFromClone = self:getDistanceFromClone(newTargetPosition)
                        if distanceFromClone > finalReactiveDistance then
                            followMaid.positionChangedChecker = nil
                            self:moveTo(newTargetPosition, finalStudsAwayToStop, basePart)
                        end
                    end
                end
            end)
        end
    end))

    followMaid:give(main.modules.Thread.delayUntil(function() return basePart end, function()
        targetPosition = basePart.Position
        self:moveTo(targetPosition)
    end))
end

function Clone:getDistanceFromClone(positionOfTarget)
    local clonePosition = self.hrp.Position
    local normalisedClonePosition = Vector3.new(clonePosition.X, positionOfTarget.Y, clonePosition.Z)
    local distanceFromClone = (positionOfTarget - normalisedClonePosition).Magnitude
    return distanceFromClone
end

function Clone:unfollow()
	self._maid.followMaid = nil
end

function Clone:destroy()
    if not self.destroyed then
        self.destroyed = true
        self._maid:clean()
        self.destroyedSignal:Fire()
        self.destroyedSignal:Destroy()
        for k, v in pairs(self) do
            if typeof(v) == "table" then
                self[k] = nil
            end
        end
    end
end
Clone.Destroy = Clone.destroy



return Clone