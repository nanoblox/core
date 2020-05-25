-- LOCAL
local dataStoreService = game:GetService("DataStoreService")
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local teleportService = game:GetService("TeleportService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local HDAdmin = replicatedStorage:WaitForChild("HDAdmin")
local Signal = require(HDAdmin:WaitForChild("Signal"))
local Maid = require(HDAdmin:WaitForChild("Maid"))
local TableModifiers = require(script.Parent.TableModifiers)
local User = {}
User.__index = User
setmetatable(User, TableModifiers)



-- CONSTRUCTOR
function User.new(dataStoreName, key)
	local self = TableModifiers.new()
	setmetatable(self, User)
	
	-- Config
	local currentTime = os.time()
	local maid = Maid.new()
	self._maid = maid
	self.sessionId = httpService:GenerateGUID(false)
	self.isNewData = nil
	self.dataLoaded = maid:add(Signal.new())
	self.failDataPresent = maid:add(Signal.new())
	self.onlySaveDataWhenChanged = true
	self.teleportPlayerAwayOnFail = false
	self.autoSave = true
	self.autoSaveInterval = 60
	self.callInfo = {
		load = {
			maxRetries = 3,
			maxCallsPerMinute = 8,
			callCooldown = 8,
			callsThisMinute = 0,
			previousRefreshTime = currentTime,
			previousCallTime = currentTime,
		};
		save = {
			maxRetries = 3,
			maxCallsPerMinute = 4,
			callCooldown = 8,
			callsThisMinute = 0,
			previousRefreshTime = currentTime,
			previousCallTime = currentTime,
		}
	}
	
	-- Setup information
	local core = {}
	self._core = core
	core.dataStoreName = dataStoreName
	core.dataStore = dataStoreName and key and dataStoreService:GetDataStore(dataStoreName)
	core.key = key
	core.player = key and players:GetPlayerByUserId(tonumber(tostring(key):match("%d+")))
	core.errorMessageBase = "DataStore+ | Failed to %s DataKey '".. tostring(key).."' ("..dataStoreName.."): "
	core.startData = {}
	
	-- AutoSave
	core.saveLoopInitialized = false
	core.previousAutoSaveTime = currentTime
	if self.autoSave then
		self:initSaveLoop()
	end
	
	--BindToClose
	if not runService:IsStudio() then
		game:BindToClose(function()
		    self:saveAsync()
		end)
	end
	
	return self
end



-- DATASTORE METHODS
function User:loadAsync()
	local callType = "load"
	local core = self._core
	local existingData = self.data
	local rawData = self:protectedCall(callType, function(finalAttempt)
		return core.dataStore:GetAsync(core.key)
	end)
	--
	if not rawData then
		rawData = core.startData
		self.isNewData = true
	else
		self.isNewData = false
	end
	--
	local failData = existingData and existingData._failData
	if failData then
		failData:destroy()
	end
	local previousFailData = rawData._failData or {}
	failData = TableModifiers.new(self)
	for k,v in pairs(previousFailData) do
		failData[k] = v
	end
	rawData._failData = failData
	--
	local data = existingData or TableModifiers.new(self)
	for k,v in pairs(rawData) do
		data[k] = v
	end
	--
	self.data = data
	self.dataLoaded:Fire()
	--
	if failData._tableUpdated then
		self.failDataPresent:Fire(failData)
	end
	--
	return data
end

function User:saveAsync()
	local callType = "save"
	local core = self._core
	-- Check if anything needs to be saved
	if not self.data or self.data._tableUpdated == false and self.data._failData._tableUpdated == false and self.onlySaveDataWhenChanged then
		return false
	end
	-- Save data
	local backupAction = false
	local success = self:protectedCall(callType, function(finalAttempt)
		return core.dataStore:UpdateAsync(core.key, function(previousData)
			local previousData = previousData or self.data
			if previousData._dataId == self.data._dataId then
				-- DataIds match, generate new unique DataId
				self.data._dataId = httpService:GenerateGUID()
				self.data._tableUpdated = false
			elseif finalAttempt then
				-- DataIds do not match, all retries failed, force add _failData to previousData and proceed to backup action 
				warn(string.format(core.errorMessageBase.."DataIds do not match, all retries failed. Saved _failData and and proceeding to backup action.", callType))
				previousData._failData = self.data._failData
				backupAction = true
				return previousData
			else
				-- DataIds do not match, abort save and retry
				warn(string.format(core.errorMessageBase.."DataIds do not match, retrying save...", callType))
				return nil
			end
			-- Clear _failData if required
			local failData = self.data._failData
			failData:clear()
			-- Success, return data to be saved
			return self.data
		end)
	end)
	-- All retires failed, resort to backup action
	if backupAction then
		-- Teleport away (not recommended)
		if self.teleportPlayerAwayOnFail then
			local player = core.player
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
	local core = self._core
	return core.dataStore:RemoveAsync(core.key)
end



-- UTILITY METHODS
function User:setStartData(startData)
	local core = self._core
	if type(startData) ~= "table" then
		startData = {startData}
	end
	core.startData = startData
end

function User:initSaveLoop()
	local core = self._core
	local loopId = self.sessionId
	if not core.saveLoopInitialized then
		core.saveLoopInitialized = true
		coroutine.wrap(function()
			while self.autoSave and loopId == self.sessionId do
				local currentTime = os.time()
				if currentTime - core.previousAutoSaveTime >= self.autoSaveInterval then
					core.previousAutoSaveTime = currentTime
					self:saveAsync()
				end
				wait(1)
			end
			core.saveLoopInitialized = false
		end)()
	end
end

function User:protectedCall(callType, func)
	local core = self._core
	if not core.dataStore then
		return {}
	end
	local callTypeInfo = self.callInfo[callType]
	local errorMessageBaseStart = string.format(core.errorMessageBase, callType)
	-- Call limit checks
	if callTypeInfo.callsThisMinute > callTypeInfo.maxCallsPerMinute then
		-- Has the max number of calls/minute been exeeded?
		warn(string.format("%sExceeded maxCallsPerMinute (callsThisMinute = %s, maxCallsPerMinute = %s).", errorMessageBaseStart, callTypeInfo.callsThisMinute, callTypeInfo.maxCallsPerMinute))
		return nil
	elseif os.time() - callTypeInfo.previousCallTime < callTypeInfo.callCooldown then
		-- Has the call been made before the cooldown? If so, delay until ready
		repeat
			wait(1)
		until os.time() - callTypeInfo.previousCallTime >= callTypeInfo.callCooldown
	end
	-- Update limit values
	local currentTime = os.time()
	callTypeInfo.callsThisMinute = callTypeInfo.callsThisMinute + 1
	callTypeInfo.previousCallTime = currentTime
	if currentTime - callTypeInfo.previousRefreshTime >= 60 then
		callTypeInfo.previousRefreshTime = currentTime
		callTypeInfo.callsThisMinute = 0
	end
	-- Call function and retry if necessary
	local data, success, errorMessage
	for i = 1, callTypeInfo.maxRetries do
		local finalAttempt = i == callTypeInfo.maxRetries
		local success, errorMessage = pcall(function() data = func(finalAttempt) end)
		if success and (data or callType == "load") then
			break
		elseif finalAttempt then
			warn(errorMessageBaseStart, errorMessage)
			return nil
		end
		wait(1)
	end
	return data
end

function User:destroy()
	self.sessionId = nil
	for maidName, maid in pairs(self) do
		if type(maid) == "table" and maid.doCleaning then
			maid:doCleaning()
		end
	end
end



return User