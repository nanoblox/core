-- LOCAL
local main = require(game.Nanoblox)
local PlayerUtil = {}



-- METHODS
function PlayerUtil.getCharacter(player)
	local character = player and player.Character
	return character
end

function PlayerUtil.getHead(player)
	local character = PlayerUtil.getCharacter(player)
	local head = character and character:FindFirstChild("Head")
	return head
end

function PlayerUtil.getHeadPos(player)
	local head = PlayerUtil.getHead(player)
	local headPos = head and head.Position
	return headPos
end

function PlayerUtil.getHRP(player)
	local character = PlayerUtil.getCharacter(player)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	return hrp
end

function PlayerUtil.getHRPPosition(player)
	local hrp = PlayerUtil.getHRP(player)
	local hrpPos = hrp and hrp.Position
	return hrpPos
end

function PlayerUtil.getHumanoid(player)
	local character = PlayerUtil.getCharacter(player)
	local humanoid = character and character:FindFirstChild("Humanoid")
	return humanoid
end


return PlayerUtil