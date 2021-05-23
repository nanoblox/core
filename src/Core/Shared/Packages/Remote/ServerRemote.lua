-- CONFIG
-- This is important!!
-- This defines the folder to store all remotes
-- It must be present before the game initiates
local remotesStorage = require(game.Nanoblox).shared.Remotes
local REQUESTS_EXCEEDED_MESSAGE = "Exceeded request limit for remote '%s'. Cooldown = %s."
local DATALIMIT_EXCEEDED_MESSAGE = "Exceeded data size limit of %s bytes for remote '%s'."



-- LOCAL
local Maid = require(script.Parent.Maid)
local Promise = require(script.Parent.Promise)
local Remote = {}
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")
local requestDetails = {}
local remotes = {}



-- BEHAVIOUR
local function playerAdded(player)
	local detail = {
		requests = 0,
		nextRefresh = 0,
	}
	requestDetails[player] = detail
end
players.PlayerAdded:Connect(function(player)
	playerAdded(player)
end)
for _, player in pairs(players:GetPlayers()) do
	playerAdded(player)
end
players.PlayerRemoving:Connect(function(player)
	requestDetails[player] = nil
end)

-- This handles the notification of any blocked requests
spawn(function()
	Remote.requestBlockedRemote = Remote.new("requestBlocked")
end)



-- CONSTRUCTOR
function Remote.new(name, requestLimit, refreshInterval, dataLimit)
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
	self.requestLimit = requestLimit or 12
	self.refreshInterval = refreshInterval or 3
	self.dataLimit = tonumber(dataLimit)
	
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
					local player = table.pack(...)[1]
					Remote.requestBlockedRemote:fireClient(player, self.name, errorMessage)
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
			return false, errorMessage
		end
		local returnedValues = table.pack(customFunction(...))
		return true, table.unpack(returnedValues)
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
		local errorMessage = (REQUESTS_EXCEEDED_MESSAGE):format(self.name, detail.nextRefresh - currentTime)
		return false, errorMessage
	elseif self.dataLimit then
		local requestData = table.pack(...)
		local requestSize = string.len(httpService:JSONEncode(requestData))
		if requestSize > self.dataLimit then
			local errorMessage = (DATALIMIT_EXCEEDED_MESSAGE):format(self.dataLimit, self.name)
			return false, errorMessage
		end
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