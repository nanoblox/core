local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, targetPlayer, congaList)

	-- This records the targetPlayers details
	local INTERVAL_DELAY = 0.3
	local FRAMES_PER_SECOND = 60
	local STUDS_APART = 2
	local playerClones = {}
	local targetPlayerHumanoid = main.modules.PlayerUtil.getHumanoid(targetPlayer)
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
	local targetIsMoving = false
	task:give(main.RunService.Stepped:Connect(function()
		targetIsMoving = targetPlayerHumanoid.MoveDirection.Magnitude > 0
		if targetIsMoving then
			table.insert(movementHistory, 1, targetPlayerHRP.CFrame)
		end
	end))

	local function createClone(index, player)
		-- This constructs the clone
		local clone = task:give(main.modules.Clone.new(player, {forcedRigType = rigType}))
		clone:anchorHRP(true)
		clone:setSize(1)
		clone:setCollidable(false)
		clone.congaDelay = index*INTERVAL_DELAY*FRAMES_PER_SECOND
		clone.motors = {}
		for _, motor in pairs(clone.clone:GetDescendants()) do
			if motor:IsA("Motor6D") then
				clone.motors[motor.Name] = motor
			end
		end
		playerClones[index] = clone

		-- This mimics the actions of the targetPlayer
		clone.maid:give(main.RunService.Stepped:Connect(function()
			local motorValues = {}
			local desiredCFrame = movementHistory[1+clone.congaDelay]--[clone.congaDelay]
			--print("desiredCFrame = ", desiredCFrame, clone.congaDelay, movementHistory)
			for _, motorToCopy in pairs(targetPlayerMotors) do
				local motor = clone.motors[motorToCopy.Name]
				if motor.Parent ~= nil then
					motorValues[motor] = motorToCopy.Transform
				end
			end
			local delay = (targetIsMoving and 0) or clone.congaDelay
			for i = 1, delay do
				main.RunService.Stepped:Wait()
				if task.isDead then
					return
				end
			end--]]
			for motor, value in pairs(motorValues) do
				motor.Transform = value
			end
			if desiredCFrame then
				local offset = clone.hrp.Size.Y*1.5 - player.Character.HumanoidRootPart.Size.Y*1.5
				clone:setCFrame(desiredCFrame * CFrame.new(0, offset, 0))
			end
		end))
	end

	-- This creates default clones
	for index, player in pairs(congaList) do
		createClone(index, player)
	end

	local movementPathway = {}

	local remote = task:give(main.modules.Remote.new(task.UID))
	remote.onClientEvent:Connect(function(index, playerOrNil)
		local existingClone = playerClones[index]
		local totalClones = #playerClones
		if playerOrNil == nil then
			existingClone:Destroy()
			if index < totalClones then
				for i = index+1, totalClones do
					local clone = playerClones[i]
					local newIndex = i-1
					clone.congaDelay = newIndex*INTERVAL_DELAY*FRAMES_PER_SECOND
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
		print("CLIENT index, playerOrNil = ", index, playerOrNil)
	end)

end



return ClientCommand