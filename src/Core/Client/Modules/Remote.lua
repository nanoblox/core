-- LOCAL
local main = require(game.Nanoblox)
local ERROR_START = "Nanoblox | Remote (Client) | "
local ERROR_NO_LISTENER = ERROR_START.."Failed to get remoteInstance %s for '%s': no remote is listening on the server."
local Remote = {}



-- CONSTRUCTOR
function Remote.new(name, folder)
	local self = {}
	setmetatable(self, Remote)
	
	self.name = name
	self.folder = folder
	self.container = {}
	
	for _, remoteInstance in pairs(folder:GetChildren()) do
		local remoteType = remoteInstance.ClassName
		self.container[remoteType] = remoteInstance
	end
	folder.ChildAdded:Connect(function(remoteInstance)
		local remoteType = remoteInstance.ClassName
		self.container[remoteType] = remoteInstance
	end)
	
	return self
end



-- METAMETHODS
function Remote:__index(index)
	local newIndex = Remote[index]
	if not newIndex then
		local remoteType, remoteInstance, indexFormatted = self:checkRemoteInstance(index)
		if remoteType then
			if remoteInstance then
				newIndex = remoteInstance[indexFormatted]
			else
				newIndex = {}
				local events = {}
				function newIndex:Connect(event)
					table.insert(events, event)
				end
				local waitForChildRemote
				waitForChildRemote = self.folder.ChildAdded:Connect(function(child)
					if child.Name == remoteType then
						child[indexFormatted]:Connect(function(...)
							for _, event in pairs(events) do
								event(...)
							end
						end)
						waitForChildRemote:Disconnect()
					end
				end)
			end
		end
	end
	return newIndex
end

function Remote:__newindex(index, value)
	local remoteType, remoteInstance, indexFormatted = self:checkRemoteInstance(index)
	if not remoteType then
		rawset(self, index, value)
		return
	end
	local customFunction = value
	if remoteInstance then
		remoteInstance[indexFormatted] = customFunction
	else
		local waitForChildRemote
		waitForChildRemote = self.folder.ChildAdded:Connect(function(child)
			if child.Name == remoteType then
				child[indexFormatted] = customFunction
				waitForChildRemote:Disconnect()
			end
		end)
	end
end



-- METHODS
function Remote:checkRemoteInstance(index)
	local remoteTypes = {
		["onClientEvent"] = "RemoteEvent",
		["onClientInvoke"] = "RemoteFunction",
	}
	local remoteType = remoteTypes[index]
	if remoteType then
		local remoteInstance = self:getRemoteInstance(remoteType)
		local indexFormatted = index:sub(1,1):upper()..index:sub(2)
		return remoteType, remoteInstance, indexFormatted
	end
end

function Remote:getRemoteInstance(remoteType)
	local remoteInstance = self.container[remoteType]
	if not remoteInstance then
		return false
	end
	return remoteInstance
end

function Remote:fireServer(...)
	local remoteType = "RemoteEvent"
	local remoteInstance = self:getRemoteInstance(remoteType)
	if not remoteInstance then
		warn(ERROR_NO_LISTENER:format(ERROR_START, remoteType, self.name))
		return
	end
	remoteInstance:FireServer(...)
end

function Remote:invokeServer(...)
	local remoteType = "RemoteFunction"
	local remoteInstance = self:getRemoteInstance(remoteType)
	if not remoteInstance then
		warn(ERROR_NO_LISTENER:format(ERROR_START, remoteType, self.name))
		return
	end
	return remoteInstance:InvokeServer(...)
end



return Remote