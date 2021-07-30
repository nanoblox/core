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



return HumanoidUtil