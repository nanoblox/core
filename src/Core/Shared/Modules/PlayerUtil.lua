-- LOCAL
local main = require(game.Nanoblox)
local PlayerUtil = {}



-- METHODS
function PlayerUtil.getCharacter(playerOrUserId)
	local player
	local playerUserId = tonumber(playerOrUserId)
	if playerUserId then
		player = main.Players:GetPlayerByUserId(playerUserId)
	elseif typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		player = playerOrUserId
	elseif main.isClient and playerOrUserId == nil then
		player = main.localPlayer
	end
	local character = player and player.Character
	return character
end

function PlayerUtil.getHead(playerOrUserId)
	local character = PlayerUtil.getCharacter(playerOrUserId)
	local head = character and character:FindFirstChild("Head")
	return head
end

function PlayerUtil.getHeadPos(playerOrUserId)
	local head = PlayerUtil.getHead(playerOrUserId)
	local headPos = head and head.Position
	return headPos
end

function PlayerUtil.getHRP(playerOrUserId)
	local character = PlayerUtil.getCharacter(playerOrUserId)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	return hrp
end

function PlayerUtil.getHRPPosition(playerOrUserId)
	local hrp = PlayerUtil.getHRP(playerOrUserId)
	local hrpPos = hrp and hrp.Position
	return hrpPos
end

function PlayerUtil.getHumanoid(playerOrUserId)
	local character = PlayerUtil.getCharacter(playerOrUserId)
	local humanoid = character and character:FindFirstChild("Humanoid")
	return humanoid
end

function PlayerUtil.getNameFromUserId(userId)
	return main.modules.Promise.new(function(resolve, reject)
		local player = main.Players:GetPlayerByUserId(userId)
		if player then
			resolve(player.Name)
		end
		local success, result = pcall(function() return main.Players:GetNameFromUserIdAsync(userId) end)
		if success then
			resolve(result)
		else
			reject(result)
		end
	end)
end

function PlayerUtil.getUserIdFromName(username)
	return main.modules.Promise.new(function(resolve, reject)
		local player = main.Players:FindFirstChild(username)
		if player and player:IsA("Player") then
			resolve(player.UserId)
		end
		local success, result = pcall(function() return main.Players:GetUserIdFromNameAsync(username) end)
		if success then
			resolve(result)
		else
			reject(result)
		end
	end)
end


return PlayerUtil