-- LOCAL
local main = require(game.Nanoblox)
local Janitor = main.modules.Janitor
local Signal = main.modules.Signal
local Receiver = {}
Receiver.__index = Receiver



-- CONSTRUCTOR
function Receiver.new(name)
	local self = {}
	setmetatable(self, Receiver)
	
	local janitor = Janitor.new()
	self._janitor = janitor
	self.name = name
	self.onGlobalEvent = janitor:add(Signal.new(), "destroy")
	self.onGlobalInvoke = nil
	
	return self
end



-- METHODS
function Receiver:destroy()
	self._janitor:destroy()
	for k, v in pairs(self) do
		if typeof(v) == "table" then
			self[k] = nil
		end
	end
end



return Receiver