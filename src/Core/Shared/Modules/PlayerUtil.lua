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

function PlayerUtil.getHumanoidRootPart(playerOrUserId)
	local character = PlayerUtil.getCharacter(playerOrUserId)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	return hrp
end
PlayerUtil.getHRP = PlayerUtil.getHumanoidRootPart

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

local agents = {}
function PlayerUtil.getAgent(player)
	local agent = agents[player]
	if not agent then
		-- Agents automatically destroy themselves when their associated player leaves so we don't need to worry about cleaning them up
		agent = main.modules.Agent.new(player, true)
		agents[player] = agent
	end
	return agent
end

local hiddenAgents = {}
function PlayerUtil.hidePlayer(player)
	if main.isClient and player == nil then
		player = main.localPlayer
	end
	local hiddenKey = main.modules.DataUtil.generateUID()
	local agent = PlayerUtil.getAgent(player)
	if agent then
		-- We make the player invisible and freeze them, instead of parenting them to ReplicatedStorage, so that they can still perform actions such as resetting
		local hiddenDetail = hiddenAgents[agent]
		if hiddenDetail == nil then
			local buffs = {}
			table.insert(buffs, agent:buff("BodyTransparency"):set(1):setWeight(999))
			table.insert(buffs, agent:buff("Humanoid", "WalkSpeed"):set(0):setWeight(999))
			main.modules.Thread.delay(0.1, function() -- This allows enough time for the Humanoid to register as 'stopped'
				if hiddenAgents[agent] then
					table.insert(buffs, agent:buff("HumanoidRootPart", "Anchored"):set(true):setWeight(999))
				end
			end)
			main.modules.ChatUtil.hideChat(player)
			hiddenAgents[agent] = {buffs, hiddenKey}
		else
			hiddenDetail[2] = hiddenKey
		end
	end
	return hiddenKey
end

function PlayerUtil.showPlayer(player)
	if main.isClient and player == nil then
		player = main.localPlayer
	end
	local agent = PlayerUtil.getAgent(player)
	local hiddenDetail = hiddenAgents[agent]
	if hiddenDetail then
		hiddenAgents[agent] = nil
		local buffs = hiddenDetail[1]
		for _, buff in pairs(buffs) do
			buff:destroy()
		end
		main.modules.ChatUtil.showChat(player)
	end
end

function PlayerUtil.isPlayerHidden(player)
	if main.isClient and player == nil then
		player = main.localPlayer
	end
	local agent = PlayerUtil.getAgent(player)
	local hiddenDetail = hiddenAgents[agent]
	if hiddenDetail then
		return true, hiddenDetail[2]
	end
	return false
end



return PlayerUtil