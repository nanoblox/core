-- LOCAL
local UserService = {}
local User = require(script.Parent.User)
local users = {}
local errorStart = "HD Admin | User | "



-- METHODS
function UserService:createUser(dataStoreName, player)
	if users[player] then
		warn(("%sFailed to create User '%s': that user already exists."):format(errorStart, player.Name))
		return false
	end
	local key = player.UserId
	local user = User.new(dataStoreName, key)
	users[player] = user
	coroutine.wrap(function()
		user:loadAsync()
	end)()
	return user
end

function UserService:getUser(player)
	return users[player]
end

function UserService:getUserByUserId(userId)
	for player, user in pairs(users) do
		if player.UserId == userId then
			return self:getUser(player)
		end
	end
end

function UserService:getUserByName(name)
	for player, user in pairs(users) do
		if player.Name == name then
			return self:getUser(player)
		end
	end
end

function UserService:getAllUsers(name)
	local usersArray = {}
	for plr, user in pairs(users) do
		table.insert(usersArray, user)
	end
	return usersArray
end

function UserService:getUserWithData(player)
	local user = self:getUser(player)
	if user and user.data then
		return user
	end
end

function UserService:getUserByUserIdWithData(userId)
	for player, user in pairs(users) do
		if player.UserId == userId then
			return self:getUserWithData(player)
		end
	end
end

function UserService:getUserByNameWithData(name)
	for player, user in pairs(users) do
		if player.Name == name then
			return self:getUserWithData(player)
		end
	end
end

function UserService:getAllUsersWithData(name)
	local usersArray = {}
	for plr, user in pairs(users) do
		if user.data then
			table.insert(usersArray, user)
		end
	end
	return usersArray
end

function UserService:removeUser(player)
	local user = self:getUser(player)
	if not user then
		warn(("%sFailed to remove User '%s': user does not exist."):format(errorStart, player.Name))
		return false
	end
	user:saveAsync()
	user:destroy()
	users[player] = nil
end



return UserService