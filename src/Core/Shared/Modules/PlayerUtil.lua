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
	local humanoid = character and (character:FindFirstChild("Humanoid") or character:FindFirstChildOfClass("Humanoid"))
	return humanoid
end

function PlayerUtil.getAnimator(playerOrUserId)
	local humanoid = PlayerUtil.getHumanoid(playerOrUserId)
	local animator = humanoid and (humanoid:FindFirstChild("Animator") or humanoid:FindFirstChildOfClass("Animator"))
	return humanoid
end

function PlayerUtil.getNameFromUserId(userId)
	return main.modules.Promise.defer(function(resolve, reject)
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
	return main.modules.Promise.defer(function(resolve, reject)
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

function PlayerUtil.loadTrack(player, animationId)
	local humanoid = main.modules.PlayerUtil.getHumanoid(player)
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local animation = Instance.new("Animation")
	animation.Name = "Nanoblox-"..animationId
	animation.AnimationId = "rbxassetid://"..animationId
	animation.Parent = player.Character
	return animator:LoadAnimation(animation)
end

local hiddenCharacters = {}
function PlayerUtil.hideCharacter(playerOrCharacter)
	local storageName = "NanobloxHiddenCharacters"
	local hiddenStorage = main.ReplicatedStorage:FindFirstChild(storageName)
	if not hiddenStorage then
		hiddenStorage = Instance.new("Folder")
		hiddenStorage.Name = storageName
		hiddenStorage.Parent = main.ReplicatedStorage
	end
	if main.isClient and playerOrCharacter == nil then
		playerOrCharacter = main.localPlayer
	end
	local character = (playerOrCharacter:IsA("Player") and playerOrCharacter.Character) or playerOrCharacter
	local hiddenKey = main.modules.DataUtil.generateUID()
	local hiddenDetail = hiddenCharacters[character]
	if character then
		if hiddenDetail == nil then
			hiddenCharacters[character] = {(character.Parent or workspace), hiddenKey}
			character.Parent = hiddenStorage
		else
			hiddenDetail[2] = hiddenKey
		end
	end
	return hiddenKey
end

function PlayerUtil.showCharacter(playerOrCharacter)
	if main.isClient and playerOrCharacter == nil then
		playerOrCharacter = main.localPlayer
	end
	local character = (playerOrCharacter:IsA("Player") and playerOrCharacter.Character) or playerOrCharacter
	local hiddenDetail = hiddenCharacters[character]
	if hiddenDetail then
		hiddenCharacters[character] = nil
		character.Parent = hiddenDetail[1]
	end
end

function PlayerUtil.isHidden(playerOrCharacter)
	if main.isClient and playerOrCharacter == nil then
		playerOrCharacter = main.localPlayer
	end
	local character = (playerOrCharacter:IsA("Player") and playerOrCharacter.Character) or playerOrCharacter
	local hiddenDetail = hiddenCharacters[character]
	if hiddenDetail then
		return true, hiddenDetail[2]
	end
	return false
end



return PlayerUtil