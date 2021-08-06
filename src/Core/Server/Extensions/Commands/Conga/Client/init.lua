local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(job, targetPlayer, congaList, delay, gap)

	-- This command could have been a few lines long, although I really wanted to provide the ability to customise the configuration.delay and configuration.gap, hence
	-- it became this mammoth instead (due to the additional details like jumps, motors, positions, etc that require tracking)
	local configuration = {
		delay = delay,
		gap = gap,
	}
	local framesPerSecond = 60
	local playerClones = {}
	local totalClones = 0
	local targetPlayerHumanoid = main.modules.PlayerUtil.getHumanoid(targetPlayer)
	local targetPlayerAnimator = main.modules.PlayerUtil.getAnimator(targetPlayer)
	local targetPlayerAnimate = targetPlayer.Character:FindFirstChild("Animate")
	local targetPlayerHRP = main.modules.PlayerUtil.getHRP(targetPlayer)
	local rigType = targetPlayerHumanoid.RigType
	local targetPlayerMotors = {}
	for _, motor in pairs(targetPlayer.Character:GetDescendants()) do
		if motor:IsA("Motor6D") then
			table.insert(targetPlayerMotors, motor)
		end
	end

	-- This listens for changes to DELAY or configuration.gap
	local tag = targetPlayerHumanoid:FindFirstChild("NanobloxCongaLeader")
	if tag then
		local tagAttributeValues = {
			NanobloxCongaDelay = "delay",
			NanobloxCongaGap = "gap",
		}
		job:add(tag.AttributeChanged:Connect(function(attributeName)
			local configKey = tagAttributeValues[attributeName]
			if configKey then
				configuration[configKey] = tag:GetAttribute(attributeName)
				for index, clone in pairs(playerClones) do
					clone:setIndex(index)
				end
			end
		end), "Disconnect")
	end

	-- This records the targetPlayers CFrames
	local movementHistory = {}
	local totalMovementHistory = 0
	local prevTargetPos = targetPlayerHRP.Position
	local prevDistanceTravelledThisFrame = 0
	local prevTargetMoveMagnitude = 0
	local targetMotorValues = {}
	local targetIsOnlyRunningOrWalking = false
	local targetIsStationaryJumping
	local targetIsStanding = false
	local stopCooldown = 0
	local lastTargetStopPosition = targetPlayerHRP.Position
	local totalFramesCompletelyStill = 0
	
	local movementAnims = {
		["WalkAnim"] = 2,
		["RunAnim"] = 2,
		["Animation1"] = 3,
		["Animation2"] = 3,
	}
	local fixedHistoryMovementAnims = {
		["ClimbAnim"] = true,
		["FallAnim"] = true,
		["JumpAnim"] = true,
	}
	local function checkIsOnlyRunningOrWalking(currentAnims)
		local requiredTotalAnims = -1
		for _, anim in pairs(currentAnims) do
			local requiredMax = movementAnims[anim.Name]
			if not requiredMax then
				return false
			end
			if requiredMax > requiredTotalAnims then
				requiredTotalAnims = requiredMax
			end
		end
		return requiredTotalAnims == #currentAnims
	end
	job:add(main.RunService.Stepped:Connect(function()
		
		-- Animation names don't replicate to other clients therefore we have to find the names ourself by comparing AnimationIds
		local currentAnimsOriginal = targetPlayerAnimator:GetPlayingAnimationTracks()
		local currentAnims = {}
		local totalAnims = 0
		for _, animTrack in pairs(currentAnimsOriginal) do
			local success = true
			if animTrack.Name == "Animation" then
				local thisAnimId = animTrack.Animation.AnimationId:match("%d+")
				for _, instance in pairs(targetPlayerAnimate:GetDescendants()) do
					success = false
					if instance:IsA("Animation") and instance.AnimationId:match("%d+") == thisAnimId then
						animTrack.Name = instance.Name
						animTrack.Animation.Name = instance.Name
						success = true
						break
					end
				end
			end
			if success then
				table.insert(currentAnims, animTrack)
				totalAnims += 1
				--table.insert(currentAnimNames, animTrack.Name) --HIDE
			end
		end
		--print(table.concat(currentAnimNames, " | ")) --HIDE
		
		local firstAnim = currentAnims[1]
		local firstAnimName = firstAnim and firstAnim.Name
		local isFixedAnim = fixedHistoryMovementAnims[firstAnimName]
		targetIsOnlyRunningOrWalking = checkIsOnlyRunningOrWalking(currentAnims)
		targetMotorValues = {}
		for _, motorToCopy in pairs(targetPlayerMotors) do
			targetMotorValues[motorToCopy.Name] = motorToCopy.Transform
		end
		local fixedMotors
		if isFixedAnim then
			fixedMotors = {}
			for _, motorToCopy in pairs(targetPlayerMotors) do
				fixedMotors[motorToCopy.Name] = motorToCopy.Transform
			end
		end

		--
		local newTargetPos = targetPlayerHRP.Position
		local distanceTravelledThisFrame = main.modules.DataUtil.round((prevTargetPos and (prevTargetPos - newTargetPos).Magnitude) or 0, 4)
		local xAndZDistanceTravelledThisFrame = main.modules.DataUtil.round((prevTargetPos and (Vector3.new(prevTargetPos.X, 0, prevTargetPos.Z) - Vector3.new(newTargetPos.X, 0, newTargetPos.Z)).Magnitude) or 0, 4)
		targetIsStanding = xAndZDistanceTravelledThisFrame <= 0 -- prev 0.2
		
		-- This determines if the player is jumping while stationary
		if not targetIsStationaryJumping and xAndZDistanceTravelledThisFrame == 0 and prevDistanceTravelledThisFrame == 0 and distanceTravelledThisFrame > 0 then
			targetIsStationaryJumping = true
		end
		if targetIsStationaryJumping and (xAndZDistanceTravelledThisFrame > 0 or distanceTravelledThisFrame == 0) then
			targetIsStationaryJumping = false
		end
		if targetIsStationaryJumping then
			isFixedAnim = false
			fixedMotors = nil
		end

		-- This prevents the second clone bunching up to the conga leader when stopping
		local targetMoveMagnitude = math.round(targetPlayerHumanoid.MoveDirection.Magnitude)
		if stopCooldown == 0 and targetMoveMagnitude == 0 and prevTargetMoveMagnitude == 1 then
			stopCooldown = 4
		elseif stopCooldown > 0 then
			stopCooldown -= 1
			if stopCooldown == 0 then
				lastTargetStopPosition = newTargetPos
			end
		end

		local targetIsMoving
		local distanceFromStopPosition = (newTargetPos - lastTargetStopPosition).Magnitude
		if not targetIsStationaryJumping then
			local distanceRequired = 0
			--------------
			-- This is here to prevent a dance like 'dance6' causing a movement detection while still allowing a stationary swim float to be detected
			if totalAnims > 1 and distanceFromStopPosition < 1 then
				distanceRequired = 0.1
			end
			local magFromPrev = (newTargetPos - prevTargetPos).Magnitude
			if magFromPrev == 0 then
				totalFramesCompletelyStill += 1
				if totalFramesCompletelyStill > 60 then
					lastTargetStopPosition = newTargetPos
				end
			elseif totalFramesCompletelyStill > 0 then
				totalFramesCompletelyStill = 0
			end
			--------------
			targetIsMoving = targetMoveMagnitude > 0 or (distanceTravelledThisFrame > distanceRequired and stopCooldown == 0)
			if targetIsMoving then
				totalMovementHistory += 1
				table.insert(movementHistory, {
					cf = targetPlayerHRP.CFrame, -- * CFrame.new(0, -targetJumpHeight, 0),
					hs = targetPlayerHRP.Size.Y*1.5,
					fm = fixedMotors,
					--jh = finalJumpHeight,
				})
			elseif isFixedAnim and not targetIsStanding then
				totalMovementHistory += 1
				table.insert(movementHistory, {
					fm = fixedMotors,
				})
			end
		end

		prevDistanceTravelledThisFrame = distanceTravelledThisFrame
		prevTargetPos = newTargetPos
		prevTargetMoveMagnitude = targetMoveMagnitude
	end), "Disconnect")

	-- This constructs the clone
	local playerChattedRemote = job:add(main.modules.Remote.new("PlayerChatted-"..job.UID), "destroy")
	local cloneStartIndex = 1
	local clonePastHistoryIndexes = {}
	local function createClone(index, player)
		-- This creates and modifies the clone
		local clone = job:add(main.modules.Clone.new(player, {forcedRigType = rigType}), "destroy")
		clone:anchorHRP(true)
		clone:setCollidable(false)
		clone.congaPlayer = player
		function clone:setIndex(index)
			self.index = index
			self.congaDelay = index*configuration.delay
			self.congaGap = index*configuration.gap*4
			playerClones[index] = clone
			totalClones = #playerClones
		end
		clone:setIndex(index)
		clone:disableAnimateScript()
		clone.motors = {}
		for _, motor in pairs(clone:GetDescendants()) do
			if motor:IsA("Motor6D") then
				clone.motors[motor.Name] = motor
			end
		end
		
		-- This updates the clients camera if they are that clone (and not the leader) and dont already have a clone in that line
		-- This is also responsible for hiding/showing a players real character
		local playerAlreadyExistsInLine = false
		for i, otherClone in pairs(playerClones) do
			if otherClone.congaPlayer == player and i ~= index then
				playerAlreadyExistsInLine = true
			end
		end
		local playerHumanoid = main.modules.PlayerUtil.getHumanoid(player)
		local isCongaLeader = targetPlayer == player--playerHumanoid and playerHumanoid:FindFirstChild("NanobloxCongaLeader")
		local isLocalPlayer = main.localPlayer == player
		local agent = main.modules.PlayerUtil.getAgent(player)
		if not isCongaLeader and not playerAlreadyExistsInLine then
			clone.janitor:add(agent:buff("HideCharacter"):set(true), "destroy")
			if isLocalPlayer then
				clone.janitor:add(agent:buff("Camera", "CameraSubject"):set(clone.humanoid), "destroy")
			end
		elseif isCongaLeader then
			clone.janitor:add(agent:buff("HideCharacter"):set(false):setWeight(2), "destroy")
			if isLocalPlayer then
				clone.janitor:add(agent:buff("Camera", "CameraSubject"):set(playerHumanoid):setWeight(2), "destroy")
			end
		end

		-- This mimics the players bubble chat above the clones head
		playerChattedRemote.onClientEvent:Connect(function(forPlayer, message)
			local cloneHead = clone:FindFirstChild("Head")
			if cloneHead and forPlayer == player then
				main.Chat:Chat(cloneHead, message, Enum.ChatColor.White)
			end
		end)

		local TableUtil = main.modules.TableUtil
		local cloneStepId = 0
		local cloneStepOverrideDetails
		
		-- This extends the pathway backwards so the clone instantly begins moving (if the very back clone)
		local cloneIndexString = tostring(index)
		local cloneHistoryIndex = clonePastHistoryIndexes[cloneIndexString]
		if not cloneHistoryIndex then
			local extendBackwardsAmount = clone.congaGap/index
			cloneHistoryIndex = cloneStartIndex - extendBackwardsAmount
			local baseRecord = movementHistory[cloneHistoryIndex+1]
			if not baseRecord then
				baseRecord = {
					cf = targetPlayerHRP.CFrame,
				}
			end
			local zGap = 0
			local zGapIncrement = configuration.gap/15
			for i = cloneStartIndex, cloneHistoryIndex, -1 do
				local existingRecord = movementHistory[i]
				if existingRecord then
					baseRecord = existingRecord
				else
					local newRecord = {
						cf = baseRecord.cf * CFrame.new(0, 0, zGap),
						hs = targetPlayerHRP.Size.Y*1.5,
						fm = nil,
						jh = 0,
					}
					movementHistory[i] = newRecord
				end
				zGap += zGapIncrement
			end
			cloneStartIndex = cloneHistoryIndex
		end
		local firstRecord = movementHistory[cloneHistoryIndex]
		if firstRecord then
			clone:setCFrame(firstRecord.cf)
		end

		clone.janitor:add(main.RunService.Heartbeat:Connect(function()

			-- This is important for tracking what frame we wish to update a Motor6D
			cloneStepId += 1

			-- This calculates the relative rotation of the lead clone
			local rotationOffset = 0
			local jumpOffset = 0
			local leadRecord = movementHistory[totalMovementHistory]
			local leadHistoryCFrame = leadRecord and leadRecord.cf
			if leadHistoryCFrame then
				local projectedVector = targetPlayerHRP.CFrame:VectorToObjectSpace(leadHistoryCFrame.lookVector) * Vector3.new(1, 0, 1)
				rotationOffset = ((math.deg(math.atan2(projectedVector.Z, projectedVector.X)) + 270) % 360) - 180
				jumpOffset = targetPlayerHRP.Position.Y - leadHistoryCFrame.Position.Y
			end

			-- This handles the relative positioning of the clone
			local sizeOffset = 0
			local fixedCFrame
			local function setCFrame(value, rotation, jumpHeight)
				local finalRotation = rotation or rotationOffset or 0
				local finalJumpOffset = jumpHeight or jumpOffset or 0
				clone:setCFrame(value * CFrame.new(0, sizeOffset+finalJumpOffset, 0) * CFrame.Angles(0, math.rad(finalRotation), 0))
			end
			local function updateHistoryIndex()
				local newIndex = cloneHistoryIndex + 1
				if clone.index == totalClones then
					-- If last clone in conga line, erase history
					cloneStartIndex = newIndex
					movementHistory[cloneHistoryIndex] = false
				end
				cloneHistoryIndex = newIndex
				clonePastHistoryIndexes[cloneIndexString] = newIndex
			end
			local function handlePositioning()
				local historyRecord = movementHistory[cloneHistoryIndex]
				while historyRecord == false do
					updateHistoryIndex()
					historyRecord = movementHistory[cloneHistoryIndex]
				end
				if not historyRecord then
					return
				end
				local historyFixedMotors = historyRecord.fm
				local historyCFrame = historyRecord.cf
				if not historyCFrame then
					updateHistoryIndex()
					return historyFixedMotors
				end
				sizeOffset = clone.hrp.Size.Y*1.5 - historyRecord.hs
				if totalMovementHistory - cloneHistoryIndex < clone.congaGap - 1 then
					return
				end
				if historyRecord.jh then
					-- This handles moving jumps
					--historyCFrame = historyCFrame*CFrame.new(0, historyRecord.jh, 0)
				end
				setCFrame(historyCFrame)
				updateHistoryIndex()
				return historyFixedMotors
			end

			-- This handles the mimicking of animations
			local function updateAnimValues(motorValues, fixedCFrameValue, rotation, jumpHeight)
				for name, value in pairs(motorValues) do
					local motor = clone.motors[name]
					if motor then
						motor.Transform = value
					end
				end
				if fixedCFrameValue then
					setCFrame(fixedCFrameValue, rotation, jumpHeight)
				else--if tmath.abs(rotation) > 0.5 then
					local historyRecord = movementHistory[cloneHistoryIndex]
					local cframe = historyRecord and historyRecord.cf
					if cframe then
						setCFrame(cframe, rotation, jumpHeight)
					end
				end
			end

			local fixedMotors = handlePositioning()
			local cloneMotorValues = fixedMotors or targetMotorValues

			local overrideDetails = cloneStepOverrideDetails and cloneStepOverrideDetails[tostring(cloneStepId)]
			if targetIsOnlyRunningOrWalking then
				-- This ensures the cancelling of all stationary delayed animations if the player begins walking again
				if cloneStepOverrideDetails then
					cloneStepOverrideDetails = nil
				end
			elseif not targetIsOnlyRunningOrWalking and not fixedMotors then
				local yieldTime = framesPerSecond*clone.congaDelay
				if yieldTime > 0 then
					-- This delays animations based upon configuration.delay
					local newStepId = cloneStepId + yieldTime
					cloneStepOverrideDetails = cloneStepOverrideDetails or {}
					cloneStepOverrideDetails[tostring(newStepId)] = {
						cloneMotorValues = TableUtil.copy(targetMotorValues),
						fixedCFrame = fixedCFrame,
						rotation = rotationOffset or 0,
						jumpHeight = jumpOffset,
					}
					if overrideDetails then
						updateAnimValues(overrideDetails.cloneMotorValues, overrideDetails.fixedCFrame, overrideDetails.rotation, overrideDetails.jumpHeight)
						return
					end
					return
				end
			end
			if overrideDetails then
				updateAnimValues(overrideDetails.cloneMotorValues, overrideDetails.fixedCFrame, overrideDetails.rotation, overrideDetails.jumpHeight)
				return
			end
			updateAnimValues(cloneMotorValues, fixedCFrame, rotationOffset, jumpOffset)

		end), "Disconnect")
	end

	-- This creates default clones
	for index, player in pairs(congaList) do
		createClone(index, player)
	end

	local congaListRemote = job:add(main.modules.Remote.new("CongaList-"..job.UID), "destroy")
	congaListRemote.onClientEvent:Connect(function(index, playerOrNil)
		local existingClone = playerClones[index]
		if playerOrNil == nil then
			if existingClone then
				existingClone:destroy()
			end
			playerClones[index] = nil
			totalClones = #playerClones
			return

		elseif existingClone and existingClone.congaPlayer ~= playerOrNil then
			existingClone:destroy()
			createClone(index, playerOrNil)

		elseif not existingClone then
			createClone(index, playerOrNil)

		end
		totalClones = #playerClones
	end)

end



return ClientCommand