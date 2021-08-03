-- LOCAL
local main = require(game.Nanoblox)
local HumanoidUtil = {}



-- METHODS
function HumanoidUtil.unseat(humanoid)
	-- Credit to Quenty and Nevermore Engine for this trick:
	-- https://github.com/Quenty/NevermoreEngine/blob/a98f213bb46a3c1dbe311b737689c5cc820a4901/Modules/Shared/Character/HumanoidUtils.lua#L24
	local wasSeated = false
	if humanoid.SeatPart then
		local weld = humanoid.SeatPart:FindFirstChild("SeatWeld")
		if weld then
			wasSeated = true
			weld:Destroy()
		end
		humanoid.SeatPart:Sit(nil)
	end
	humanoid.Sit = false
	return wasSeated
end

function HumanoidUtil.createDoubleJumpedSignal(humanoid)
	local jumps = 0
	local jumpDebounce = false
	local signal = main.modules.Signal.new()
	local Thread = main.modules.Thread
	local janitor = main.modules.Janitor.new()
	janitor:add(humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
		if jumpDebounce then
			return
		end
		jumpDebounce = true
		jumps = jumps + 1
		if jumps == 4 then
			signal:Fire()
		end
		Thread.spawn(function()
			jumpDebounce = false
		end)
		Thread.delay(0.2, function()
			jumps = jumps - 1
		end)
	end), "Disconnect")
	signal.janitor = janitor
	return signal
end



return HumanoidUtil