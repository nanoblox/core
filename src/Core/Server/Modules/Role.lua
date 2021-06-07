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
	self.commands = {}
	
	for k,v in pairs(properties or {}) do
		self[k] = v
	end

	self:updateCommands()
	
	return self
end



-- METHODS
function Role:destroy()
	self._maid:clean()
end

function Role:give(user, roleType)
	user.temp:getOrSetup("roles"):set(self.UID, true)
	main.services.RoleService.updateRoleInformation(user)
end

function Role:setRoleType(user, roleType)

end

function Role:take(user)

	main.services.RoleService.updateRoleInformation(user)
end

function Role:getUsers()
	return {}
end

function Role:updateUsers()
	local users = self:getUsers()
	for _, user in pairs(users) do
		main.services.RoleService.updateRoleInformation(user)
	end
end

function Role:updateCommands() -- maybe consider changing to just 'update'
	-- IMPORTANT: prevent this being called multiple times a frame. if it is, then call once, then delay another call for the next frame.
	-- Scan through ``inheritCommands`` and apply accoridngly
	self:updateUsers()
end

function Role:updateProperty(pathwayTable, value)

	self:updateUsers()
end

function Role:destroy()
	local users = self:getUsers()
	for _, user in pairs(users) do
		Role:take(user)
	end
end



return Role