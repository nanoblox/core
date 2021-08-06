-- LOCAL
local main = require(game.Nanoblox)
local MovementUtil = {
	characterActionSignals = {}
}

local activeMovements = {}
local movementKeys = {
	[Enum.KeyCode.Left] = "Left",
	[Enum.KeyCode.Right] = "Right",
	[Enum.KeyCode.Up] = "Forwards",
	[Enum.KeyCode.Down] = "Backwards",
	[Enum.KeyCode.A] = "Left",
	[Enum.KeyCode.D] = "Right",
	[Enum.KeyCode.W] = "Forwards",
	[Enum.KeyCode.S] = "Backwards",
	[Enum.KeyCode.Space] = "Up",
	[Enum.KeyCode.R] = "Up",
	[Enum.KeyCode.Q] = "Down",
	[Enum.KeyCode.LeftControl] = "Down",
	[Enum.KeyCode.F] = "Down",
}
local directions = {
	Left = Vector3.new(-1, 0, 0);
	Right = Vector3.new(1, 0, 0);
	Forwards = Vector3.new(0, 0, -1);
	Backwards = Vector3.new(0, 0, 1);
	Up = Vector3.new(0, 1, 0);
	Down = Vector3.new(0, -1, 0);
}

local movementSignals = {
	-------------------------------------
	["Jump"] = function(signal)
		local jumping = false
		main.UserInputService.JumpRequest:Connect(function()
			if not jumping then
				jumping = true
				signal:Fire(jumping)
			end
		end)
		main.UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
			local keyCode = input.KeyCode
			if (jumping and keyCode == Enum.KeyCode.Space and gameProcessedEvent == false) -- Keyboard
			or (jumping and keyCode == Enum.KeyCode.Unknown and gameProcessedEvent == true) -- Touchpad
			or (jumping and keyCode == Enum.KeyCode.ButtonA) then -- Controller
				jumping = false
				signal:Fire(jumping)
			end
		end)
	end,

	-------------------------------------
	["DoubleJump"] = function(signal)
		local jumpSignal = MovementUtil.getSignal("Jump")
		local jumps = 0
		jumpSignal:Connect(function(isActive)
			if isActive then
				jumps += 1
				task.delay(0.2, function()
					jumps -= 1
				end)
				if jumps >= 2 then
					signal:Fire()
				end
			end
		end)
	end,

	-------------------------------------
}



-- SETUP
-- This listens for movement key changes
main.UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	local movement = movementKeys[input.KeyCode]
	if not gameProcessedEvent and movement then
		local count = activeMovements[movement]
		if not count then
			count = 0
		end
		activeMovements[movement] = count + 1
	end
end)

main.UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	local movement = movementKeys[input.KeyCode]
	if movement then
		local count = activeMovements[movement]
		if count then
			count -= 1
			if count == 0 then
				activeMovements[movement] = nil
			end
		end
	end
end)



-- METHODS
function MovementUtil.getSignal(actionName)
	local signal = MovementUtil.characterActionSignals[actionName]
	if not signal then
		signal = main.modules.Signal.new()
		MovementUtil.characterActionSignals[actionName] = signal
		movementSignals[actionName](signal)
	end
	return signal
end

function MovementUtil.getNextMovement(deltaTime, speed)
	local nextMove = Vector3.new()
	local combinedMovements = {}

	-- This determines movements based upon keys pressed
	for movement, _ in pairs(activeMovements) do
		combinedMovements[movement] = true
	end
	local humanoid = main.modules.PlayerUtil.getHumanoid()
	local camera = main.modules.CameraUtil.camera
	if humanoid then

		-- This determines movements based upon the Humanoid.MoveDirection
		-- Thank you EgoMoose for a great deal of this
		-- You sir are a true legend
		local REQUIRED_VALUE = 0.7
		
		local rightValue = humanoid.MoveDirection:Dot(camera.CFrame.RightVector)
		if rightValue >= REQUIRED_VALUE then
			combinedMovements["Right"] = true
		elseif rightValue <= -REQUIRED_VALUE then
			combinedMovements["Left"] = true
		end
		
		local upValue = humanoid.MoveDirection:Dot(camera.CFrame.UpVector)
		local lookValue = humanoid.MoveDirection:Dot(camera.CFrame.LookVector)
		if (upValue < 0 and lookValue > 0) or (upValue > 0 and lookValue < 0) then
			upValue = -upValue
		end
		local forwardsValue = upValue + lookValue
		if forwardsValue >= REQUIRED_VALUE then
			combinedMovements["Forwards"] = true
		elseif forwardsValue <= -REQUIRED_VALUE then
			combinedMovements["Backwards"] = true
		end
	end

	-- This retrieves the corresponding movement vectors and adds them together
	for movement, _ in pairs(combinedMovements) do
		local directionVector = directions[movement]
		nextMove += directionVector
	end

	return CFrame.new(nextMove * speed * deltaTime), nextMove
end



return MovementUtil