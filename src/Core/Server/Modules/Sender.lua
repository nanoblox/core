-- LOCAL
local main = require(game.Nanoblox)
local Janitor = main.modules.Janitor
local Signal = main.modules.Signal
local Sender = {}
Sender.__index = Sender



-- CONSTRUCTOR
function Sender.new(name)
	local self = {}
	setmetatable(self, Sender)
	
	local janitor = Janitor.new()
	self._janitor = janitor
	self.name = name
	self.addRequest = janitor:add(Instance.new("BindableFunction"), "Destroy")
	self.forceRetry = false
	
	return self
end



-- METHODS
function Sender:fireServer(jobId, ...)
	self.addRequest:Invoke("FS", jobId, ...)
end

function Sender:fireAllServers(...)
	self.addRequest:Invoke("FAS", ...)
end

function Sender:fireOtherServers(...)
	self.addRequest:Invoke("FOS", ...)
end

function Sender:invokeServer(jobId, ...)
	local dataFromServers = self.addRequest:Invoke("IS", jobId, ...)
	local dataFromServer = unpack(dataFromServers)
	return dataFromServer
end

function Sender:invokeAllServers(...)
	local dataFromServers = self.addRequest:Invoke("IAS", ...)
	return dataFromServers
end

function Sender:invokeOtherServers(...)
	local dataFromServers = self.addRequest:Invoke("IOS", ...)
	return dataFromServers
end

function Sender:destroy()
	self._janitor:destroy()
	for k, v in pairs(self) do
		if typeof(v) == "table" then
			self[k] = nil
		end
	end
end



return Sender