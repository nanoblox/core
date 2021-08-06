local main = require(game.Nanoblox)
local ClientCommand =	{}



function ClientCommand.invoke(job, speed)
	local hrp = main.modules.PlayerUtil.getHRP()
	local humanoid = main.modules.PlayerUtil.getHumanoid()
	if not hrp or not humanoid then
		return
	end
	
	local enabled = false
	local loopThread
	local function toggleFlight()
		enabled = not enabled

		-- This handles the chracter buffs
		local buffDetails = {
			sitBuff = {{"Humanoid", "PlatformStand"}, {true}, 3},
			anchorBuff = {{"HumanoidRootPart", "Anchored"}, {true}, 3},
		}
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

		-- This handles the setting of the HRP's position
		if not enabled then
			if loopThread then
				loopThread:disconnect()
			end
		else
			local lastUpdate = tick()
			local camera = main.modules.CameraUtil.camera
			loopThread = job:loop(0, function()
				local delta = tick()-lastUpdate
				local look = (camera.Focus.p - camera.CFrame.p).unit
				local move = main.modules.MovementUtil.getNextMovement(delta, speed)
				local pos = hrp.Position
				hrp.CFrame = CFrame.new(pos,pos+look) * move
				lastUpdate = tick()
			end)
		end
	end

	-- This enables flight
	toggleFlight()

	-- This handles the toggling of flight when double jumping
	local doubleJumpSignal = main.modules.MovementUtil.getSignal("DoubleJump")
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