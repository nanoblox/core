-- CONFIG
-- This is important!!
-- This defines the folder to store all remotes
-- It must be present before the game initiates
local remotesStorage = require(game.Nanoblox).shared.Remotes



-- LOCAL
local Maid = require(script.Parent.Maid)
local Promise = require(script.Parent.Promise)
local Remote = {}
local players = game:GetService("Players")
local requestDetails = {}
local remotes = {}



-- BEHAVIOUR
players.PlayerAdded:Connect(function(player)
	local detail = {
		requests = 0,
		nextRefresh = 0,
	}
	requestDetails[player] = detail
end)
players.PlayerRemoving:Connect(function(player)
	requestDetails[player] = nil
end)



-- CONSTRUCTOR
function Remote.new(name, requestLimit, refreshInterval)
	local self = {}
	setmetatable(self, Remote)
	
	local maid = Maid.new()
	self._maid = maid
	
	local remoteFolder = maid:give(Instance.new("Folder"))
	remoteFolder.Name = name
	remoteFolder.Parent = remotesStorage
	self.remoteFolder = remoteFolder
	
	self.name = name
	self.container = {}
	self.requestLimit = requestLimit or 20
	self.refreshInterval = refreshInterval or 5
	
	assert(remotes[name] == nil, ("Remote %s already exits!"):format(name))
	remotes[name] = self

	return self
end



-- METAMETHODS
function Remote:__index(index)
	local newIndex = Remote[index]
	if not newIndex then
		local remoteInstance, indexFormatted = self:_checkRemoteInstance(index)
		if remoteInstance then
			newIndex = {}
			local customFunction
			function newIndex:Connect(event)
				customFunction = event
			end
			remoteInstance[indexFormatted]:Connect(function(...)
				local requestSuccess, errorMessage = self:_checkRequest(...)
				if not requestSuccess then
					return requestSuccess, errorMessage
				end
				return customFunction(...)
			end)
		end
	end
	return newIndex
end

function Remote:__newindex(index, value)
	local remoteInstance, indexFormatted = self:_checkRemoteInstance(index)
	if not remoteInstance then
		rawset(self, index, value)
		return
	end
	local customFunction = value
	remoteInstance[indexFormatted] = function(...)
		local requestSuccess, errorMessage = self:_checkRequest(...)
		if not requestSuccess then
			return requestSuccess, errorMessage
		end
		return customFunction(...)
	end
end
		
		
		
-- METHODS
function Remote:_checkRemoteInstance(index)
	local remoteTypes = {
		["onServerEvent"] = "RemoteEvent",
		["onServerInvoke"] = "RemoteFunction",
	}
	local remoteType = remoteTypes[index]
	if remoteType then
		local remoteInstance = self:_getRemoteInstance(remoteType)
		local indexFormatted = index:sub(1,1):upper()..index:sub(2)
		return remoteInstance, indexFormatted
	end
end

function Remote:_checkRequest(player, ...)
	local detail = requestDetails[player]
	local currentTime = os.clock()
	if currentTime >= detail.nextRefresh then
		detail.nextRefresh = currentTime + self.refreshInterval
		detail.requests = 0
	end
	if detail.requests >= self.requestLimit then
		local errorMessage = ("Exceeded request limit. Wait %s before sending another request."):format(detail.nextRefresh - currentTime)
		return false, errorMessage
	end
	detail.requests +=1
	return true
end
	
function Remote:_getRemoteInstance(remoteType)
	local remoteInstance = self.container[remoteType]
	if not remoteInstance then
		remoteInstance = Instance.new(remoteType)
		remoteInstance.Parent = self.remoteFolder
		self.container[remoteType] = self._maid:give(remoteInstance)
	end
	return remoteInstance
end

function Remote:fireClient(player, ...)
	local remoteInstance = self:_getRemoteInstance("RemoteEvent")
	remoteInstance:FireClient(player, ...)
end

function Remote:fireAllClients(...)
	for _, player in pairs(players:GetPlayers()) do
		self:fireClient(player, ...)
	end
end

function Remote:fireNearbyClients(origin, radius, ...)
	for _, player in pairs(players:GetPlayers()) do
		if player:DistanceFromCharacter(origin) <= radius then
			self:fireClient(player, ...)
		end
	end
end

function Remote:invokeClient(player, ...)
	local remoteInstance = self:_getRemoteInstance("RemoteFunction")
	local args = table.pack(...)
	return Promise.defer(function(resolve, reject)
		local results = table.pack(pcall(remoteInstance.InvokeClient, remoteInstance, player, table.unpack(args)))
		local success = table.remove(results, 1)
		if success then
			resolve(table.unpack(results))
		else
			reject(table.unpack(results))
		end
	end)
end

function Remote:destroy()
	self._maid:clean()
end



return Remote