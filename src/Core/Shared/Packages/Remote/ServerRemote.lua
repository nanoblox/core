-- LOCAL
local main = require(game.Nanoblox)
local Maid = main.modules.Maid
local Remote = {}



-- CONSTRUCTOR
function Remote.new(name, requestLimit, refreshInterval)
	local self = {}
	setmetatable(self, Remote)
	
	local maid = Maid.new()
	self._maid = maid
	
	local folder = maid:give(Instance.new("Folder"))
	folder.Name = name
	self.folder = folder
	
	self.name = name
	self.container = {}
	self.requestLimit = requestLimit or 10
	self.refreshInterval = refreshInterval or 5
	
	return self
end



-- METAMETHODS
function Remote:__index(index)
	local newIndex = Remote[index]
	if not newIndex then
		local remoteInstance, indexFormatted = self:checkRemoteInstance(index)
		if remoteInstance then
			newIndex = {}
			local customFunction
			function newIndex:Connect(event)
				customFunction = event
			end
			remoteInstance[indexFormatted]:Connect(function(...)
				local requestSuccess, errorMessage = self:checkRequest(...)
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
	local remoteInstance, indexFormatted = self:checkRemoteInstance(index)
	if not remoteInstance then
		rawset(self, index, value)
		return
	end
	local customFunction = value
	remoteInstance[indexFormatted] = function(...)
		local requestSuccess, errorMessage = self:checkRequest(...)
		if not requestSuccess then
			return requestSuccess, errorMessage
		end
		return customFunction(...)
	end
end
		
		
		
-- METHODS
function Remote:checkRemoteInstance(index)
	local remoteTypes = {
		["onServerEvent"] = "RemoteEvent",
		["onServerInvoke"] = "RemoteFunction",
	}
	local remoteType = remoteTypes[index]
	if remoteType then
		local remoteInstance = self:getRemoteInstance(remoteType)
		local indexFormatted = index:sub(1,1):upper()..index:sub(2)
		return remoteInstance, indexFormatted
	end
end

function Remote:checkRequest(player, ...)
	local currentTime = os.time()
	local user = main.modules.PlayerStore:getUser(player)
	if not user then
		return false, "Invalid user"
	end
	local requestsKey = "Requests_".. self.name
	local lastRefreshKey = "LastRefresh_".. self.name
	local requests = user.temp:get(requestsKey) or 0
	local lastRefresh = user.temp:get(lastRefreshKey) or 0
	if currentTime > lastRefresh + self.refreshInterval then
		lastRefresh = user.temp:set(lastRefreshKey, currentTime)
		requests = user.temp:set(requestsKey, 0)
	end
	if requests >= self.requestLimit then
		local errorMessage = ("Exceeded request limit. Wait %s before sending another request."):format(lastRefresh + 1 + self.refreshInterval - currentTime)
		return false, errorMessage
	end
	user.temp:increment(requestsKey, 1)
	return true
end
	
function Remote:getRemoteInstance(remoteType)
	local remoteInstance = self.container[remoteType]
	if not remoteInstance then
		remoteInstance = Instance.new(remoteType)
		remoteInstance.Parent = self.folder
		self.container[remoteType] = self._maid:give(remoteInstance)
	end
	return remoteInstance
end

function Remote:fireClient(player, ...)
	local remoteInstance = self:getRemoteInstance("RemoteEvent")
	remoteInstance:FireClient(player, ...)
end

function Remote:fireAllClients(...)
	for _, player in pairs(main.Players:GetPlayers()) do
		self:fireClient(player, ...)
	end
end

function Remote:fireNearbyClients(origin, radius, ...)
	for _, player in pairs(main.Players:GetPlayers()) do
		if player:DistanceFromCharacter(origin) <= radius then
			self:fireClient(player, ...)
		end
	end
end

function Remote:invokeClient(player, ...)
	local remoteInstance = self:getRemoteInstance("RemoteFunction")
	return remoteInstance:InvokeClient(player, ...)
end

function Remote:destroy()
	self._maid:clean()
end



return Remote