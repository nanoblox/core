local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, targetPlayer, congaList)

	-- This command could have been a few lines long, although I really wanted to provide the ability to customise the ANIMATION_DELAY and GAP, hence
	-- it became this mammoth instead (due to the additional details like jumps, motors, positions, etc that require tracking)

	-- This records the targetPlayers details
	local ANIMATION_DELAY = 0.3
	local GAP = 4

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

	-- This records the targetPlayers CFrames
	local movementHistory = {}
	local totalMovementHistory = 0
	local prevTargetPos
	local targetMotorValues = {}
	local targetIsOnlyRunningOrWalking = false
	local targetIsJumpingFromStanding = false
	local targetIsJumping = false
	local targetJumpHeight = 0
	local targetJumpingStartPositionY
	local movingAfterStandingJump
	local STANDING_DISTANCE = 0.2
	local targetIsStanding = false
	--if targetPlayer == main.localPlayer then
		targetPlayerHumanoid.StateChanged:Connect(function(old, new)
			--print("old, new = ", old, new)
			if new == Enum.HumanoidStateType.Jumping or (new == Enum.HumanoidStateType.Freefall and not targetIsJumping) then
				--print("Target jumped!")
				targetJumpingStartPositionY = targetPlayerHRP.Position.Y
				targetIsJumping = true
				targetIsJumpingFromStanding = targetIsStanding
			elseif old == Enum.HumanoidStateType.Landed or (old == Enum.HumanoidStateType.Freefall and new ~= Enum.HumanoidStateType.Landed) then
				--print("Target jump ended!")
				targetIsJumping = false
				targetIsJumpingFromStanding = false
			end
		end)
	--end
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
	task:give(main.RunService.Stepped:Connect(function()
		
		-- Animation names don't replicate to other clients therefore we have to find the names ourself by comparing AnimationIds
		local currentAnimsOriginal = targetPlayerAnimator:GetPlayingAnimationTracks()
		local currentAnims = {}
		local currentAnimNames = {}
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
				--table.insert(currentAnimNames, animTrack.Name)
			end
		end
		--print(table.concat(currentAnimNames, " | "))
		
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
		local distanceTravelledThisFrame = (prevTargetPos and (prevTargetPos - newTargetPos).Magnitude) or 0
		local xAndZDistanceTravelledThisFrame = (prevTargetPos and (Vector3.new(prevTargetPos.X, 0, prevTargetPos.Z) - Vector3.new(newTargetPos.X, 0, newTargetPos.Z)).Magnitude) or 0
		prevTargetPos = newTargetPos
		targetIsStanding = xAndZDistanceTravelledThisFrame <= STANDING_DISTANCE
		if targetIsJumping then
			targetJumpHeight = newTargetPos.Y - targetJumpingStartPositionY
		end
		if targetJumpHeight ~= 0 and not targetIsJumping and firstAnimName ~= "FallAnim" then
			targetJumpHeight = 0
		end
		print("targetIsJumping, targetJumpHeight, targetIsJumpingFromStanding = ", targetIsJumping, targetJumpHeight, targetIsJumpingFromStanding)
		
		-- This cancels any fixed animations if a player jumps (while standing) then moves
		local finalJumpHeight = targetJumpHeight
		movingAfterStandingJump = targetIsJumpingFromStanding and xAndZDistanceTravelledThisFrame > 0
		if targetIsJumpingFromStanding then
			isFixedAnim = false
			fixedMotors = nil
			finalJumpHeight = 0
		end

		if not targetIsJumpingFromStanding or movingAfterStandingJump then
			local targetIsMoving = targetPlayerHumanoid.MoveDirection.Magnitude > 0 or distanceTravelledThisFrame > STANDING_DISTANCE
			if targetIsMoving then
				totalMovementHistory += 1
				table.insert(movementHistory, {
					cf = targetPlayerHRP.CFrame * CFrame.new(0, -targetJumpHeight, 0),
					hs = targetPlayerHRP.Size.Y*1.5,
					fm = fixedMotors,
					jh = finalJumpHeight,
				})
			elseif isFixedAnim and not targetIsStanding then
				totalMovementHistory += 1
				table.insert(movementHistory, {
					fm = fixedMotors,
				})
			end
		end
	end))

	-- This constructs the clone
	local cloneStartIndex = 1
	local function createClone(index, player)
		local clone = task:give(main.modules.Clone.new(player, {forcedRigType = rigType}))
		clone:anchorHRP(true)
		clone:setSize(1)
		clone:setCollidable(false)
		function clone:setIndex(index)
			self.index = index
			self.congaDelay = index*ANIMATION_DELAY
			self.congaGap = index*GAP*4
			playerClones[index] = clone
			totalClones = #playerClones
		end
		clone:setIndex(index)
		clone:disableAnimateScript()
		clone.motors = {}
		for _, motor in pairs(clone.clone:GetDescendants()) do
			if motor:IsA("Motor6D") then
				clone.motors[motor.Name] = motor
			end
		end
		
		local TableUtil = main.modules.TableUtil
		local cloneStepId = 0
		local cloneStepOverrideDetails
		
		-- This extends the pathway backwards so the clone instantly begins moving
		local extendBackwardsAmount = clone.congaGap/index
		local cloneHistoryIndex = cloneStartIndex - extendBackwardsAmount
		local baseRecord = movementHistory[cloneHistoryIndex+1]
		if not baseRecord then
			baseRecord = {
				cf = targetPlayerHRP.CFrame,
			}
		end
		local zGap = 0
		local zGapIncrement = GAP/15
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
		local firstRecord = movementHistory[cloneHistoryIndex]
		clone:setCFrame(firstRecord.cf)
		cloneStartIndex = cloneHistoryIndex

		clone.maid:give(main.RunService.Heartbeat:Connect(function()

			-- This is important for tracking what frame we wish to update a Motor6D
			cloneStepId += 1

			-- This handles the relative positioning of the clone
			local offset
			local fixedCFrame
			local function setCFrame(value)
				clone:setCFrame(value * CFrame.new(0, offset, 0))
			end
			local function updateHistoryIndex()
				local newIndex = cloneHistoryIndex + 1
				if clone.index == totalClones then
					-- If last clone in conga line, erase history
					cloneStartIndex = newIndex
					movementHistory[cloneHistoryIndex] = false
				end
				cloneHistoryIndex = newIndex
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
				offset = clone.hrp.Size.Y*1.5 - historyRecord.hs
				if targetIsJumpingFromStanding and not movingAfterStandingJump then
					-- This handles standing jumps
					local myPos = clone.hrp.Position
					local baseCFrame = clone.hrp.CFrame * CFrame.new(0, historyCFrame.Position.Y - myPos.Y, 0)
					fixedCFrame = baseCFrame * CFrame.new(0, targetJumpHeight, 0)
					return
				end
				if totalMovementHistory - cloneHistoryIndex < clone.congaGap - 1 then
					return
				end
				if historyRecord.jh then
					-- This handles moving jumps
					historyCFrame = historyCFrame*CFrame.new(0, historyRecord.jh, 0)
				end
				setCFrame(historyCFrame)
				updateHistoryIndex()
				return historyFixedMotors
			end

			-- This handles the mimicking of animations
			local function updateAnimValues(motorValues, fixedCFrameValue)
				for name, value in pairs(motorValues) do
					local motor = clone.motors[name]
					if motor then
						motor.Transform = value
					end
				end
				if fixedCFrameValue then
					setCFrame(fixedCFrameValue)
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
					-- This delays animations based upon ANIMATION_DELAY
					local newStepId = cloneStepId + yieldTime
					cloneStepOverrideDetails = cloneStepOverrideDetails or {}
					cloneStepOverrideDetails[tostring(newStepId)] = {
						cloneMotorValues = TableUtil.copy(targetMotorValues),
						fixedCFrame = fixedCFrame,
					}
					if overrideDetails then
						updateAnimValues(overrideDetails.cloneMotorValues, overrideDetails.fixedCFrame)
						return
					end
					return
				end
			end
			if overrideDetails then
				updateAnimValues(overrideDetails.cloneMotorValues, overrideDetails.fixedCFrame)
				return
			end
			updateAnimValues(cloneMotorValues, fixedCFrame)

		end))
	end

	-- This creates default clones
	for index, player in pairs(congaList) do
		createClone(index, player)
	end

	local remote = task:give(main.modules.Remote.new(task.UID))
	remote.onClientEvent:Connect(function(index, playerOrNil)
		local existingClone = playerClones[index]
		if playerOrNil == nil then
			existingClone:Destroy()
			if index < totalClones then
				for i = index+1, totalClones do
					local clone = playerClones[i]
					local newIndex = i-1
					clone:setIndex(newIndex)
					playerClones[newIndex] = clone -- CLONE SHIFT
				end
			end
			playerClones[totalClones] = nil
			return

		elseif existingClone == nil then
			createClone(index, playerOrNil)
		end
		--[[
			ben		matt	sam		tom
			1    	2    	3   	4

			ben		false	sam		tom
			1    	2    	3   	4

			ben		sam		tom		tom
			1    	2    	3   	4

			ben		sam		tom
			1    	2    	3 
		--]]
		--print("CLIENT index, playerOrNil = ", index, playerOrNil)
	end)

end



return ClientCommand