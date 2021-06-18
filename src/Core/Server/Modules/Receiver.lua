-- LOCAL
local main = require(game.Nanoblox)
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Receiver = {}
Receiver.__index = Receiver



-- CONSTRUCTOR
function Receiver.new(name)
	local self = {}
	setmetatable(self, Receiver)
	
	local maid = Maid.new()
	self._maid = maid
	self.name = name
	self.onGlobalEvent = maid:give(Signal.new())
	self.onGlobalInvoke = nil
	
	return self
end



-- METHODS
function Receiver:destroy()
	self._maid:clean()
	for k, v in pairs(self) do
		if typeof(v) == "table" then
			self[k] = nil
		end
	end
end



return Receiver