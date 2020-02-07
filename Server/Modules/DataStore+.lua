-- LOCAL
local dataStoreService = game:GetService("DataStoreService")
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local teleportService = game:GetService("TeleportService")
local Signal = require(4644649679)
local User = {}
User.__index = User



-- CONSTRUCTOR
function User.new(dataStoreName, key)
	local self = {}
	setmetatable(self, User)
	
	-- Setup information
	local currentTime = os.time()
	self.DataStoreName = dataStoreName
	self.DataStore = dataStoreService:GetDataStore(dataStoreName)
	self.Key = key
	self.SessionId = httpService:GenerateGUID(false)
	self.DataToUpdate = false
	self.Player = players:GetPlayerByUserId(tonumber(tostring(key):match("%d+")))
	
	-- Config
	self.ErrorMessageCore = "DataStore+ | Failed to %s DataKey '"..key.."' ("..dataStoreName.."): "
	self.OnlySaveDataWhenChanged = true
	self.AutoSave = true
	self.AutoSaveInterval = 60
	self.CallInfo = {
		Load = {
			MaxRetries = 3,
			MaxCallsPerMinute = 8,
			CallCooldown = 7,
			CallsThisMinute = 0,
			PreviousRefreshTime = currentTime,
			PreviousCallTime = currentTime,
		};
		Save = {
			MaxRetries = 3,
			MaxCallsPerMinute = 4,
			CallCooldown = 7,
			CallsThisMinute = 0,
			PreviousRefreshTime = currentTime,
			PreviousCallTime = currentTime,
		}
	}
	
	-- Load data
	self.__StartData = {}
	coroutine.wrap(function()
		local data = self:loadAsync()
		if not data then
			data = self.__StartData
			self.IsNewData = true
		end
		self.Data = data
		self.DataLoaded:Fire(true)
	end)()
	
	-- AutoSave
	self.SaveLoopInitialized = false
	self.PreviousAutoSaveTime = currentTime
	if self.AutoSave then
		self:initSaveLoop()
	end
	
	--BindToClose
	game:BindToClose(function()
	    if runService:IsStudio() then
	        return
	    end
		self:saveAsync()
	end)
	
	-- Signals
	local signals = {"DataLoaded", "DataChanged", "DataAdded", "DataInserted", "DataRemoved", "DataMapped"}
	for _, signalName in pairs(signals) do
		local signal = self:registerInstance(Signal.new(signalName))
		self[signalName] = signal
	end
	
	return self
end



-- DATASTORE METHODS
function User:loadAsync(ignoreLimits)
	local callType = "Load"
	return self:protectedCall(callType, ignoreLimits, function(finalAttempt)
		return self.DataStore:GetAsync(self.Key)
	end)
end

function User:saveAsync(ignoreLimits)
	local callType = "Save"
	if self.DataToUpdate == false and self.OnlySaveDataWhenChanged then
		return false
	end
	return self:protectedCall(callType, ignoreLimits, function(finalAttempt)
		return self.DataStore:UpdateAsync(self.Key, function(previousData)
			local previousData = previousData or self.Data
			if previousData.__DataId == self.Data.__DataId then
				-- DataIds match, generate new unique DataId
				self.Data.__DataId = httpService:GenerateGUID()
				self.DataToUpdate = false
			elseif finalAttempt then
				-- DataIds do not match, all retries failed, force add __ErrorData to previousData and teleport player away
				warn(string.format(self.ErrorMessageCore.."DataIds do not match, all retries failed. Saved __ErrorData and teleported player away.", callType))
				previousData.__ErrorData = self.Data.__ErrorData
				if self.Player then
					teleportService:Teleport(game.PlaceId, self.Player)
				end
				return previousData
			else
				-- DataIds do not match, abort save and retry
				warn(string.format(self.ErrorMessageCore.."DataIds do not match, retrying save...", callType))
				return nil
			end
			-- Success, return data
			return self.Data
		end)
	end)
end

function User:removeAsync()
	return self.DataStore:RemoveAsync(self.Key)
end



-- UTILITY METHODS
function User:setStartData(startData)
	if type(startData) ~= "table" then
		startData = {startData}
	end
	self.__StartData = startData
end

