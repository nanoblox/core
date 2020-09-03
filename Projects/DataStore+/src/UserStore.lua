-- LOCAL
local replicatedStorage = game:GetService("ReplicatedStorage")
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Maid = require(HDAdmin:WaitForChild("Maid"))
local User = require(script.Parent.User)
local UserStore = {}
UserStore.__index = UserStore

local function getKey(keyOrPlayer)
	local isPlayer = (type(keyOrPlayer) == "userdata" and keyOrPlayer.UserId)
	return (isPlayer and tostring(keyOrPlayer.UserId)) or keyOrPlayer, isPlayer
end



-- CONSTRUCTOR
function UserStore.new(dataStoreName)
	local self = {}
	setmetatable(self, UserStore)
	
	self.dataStoreName = dataStoreName
	self.users = {}
	
	return self
end



-- METHODS
function UserStore:createUser(key)
	local key, isPlayer = getKey(key)
	assert(not self.users[key], ("user '%s' already exists!"):format(key))
	local user = User.new(self.dataStoreName, key)
	self.users[key] = user
	user.player = isPlayer and key
	user.name = isPlayer and key.Name
	coroutine.wrap(function()
		user:loadAsync()
	end)()
	return user
end

function UserStore:getUser(key)
	local key = getKey(key)
	return self.users[key]
end

-- *Player key specific
function UserStore:getUserByUserId(userId)
	for key, user in pairs(self.users) do
		if tonumber(key) == tonumber(userId) then
			return self:getUser(user.player)
		end
	end
end

-- *Player key specific
function UserStore:getUserByName(name)
	for player, user in pairs(self.users) do
		if player.Name == name then
			return self:getUser(player)
		end
	end
end

function UserStore:getAllUsers()
	local usersArray = {}
	for key, user in pairs(self.users) do
		table.insert(usersArray, user)
	end
	return usersArray
end

function UserStore:getLoadedUser(key)
	local user = self:getUser(key)
	if user and user.isLoaded then
		return user
	end
end

-- *Player key specific
function UserStore:getLoadedUserByUserId(userId)
	for key, user in pairs(self.users) do
		if tonumber(key) == tonumber(userId) then
			return self:getLoadedUser(user.player)
		end
	end
end

-- *Player key specific
function UserStore:getLoadedUserByName(name)
	for player, user in pairs(self.users) do
		if player.Name == name then
			return self:getLoadedUser(player)
		end
	end
end

function UserStore:getAllLoadedUsers()
	local usersArray = {}
	for key, user in pairs(self.users) do
		if user.isLoaded then
			table.insert(usersArray, user)
		end
	end
	return usersArray
end

function UserStore:grabData(key)
	local key = getKey(key)
	local user = User.new(self.dataStoreName, key)
	local data = user:loadAsync()
	user:destroy()
	return data
end

-- *Player key specific
function UserStore:createLeaderstat(player, statToBind)
	local maidName = "_maid"..player.Name..tostring(statToBind)
	if self[maidName] then
		return
	end
	local maid = Maid.new()
	self[maidName] = maid
	local dataTypes = {"perm", "temp"}
	local user = self:getUser(player)
	if not user then
		return false
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local statInstance = maid:give(Instance.new("StringValue"))
	statInstance.Name = statToBind
	statInstance.Value = "..."
	coroutine.wrap(function()
		user:waitUntilLoaded()
		for _, dataName in pairs(dataTypes) do
			statInstance.Value = user[dataName]:get(statToBind) or statInstance.Value
		end
	end)()
	statInstance.Parent = leaderstats
	for _, dataName in pairs(dataTypes) do
		maid:give(user[dataName].changed:Connect(function(stat, value, oldValue)
			if statInstance and statInstance.Value and stat == statToBind then
				statInstance.Value = tostring(value)
			end
		end))
	end
	return statInstance
end

-- *Player key specific
function UserStore:removeLeaderstat(player, statToUnbind)
	local maidName = "_maid"..player.Name..tostring(statToUnbind)
	local maid = self[maidName]
	if maid then
		maid:clean()
		self[maidName] = nil
	end
	return true
end

function UserStore:removeUser(key)
	local key = getKey(key)
	local user = self:getUser(key)
	user:saveAsync()
	user:destroy()
	self.users[key] = nil
end



return UserStore