local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(task, flyForce, bodyGyro, speed, noclip)
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
	
	-- This handles the toggling of flight when double jumped and pressing E
	local function toggleFlight()
		local sitBuff = task:buffPlayer("Humanoid", propertyLock):set(true)
		task:add(sitBuff, "destroy", "sitBuff")
		if noclip then
			local collisionId = main.modules.CollisionUtil.getIdFromName("NanobloxPlayersWithNoCollision")
			local collisionBuff = task:buffPlayer("CollisionGroupId"):set(collisionId)
			task:add(collisionBuff, "destroy", "collisionBuff")
		end
		flyForce.Enabled = not flyForce.Enabled
		bodyGyro.Enabled = not bodyGyro.Enabled
	end
	local doubleJumpedSignal = task:add(main.modules.HumanoidUtil.createDoubleJumpedSignal(humanoid), "destroy")
	doubleJumpedSignal:Connect(toggleFlight)
	main.ContextActionService:BindAction("ToggleNanobloxFlight", toggleFlight, true, Enum.KeyCode.E)

	task:loop(0, function()
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
		lastUpdate = tick()
		lastPosition = hrp.Position
	end)
end



return ClientCommand