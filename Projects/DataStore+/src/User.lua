-- LOCAL
local dataStoreService = game:GetService("DataStoreService")
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local teleportService = game:GetService("TeleportService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Signal = require(HDAdmin:WaitForChild("Signal"))
local Maid = require(HDAdmin:WaitForChild("Maid"))
local TableModifiers = require(script.Parent.TableModifiers)
local Serializer = require(script.Parent.Serializer)
local User = {}
User.__index = User



-- LOCAL FUNCTIONS
local function doTablesMatch(t1, t2, cancelOpposites)
	if type(t1) ~= "table" then
		return false
	end
	for i, v in pairs(t1) do
		if (typeof(v) == "table") then
			if (doTablesMatch(t2[i], v) == false) then
				return false
			end
		else
			if (v ~= t2[i]) then
				return false
			end
		end
	end
	if not cancelOpposites then
		if not doTablesMatch(t2, t1, true) then
			return false
		end
	end
	return true
end

local function isATable(value)
	return type(value) == "table"
end

local function isEqual(v1, v2)
	if isATable(v1) and isATable(v2) then
		return doTablesMatch(v1, v2)
	end
	return v1 == v2
end

local function findValue(tab, value)
	for i,v in pairs(tab) do
		if isEqual(v, value) then
			return i
		end
	end
end



-- CONSTRUCTOR
function User.new(dataStoreName, key)
	local self = {}
	setmetatable(self, User)
	
	-- Maid
	local maid = Maid.new()
	self._maid = maid
	
	-- Main
	self.temp = {}
	self.perm = {}
	self.backup = {}
	self._data = {}
	maid:give(TableModifiers.apply(self.temp))
	maid:give(TableModifiers.apply(self.perm))
	maid:give(TableModifiers.apply(self.backup))
	maid:give(TableModifiers.apply(self._data))
	
	-- Config
	local currentTick = tick()
	self.onlySaveDataWhenChanged = true
	self.teleportPlayerAwayOnFail = false
	self.autoSave = false
	self.autoSaveInterval = 60
	self.maxRetries = 3
	self.cooldown = 8
	self.transformLoadDataTo = self.perm
	self.transformingLoadData = false
	
	-- Setup information
	self.dataStoreName = dataStoreName
	self.dataStore = dataStoreName and key and dataStoreService:GetDataStore(dataStoreName)
	self.key = key
	self.sessionId = httpService:GenerateGUID(false)
	self.isNewUser = nil
	self.isLoaded = false
	self.loaded = maid:give(Signal.new())
	self.saved = maid:give(Signal.new())
	self.player = nil
	self.errorMessageBase = "DataStore+ | Failed to %s DataKey '".. tostring(key).."' ("..dataStoreName.."): "
	self.startData = {}
	
	-- AutoSave
	self.nextAutoSaveTick = currentTick + 5
	if self.autoSave then
		self:initAutoSave()
	end
	
	--BindToClose
	if not runService:IsStudio() then
		game:BindToClose(function()
		    self:saveAsync()
		end)
	end

	-- Perm to _Data (serialization)
	local serEvents = {
		changed = "set",
		inserted = "insert",
		removed = "remove",
		paired = "pair",
	}
	for eventName, methodName in pairs(serEvents) do
		self.perm[eventName]:Connect(function(...)
			local packaged = {...}
			for k,v in pairs(packaged) do
				packaged[k] = Serializer.serialize(v, true)
			end
			self._data[methodName](self._data, table.unpack(packaged))
			self._data._tableUpdated = true
		end)
	end

	return self
end



-- METHODS
function User:loadAsync()
	local callType = "load"
	self.isLoaded = false
	
	-- Retrieve previous _data 
	local data = self:_protectedCall(callType, function(finalAttempt)
		return self.dataStore:GetAsync(self.key)
	end)

	-- Setup perm; if nothing found, apply start data. Transform _data into perm (i.e. deserialize)
	if not data then
		data = self.startData
		self.isNewUser = true
	else
		self.isNewUser = false
	end
	local tableToUpdate = self.transformLoadDataTo or self._data
	self.transformingLoadData = true
	self:transformData(data, self.perm, tableToUpdate)
	self.transformingLoadData = false
	
	-- Find and trigger any backup data
	local backupData = data._backupData
	if backupData then
		self:transformData(backupData, self.backup)
		self._data._backupData = nil
	end
	
	-- Complete
	self.isLoaded = true
	self.loaded:Fire()
	return self.perm
end

function User:saveAsync()
	local callType = "save"
	
	-- Return if nothing needs saving
	if self._data._tableUpdated == false and self.backup._tableUpdated == false and self.onlySaveDataWhenChanged then
		return false
	end
	
	-- Cooldown to prevent two calls being made within 7 seconds
	self:_applyCooldown(callType)
	
	-- Save data
	local backupAction = false
	local success = self:_protectedCall(callType, function(finalAttempt)
		return self.dataStore:UpdateAsync(self.key, function(previousData)
			previousData = previousData or self._data
			if previousData._dataId == self._data._dataId then
				-- DataIds match, generate new unique DataId
				self._data._dataId = httpService:GenerateGUID()
				self._data._tableUpdated = false
			elseif finalAttempt then
				-- DataIds do not match, all retries failed, force add backup data to previousData and proceed to backup action 
				warn(string.format("%sDataIds do not match, all retries failed. Saved backup data and and proceeding to backup action.", self.errorMessageBase:format(callType)))
				previousData._backupData = self.backup
				backupAction = true
				return previousData
			else
				-- DataIds do not match, abort save and retry
				warn(string.format("%sDataIds do not match, retrying save...", self.errorMessageBase:format(callType)))
				return nil
			end
			-- Success, return data to be saved
			return self._data
		end)
	end)
	
	-- Clear backup data
	if success then
		self.saved:Fire()
		self.backup:clear()
	end
	
	-- All retries failed, resort to backup action
	if backupAction then
		-- Teleport away (not recommended)
		if self.teleportPlayerAwayOnFail then
			local player = self.player
			if player then
				teleportService:Teleport(game.PlaceId, player)
				return "FinalAttempt: teleported away"
			end
		end
		-- Keep player in server and reload data so dataIDs match
		self:loadAsync()
		return "FinalAttempt: reloaded data"
	end
	
	-- Return
	return success
end

function User:removeAsync()
	local callType = "remove"
	
	-- Cooldown
	self:_applyCooldown(callType)
	
	-- Remove key
	self:_protectedCall(callType, function()
		self.dataStore:RemoveAsync(self.key)
	end)
end

function User:_applyCooldown(callType)
	local currentTick = tick()
	local requestName = "_nextRequest"..callType
	local nextRequest = self[requestName] or currentTick
	if currentTick < nextRequest then
		wait(nextRequest - currentTick)
	end
	self[requestName] = nextRequest + self.cooldown
end

function User:_protectedCall(callType, func)
	local retries = self.maxRetries + 1
	for i = 1, retries do
		local finalAttempt = i == self.maxRetries + 1
		local success, value = pcall(func, finalAttempt)
		if success and (value or callType == "load") then
			return value
		elseif not success and finalAttempt then
			warn(self.errorMessageBase:format(callType), value)
		end
		wait(1)
	end
end



-- UTILITY METHODS
function User:setStartData(startData)
	if type(startData) ~= "table" then
		startData = {startData}
	end
	self.startData = startData
end

function User:initAutoSave(autoSaveInterval)
	local loopId = self.sessionId
	self.autoSaveInterval = tonumber(autoSaveInterval) or self.autoSaveInterval
	if self.saveLoopInitialized then
		return false
	end
	self.saveLoopInitialized = true
	self.autoSave = true
	local firstTime = true
	coroutine.wrap(function()
		self:waitUntilLoaded()
		while self.autoSave and loopId == self.sessionId do
			local currentTick = tick()
			if currentTick >= self.nextAutoSaveTick then
				self.nextAutoSaveTick = currentTick + self.autoSaveInterval
				local maxRetries = self.maxRetries
				if firstTime then
					self.maxRetries = 0
				end
				self:saveAsync()
				if firstTime then
					self.maxRetries = (self.maxRetries == 0 and maxRetries) or self.maxRetries
					firstTime = false
				end
			end
			RunService.Heartbeat:Wait()
		end
		self.saveLoopInitialized = nil
	end)()
end

function User:transformData(data1, data2, dataToUpdate, ignoreNilled)
	-- This compares data1 and data2 and deserialises and merges the changes into dataToUpdate
	if not dataToUpdate then
		dataToUpdate = data2
	end
	-- account for nilled values
	if not ignoreNilled then
		for name, content in pairs(data2) do
			local dataToUpdateMain = dataToUpdate
			local isPrivate = data2 == self.perm and name:sub(1,1) == "_"
			if isPrivate then
				dataToUpdateMain = self._data
			else
				name = Serializer.deserialize(name)
			end
			if data1[name] == nil then
				dataToUpdateMain:set(name, nil)
			end
		end
	end
	
	-- repeat a similar process for present values
	for name, content in pairs(data1) do
		-- don't deseralize hidden values and add them to _data instantly instead
		local dataToUpdateMain = dataToUpdate
		local isPrivate = data2 == self.perm and name:sub(1,1) == "_"
		
		if isPrivate then
			dataToUpdateMain = self._data
		else
			name = Serializer.deserialize(name)
			content = Serializer.deserialize(content)
		end
		-- Update values
		local coreValue = data2[name]
		local bothAreTables = type(coreValue) == "table" and type(content) == "table"
		if isPrivate or (coreValue ~= content and not bothAreTables) then
			-- Only set values or keys with values/tables that dont match
			local oldValueNum = tonumber(coreValue)
			local newValueNum = tonumber(content)
			dataToUpdateMain[name] = coreValue
			if oldValueNum and newValueNum then
				dataToUpdateMain:increment(name, newValueNum-oldValueNum)
			else
				dataToUpdateMain:set(name, content)
			end
		else
			-- For this section, we only want to insert/set/pair *differences*
			if type(content) == "table" then
				-- t1 | the table with new information
				local t1 = content
				-- t2 | the table we are effectively merging into
				local original_t2 = (type(coreValue) == "table" and coreValue) or {}
				local t2 = {}
				for k,v in pairs(original_t2) do
					t2[k] = v
				end
				if #content > 0 then
					-- This inserts/removes differences accoridngly using minimal amounts of moves
					local iterations = (#t1 > #t2 and #t1) or #t2
					for i = 1, iterations do
						local V1 = t1[i]
						local V2 = t2[i]
						if V1 ~= V2 then
							local nextV1 = t1[i+1]
							if nextV1 ~= V2 and V2 ~= nil then
								table.remove(t2, i)
								if not ignoreNilled then
									dataToUpdateMain:remove(name, Serializer.deserialize(V2, true), i)
								end
							end
							local newV2 = t2[i]
							if V1 ~= nil and newV2 ~= V1 then
								table.insert(t2, i, V1)
								dataToUpdateMain:insert(name, Serializer.deserialize(V1, true), i)
							end
						end
					end
				else
					-- Only pair keys with values/tables that dont match
					for k,v in pairs(t1) do
						if not(t2[k] and isEqual(t2[k], v)) then
							k = Serializer.deserialize(k)
							v = Serializer.deserialize(v)
							dataToUpdateMain:pair(name, k, v)
						end
					end
					-- This accounts for nilled values
					if not ignoreNilled then
						for k,v in pairs(t2) do
							if t1[k] == nil then
								k = Serializer.deserialize(k)
								dataToUpdateMain:pair(name, k, nil)
							end
						end
					end
				end
			end
		end
	end
end

function User:waitUntilLoaded()
	local loaded = self.isLoaded or self.loaded:Wait()
	return self.perm
end

function User:destroy()
	self.sessionId = nil
	self._maid:clean()
end



return User