-- LOCAL
local main = require(game.Nanoblox)
local MovementUtil = {}



-- METHODS
function MovementUtil.getNextMovement(deltaTime, speed)
	local nextMove = Vector3.new()
	local directions = {
		Left = Vector3.new(-1, 0, 0);
		Right = Vector3.new(1, 0, 0);
		Forwards = Vector3.new(0, 0, -1);
		Backwards = Vector3.new(0, 0, 1);
		Up = Vector3.new(0, 1, 0);
		Down = Vector3.new(0, -1, 0);
	}
	if main.device == "Computer" then
		for i,v in pairs(main.movementKeysPressed) do
			local vector = directions[v]
			if vector then
				nextMove = nextMove + vector
			end
		end
	else
		local humanoid = main.modules.PlayerUtil.getHumanoid()
		local hrp = main.modules.PlayerUtil.getHRP()
		if humanoid then
			local md = humanoid.MoveDirection
			for i,v in pairs(directions) do
				local isFor = false
				if i == "Forwards" or i == "Backwards" then
					isFor = true
				end
				local cframe = hrp.CFrame
				local noRot = CFrame.new(cframe.p)
				local x, y, z = (workspace.CurrentCamera.CFrame - workspace.CurrentCamera.CFrame.Position):ToEulerAnglesXYZ()
				local newCFrame = noRot * CFrame.Angles(isFor and z or x, y, z)
				local vector = ((newCFrame*CFrame.new(v)) - hrp.CFrame.p).p;
				if (vector - md).magnitude <= 1.05 and md ~= Vector3.new(0,0,0) then
					nextMove = nextMove + v
				end
			end
		end
	end
	return CFrame.new(nextMove * speed * deltaTime), nextMove
end



return MovementUtil