-- LOCAL
local main = require(game.Nanoblox)
local Maid = main.modules.Maid
local Signal = main.modules.Signal
local Role = {}
Role.__index = Role



-- CONSTRUCTOR
function Role.new(properties)
	local self = {}
	setmetatable(self, Role)
	
	local maid = Maid.new()
	self._maid = maid
	self._validCommands = {}
	
	for k,v in pairs(properties or {}) do
		self[k] = v
	end
	
	return self
end



-- METHODS
function Role:destroy()
	self._maid:clean()
end



return Role