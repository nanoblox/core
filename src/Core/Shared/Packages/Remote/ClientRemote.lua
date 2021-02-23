-- CONFIG
-- This is important!!
-- This defines the folder to store all remotes
-- It must be present before the game initiates
local remotesStorage = require(game.Nanoblox).shared.Remotes
local runService = game:GetService("RunService")



-- LOCAL
local ERROR_NO_LISTENER = "Failed to get remoteInstance %s for '%s': no remote is listening on the server."
local Remote = {}
local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)
local Promise = require(script.Parent.Promise)



-- BEHAVIOUR
local remotes = {}
remotesStorage.ChildAdded:Connect(function(child)
	local name = child.Name
	local remote = remotes[name]
	if remote then
		remote:_setupRemoteFolder()
	end
end)
remotesStorage.ChildRemoved:Connect(function(child)
	local name = child.Name
	local remote = remotes[name]
	if remote then
		remote:destroy()
	end
end)

-- This handles the notification of any blocked requests when firing to server
spawn(function()
	local requestBlockedRemote = Remote.new("requestBlocked")
	requestBlockedRemote.onClientEvent:Connect(function(blockedRemoteName, reason)
		local blockedRemote = remotes[blockedRemoteName]
		blockedRemote:requestBlocked(reason)
	end)
end)



-- CONSTRUCTOR
function Remote.new(name)
	local self = {}
	setmetatable(self, Remote)
	
	local maid = Maid.new()
	self._maid = maid
	self.name = name
	self.container = {}
	self.remoteFolderAdded = Signal.new()
	self.remoteFolder = nil
	self:_setupRemoteFolder()
	
	remotes[name] = self
	
	return self
end



-- METAMETHODS
function Remote:__index(index)
	local newIndex = Remote[index]
	if not newIndex then
		local remoteType, remoteInstance, indexFormatted = self:_checkRemoteInstance(index)
		if remoteType then
			if remoteInstance then
				newIndex = remoteInstance[indexFormatted]
			else
				newIndex = {}
				local events = {}
				function newIndex:Connect(event)
					table.insert(events, event)
				end
				self:_continueWhenRemoteInstanceLoaded(remoteType, function(newRemoteInstance)
					newRemoteInstance[indexFormatted]:Connect(function(...)
						for _, event in pairs(events) do
							event(...)
						end
					end)
				end)
			end
		end
	end
	return newIndex
end

function Remote:__newindex(index, customFunction)
	local remoteType, remoteInstance, indexFormatted = self:_checkRemoteInstance(index)
	if not remoteType then
		rawset(self, index, customFunction)
		return
	end
	self:_continueWhenRemoteInstanceLoaded(remoteType, function(newRemoteInstance)
		newRemoteInstance[indexFormatted] = customFunction
	end)
end



-- METHODS
function Remote:requestBlocked(reason)
	-- This function is called whenever a request is rejected (e.g. one reason is when the client makes too many requests in a time period)
	-- You can change this! For example, to produce an error notification for the client
	-- In another location simply do
	--[[
	```
	local ClientRemote = require(pathway.to.here)
	function ClientRemote:requestBlocked(reason)
		-- your new action here
	end
	```
	--]]
	warn(reason)
end

function Remote:_continueWhenRemoteInstanceLoaded(remoteType, functionToCall)
	local function continueFunc()
		local remoteInstance = self:_getRemoteInstance(remoteType)
		if remoteInstance then
			functionToCall(remoteInstance)
		else
			local waitForChildRemote
			waitForChildRemote = self._maid:give(self.remoteFolder.ChildAdded:Connect(function(child)
				if child.Name == remoteType then
					waitForChildRemote:Disconnect()
					functionToCall(child)
				end
			end))
		end
	end
	local remoteFolder = self.remoteFolder
	if remoteFolder then
		continueFunc()
	else
		local waitForRemoteFolderConnection
		waitForRemoteFolderConnection = self._maid:give(self.remoteFolderAdded:Connect(function()
			waitForRemoteFolderConnection:Disconnect()
			continueFunc()
		end))
	end
end

function Remote:_setupRemoteFolder()
	local remoteFolder = remotesStorage:FindFirstChild(self.name)
	if remoteFolder then
		for _, remoteInstance in pairs(remoteFolder:GetChildren()) do
			local remoteType = remoteInstance.ClassName
			self.container[remoteType] = remoteInstance
		end
		self._maid:give(remoteFolder.ChildAdded:Connect(function(remoteInstance)
			local remoteType = remoteInstance.ClassName
			self.container[remoteType] = remoteInstance
		end))
		self.remoteFolder = remoteFolder
		self.remoteFolderAdded:Fire()
	end
end

function Remote:_checkRemoteInstance(index)
	local remoteTypes = {
		["onClientEvent"] = "RemoteEvent",
		["onClientInvoke"] = "RemoteFunction",
	}
	local remoteType = remoteTypes[index]
	if remoteType then
		local remoteInstance = self:_getRemoteInstance(remoteType)
		local indexFormatted = index:sub(1,1):upper()..index:sub(2)
		return remoteType, remoteInstance, indexFormatted
	end
end

function Remote:_getRemoteInstance(remoteType)
	local remoteInstance = self.container[remoteType]
	if not remoteInstance then
		return false
	end
	return remoteInstance
end

function Remote:fireServer(...)
	local remoteType = "RemoteEvent"
	local remoteInstance = self:_getRemoteInstance(remoteType)
	if not remoteInstance then
		-- error(ERROR_NO_LISTENER:format(remoteType, self.name))
		return
	end
	remoteInstance:FireServer(...)
end

function Remote:invokeServer(...)
	local remoteType = "RemoteFunction"
	local remoteInstance = self:_getRemoteInstance(remoteType)
	local args = table.pack(...)
	return Promise.defer(function(resolve, reject)
		if not remoteInstance then
			local waitForRemoteInstance = self._maid:give(Signal.new())
			self:_continueWhenRemoteInstanceLoaded(remoteType, function(newRemoteInstance)
				runService.Heartbeat:Wait()
				waitForRemoteInstance:Fire(newRemoteInstance)
			end)
			remoteInstance = waitForRemoteInstance:Wait()
			waitForRemoteInstance:Destroy()
		end
		local results = table.pack(pcall(remoteInstance.InvokeServer, remoteInstance, table.unpack(args)))
		local pcallSuccess = table.remove(results, 1)
		if pcallSuccess then
			local approved = table.remove(results, 1)
			if approved then
				resolve(table.unpack(results))
				return
			elseif Remote.requestBlocked then
				Remote:requestBlocked(table.unpack(results))
			end
		end
		reject(table.unpack(results))
	end)
end

function Remote:destroy()
	remotes[self.name] = nil
	self._maid:clean()
end
Remote.Destroy = Remote.destroy



return Remote