function User:protectedCall(callType, ignoreLimits, func)
	local callTypeInfo = self.CallInfo[callType]
	local errorMessageCoreStart = string.format(self.ErrorMessageCore, callType)
	if not ignoreLimits then
		-- Call limit checks
		if callTypeInfo.CallsThisMinute > callTypeInfo.MaxCallsPerMinute then
			-- Has the max number of calls/minute been exeeded?
			warn(string.format("%sExceeded MaxCallsPerMinute (CallsThisMinute = %s, MaxCallsPerMinute = %s).", errorMessageCoreStart, callTypeInfo.CallsThisMinute, callTypeInfo.MaxCallsPerMinute))
			return nil
		elseif os.time() - callTypeInfo.PreviousCallTime < callTypeInfo.CallCooldown then
			-- Has the call been made before the cooldown? If so, delay until ready
			repeat
				wait(1)
			until os.time() - callTypeInfo.PreviousCallTime >= callTypeInfo.CallCooldown
		end
		-- Update limit values
		local currentTime = os.time()
		callTypeInfo.CallsThisMinute = callTypeInfo.CallsThisMinute + 1
		callTypeInfo.PreviousCallTime = currentTime
		if currentTime - callTypeInfo.PreviousRefreshTime >= 60 then
			callTypeInfo.PreviousRefreshTime = currentTime
			callTypeInfo.CallsThisMinute = 0
		end
	end
	-- Call function and retry if necessary
	local data, success, errorMessage
	for i = 1, callTypeInfo.MaxRetries do
		local finalAttempt = i == callTypeInfo.MaxRetries
		local success, errorMessage = pcall(function() data = func(finalAttempt) end)
		if success and (data or callType == "Load") then
			break
		elseif finalAttempt then
			warn(errorMessageCoreStart, errorMessage)
			return nil
		end
		wait(1)
	end
	return data
end

function User:registerInstance(instance)
	self.__Instances = self.__Instances or {}
	table.insert(self.__Instances, instance)
	return instance
end
	
function User:initSaveLoop()
	local loopId = self.SessionId
	if not self.SaveLoopInitialized then
		self.SaveLoopInitialized = true
		coroutine.wrap(function()
			while self.AutoSave and loopId == self.SessionId do
				local currentTime = os.time()
				if currentTime - self.PreviousAutoSaveTime >= self.AutoSaveInterval then
					self.PreviousAutoSaveTime = currentTime
					self:saveAsync()
				end
				wait(1)
			end
			self.SaveLoopInitialized = false
		end)()
	end
end

function User:destroy()
	self.SessionId = nil
	for _, instance in pairs(self.__Instances) do
		instance:Destroy()
	end
end



-- DATA MANIPULATION METHODS
function User:getData(stat)
	local data = self.Data
	return data[stat]
end

function User:findData(stat, value)
	local data = self.Data
	local tab = data[stat]
	if type(tab) == "table" then
		if #tab == 0 then
			return tab[value]
		else
			for i,v in pairs(tab) do
				if v == value then
					return value
				end
			end
		end
	end
end

function User:changeData(stat, value)
	local data = self.Data
	local oldValue = data[stat]
	data[stat] = value
	self.DataToUpdate = true
	self.DataChanged:Fire(stat, value, oldValue)
	return data[stat]
end

function User:addData(stat, value)
	local data = self.Data
	if data[stat] == nil then
		data[stat] = 0
	end
	local oldValue = data[stat]
	local newValue = data[stat] + value
	data[stat] = newValue
	self.DataToUpdate = true
	self.DataChanged:Fire(stat, newValue, oldValue)
	return data[stat]
end

function User:insertData(stat, value)
	local data = self.Data
	if type(data[stat]) ~= "table" then
		data[stat] = {}
	end
	table.insert(data[stat], value)
	self.DataToUpdate = true
	self.DataInserted:Fire(stat, value)
	return data[stat]
end

function User:removeData(stat, value)
	local data = self.Data
	for i,v in pairs(data[stat]) do
		if v == value then
			table.remove(stat, i)
		end
	end
	self.DataToUpdate = true
	self.DataRemoved:Fire(stat, value)
end

function User:mapData(stat, key, value)
	local data = self.Data
	if type(data[stat]) ~= "table" then
		data[stat] = {}
	end
	data[stat][key] = value
	self.DataToUpdate = true
	self.DataMapped:Fire(stat, key, value)
end



return User