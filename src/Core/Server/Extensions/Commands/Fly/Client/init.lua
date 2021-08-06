local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(job, flyForce, bodyGyro, speed, noclip, propertyLock)
	local hrp = main.modules.PlayerUtil.getHRP()
	local humanoid = main.modules.PlayerUtil.getHumanoid()
	if not hrp or not humanoid then
		return
	end

	local TILT_MAX = 25
	local TILT_INCREMENT = 1

	local tiltAmount = 0
	local static = 0
	local lastUpdate = tick()
	local lastPosition = hrp.Position
	local camera = main.modules.CameraUtil.camera
	local MovementUtil = main.modules.MovementUtil
	
	local enabled = false
	local loopThread
	local function toggleFlight()
		enabled = not enabled

		-- This handles the chracter buffs
		local buffDetails = {
			sitBuff = {{"Humanoid", propertyLock}, {true}, 3},
		}
		if noclip then
			buffDetails.collisionBuff = {{"CollisionGroupId"}, {main.modules.CollisionUtil.getIdFromName("NanobloxPlayersWithNoCollision")}, 3}
		end
		if enabled then
			for buffName, detail in pairs(buffDetails) do
				local buff = job:buffPlayer(unpack(detail[1])):set(unpack(detail[2])):setWeight(detail[3])
				job:add(buff, "destroy", buffName)
			end
		else
			for buffName, _ in pairs(buffDetails) do
				local buff = job.janitor:get(buffName)
				if buff then
					buff:destroy()
				end
			end
		end

		-- This handles the enabling and disabling of flying forces
		local maxForce = (enabled and Vector3.new(100000, 100000, 100000)) or Vector3.new(0, 0, 0)
		flyForce.MaxForce = maxForce
		bodyGyro.MaxTorque = maxForce

		-- This handles flight direction and power
		if not enabled then
			if loopThread then
				loopThread:disconnect()
			end
		else
			loopThread = job:loop(0, function()
				local delta = tick()-lastUpdate
				local look = (camera.Focus.Position - camera.CFrame.Position).unit
				local move, directionalVector = main.modules.MovementUtil.getNextMovement(delta, speed*10)
				local pos = hrp.Position
				local targetCFrame = CFrame.new(pos,pos+look) * move
				local targetD = 750 + (speed*0.2)
				if noclip then
					targetD = targetD/2
				end
				if move.Position ~= Vector3.new() then
					static = 0
					flyForce.D = targetD
					tiltAmount = tiltAmount + TILT_INCREMENT
					flyForce.Position = targetCFrame.Position
				else
					static = static + 1
					tiltAmount = 1
					local maxMag = 6
					local mag = (hrp.Position - lastPosition).magnitude
					if mag > maxMag and static >= 4 then
						flyForce.Position = hrp.Position
					end
				end
				if math.abs(tiltAmount) > TILT_MAX then
					tiltAmount = TILT_MAX
				end
				if flyForce.D == targetD then
					local tiltX = tiltAmount * directionalVector.X * -0.5
					local tiltZ = (noclip and 0) or tiltAmount * directionalVector.Z
					bodyGyro.CFrame = targetCFrame * CFrame.Angles(math.rad(tiltZ), 0, 0)
				end
				humanoid[propertyLock] = true
				lastUpdate = tick()
				lastPosition = hrp.Position
			end)
		end
	end

	-- This enables flight
	toggleFlight()

	-- This handles the toggling of flight when double jumping
	local doubleJumpSignal = MovementUtil.getSignal("DoubleJump")
	job:add(doubleJumpSignal:Connect(toggleFlight), "Disconnect")

	-- This handles the toggling of flight when pressing E
	local function toggleFlightByKey(_, input)
		if input == Enum.UserInputState.End then
			toggleFlight()
		end
	end
	local contextId = "NanobloxNoclip-"..job.UID
	main.ContextActionService:BindAction(contextId, toggleFlightByKey, false, Enum.KeyCode.E)
	job:add(function()
		main.ContextActionService:UnbindAction(contextId)
	end)

end



return ClientCommand