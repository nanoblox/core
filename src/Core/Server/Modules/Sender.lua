-- LOCAL
local main = require(game.Nanoblox)
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Sender = {}
Sender.__index = Sender



-- CONSTRUCTOR
function Sender.new(name)
	local self = {}
	setmetatable(self, Sender)
	
	local maid = Maid.new()
	self._maid = maid
	self.name = name
	self.addRequest = maid:give(Instance.new("BindableFunction"))
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
	local dataFromServer = table.unpack(dataFromServers)
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
	self._maid:clean()
end



return Sender