local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Adds given player(s) to the targetPlayer's Conga Line (where everyone mimics the targetPlayer). The targetPlayer defaults to the caller."
Command.aliases	= {"CopyCat"}
Command.opposites = {}
Command.tags = {"Fun"}
Command.prefixes = {}
Command.contributors = {82347291, 24670328}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.False
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilRevoked
Command.args = {"Players", "TargetPlayer"} --!!! this will change, not finished yet!!

function Command.invoke(task, args)
	local players = args[1]
	local targetPlayer = args[2] or task.caller
	print("players, targetPlayer (1) = ", players, targetPlayer)
	local targetUser = main.modules.PlayerStore:getUser(targetPlayer)
	if not targetUser then
		return task:kill()
	end

	-- If a conga list is already present, update it then end this task (we let the first task handle everything)
	local congaList = targetUser.temp:get("congaCommandList")
	if congaList then
		for _, plr in pairs(players) do
			congaList:insert(plr)
		end
		return task:kill()
	end

	-- This ends the task if the targetPlayer dies, respawns or leaves --!!! REMOVE THIS AFTERWARDS AND SET Command.persistence = main.enum.Persistence.UntilPlayerRespawns (or dies, test)
	local humanoid = main.modules.PlayerUtil.getHumanoid(targetPlayer)
	if not humanoid or humanoid.Health <= 0 then
		task:kill()
		return
	end
	task:give(humanoid.Died:Connect(function()
		task:kill()
	end))
	task:give(main.Players.PlayerRemoving:Connect(function(player)
		if player == targetPlayer then
			task:kill()
		end
	end))

	-- This removes a player from a conga line if they die --!!! ADD PLAYER LEAVING AND RESPAWNING DETECTION
	local trackingPlayers = {}
	local playerChattedRemote = task:give(main.modules.Remote.new("PlayerChatted-"..task.UID))
	local function trackPlayer(player)
		if not trackingPlayers[player] then
			trackingPlayers[player] = true
			local function untrackPlayer()
				trackingPlayers[player] = nil
				congaList:removeValue(player)
			end
			local humanoid = main.modules.PlayerUtil.getHumanoid(player)
			if not humanoid or humanoid.Health <= 0 then
				untrackPlayer()
				return
			end
			task:give(humanoid.Died:Connect(function()
				untrackPlayer()
			end))

			-- This listens for the players chat messages
			main.modules.ChatUtil.getSpeaker(player)
				:andThen(function(speaker)
					task:give(speaker.SaidMessage:Connect(function(chatMessage)
						local message = tostring(chatMessage.FilterResult)
						if message == "Instance" then
							message = chatMessage.FilterResult:GetChatForUserAsync(player.UserId)
						end
						if main.Chat.BubbleChatEnabled and chatMessage.MessageType == "Message" then
							playerChattedRemote:fireAllClients(player, message)
						end
					end))
				end)
				:catch(warn)
		end
	end

	-- This adds a tag to the targetPlayer's Humanoid to indicate they are a conga leader
	local tag = task:give(Instance.new("BoolValue"))
	tag.Name = "NanobloxCongaLeader"
	tag.Value = true
	tag.Parent = humanoid

	-- This creates the conga list and adds the players to it
	congaList = targetUser.temp:set("congaCommandList", {})
	for _, player in pairs(players) do
		trackPlayer(player)
		congaList:insert(player)
	end
	
	-- This listens for changes (i.e. players being added or removed from the conga line) and updates the clients
	local congaListRemote = task:give(main.modules.Remote.new("CongaList-"..task.UID))
	task:give(congaList.changed:Connect(function(index, playerOrNil)
		print("index, playerOrNil = ", index, playerOrNil)
		trackPlayer(playerOrNil)
		congaListRemote:fireAllClients(index, playerOrNil)
	end))
	task:invokeAllAndFutureClients(targetPlayer, congaList)

	-- This removes the conga list When the task is revoked
	task:give(function()
		targetUser.temp:set("congaCommandList", nil)
	end)
end

function Command.revoke(task)
	print("Conga was revoked!")
end



return Command