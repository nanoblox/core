-- LOCAL
local main = require(game.HDAdmin)
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Command = {}
Command.__index = Command



-- CONSTRUCTOR
function Command.new(properties)
	local self = {}
	setmetatable(self, Command)
	
	local maid = Maid.new()
	self._maid = maid
	for k,v in pairs(properties or {}) do
		self[k] = v
	end
	
	return self
end



-- METHODS
function Command:destroy()
	self._maid:clean()
end



return Command