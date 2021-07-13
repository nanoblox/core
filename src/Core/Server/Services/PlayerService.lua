-- LOCAL
local main = require(game.Nanoblox)
local PlayerStore = main.modules.PlayerStore
local PlayerService = {}
local Signal = main.modules.Signal



-- EVENTS
PlayerService.playerAdded = Signal.new()
PlayerService.userLoaded = Signal.new()
PlayerService.playerLoaded = Signal.new()



-- PLAYED ADDED
local function callEventMethod(eventName, ...)
	-- We have methods in addition to events to ensure data is loaded
	-- asynchronously, in order, and handled correctly
	for serviceName, service in pairs(main.services) do
		local method = service[eventName.."Method"]
		if method then
			local returnValue = method(...)
			if returnValue == false then
				return true
			end
		end
	end
	PlayerService[eventName]:Fire()
	return false
end

local function playerAdded(player)
	
	-- Call .playerAdded for all services
	local cancelThread = callEventMethod("playerAdded", player)
	PlayerService.playerAdded:Fire(player)
	if cancelThread then
		return
	end
	
	-- Setup collision group
	main.modules.CollisionUtil.joinPlayerCollisionGroup(player)

	-- Setup user object
	local user = PlayerStore:createUser(player)
	user.agent = main.modules.Agent.new(player, true) -- an agent is automatically destroyed on player leave so no need to give to janitor
	user:initAutoSave()

	-- Listen for chat
	player.Chatted:Connect(function(message)
		main.services.CommandService.processMessage(user, message)
	end)

	-- Create additional user methods and events
	user.isRolesLoaded = false
	user.rolesLoaded = main.modules.Signal.new()
	function user:waitForRoles()
		local loaded = user.isRolesLoaded or user.rolesLoaded:Wait()
		return
	end
	
	-- Wait for user data to load
	user:waitUntilLoaded()
	
	-- Call .userLoaded for all services
	callEventMethod("userLoaded", user)
	PlayerService.userLoaded:Fire(user)
	
	-- Call .playerLoaded for all services
	callEventMethod("playerLoaded", player, user)
	PlayerService.playerLoaded:Fire(player, user)
	
end


-- Wait until every other service has initialised and data loaded before beginning
function PlayerService.loaded()
	-- Call PlayerAdded when player enters game
	main.Players.PlayerAdded:Connect(playerAdded)
	
	-- Call PlayerAdded for early joiners
	for _, player in pairs(main.Players:GetPlayers()) do
		playerAdded(player)
	end
	
	-- PLAYER REMOVING
	main.Players.PlayerRemoving:Connect(function(player)
		PlayerStore:removeUser(player)
	end)
end



return PlayerService