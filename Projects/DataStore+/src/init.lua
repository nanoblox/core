-- LOCAL
local dataStoreService = game:GetService("DataStoreService")
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local teleportService = game:GetService("TeleportService")
local Signal = require(4644649679)
local Table = require(4734187373)
local User = {}
User.__index = User
setmetatable(User, Table)

print(script.Name)

-- CONSTRUCTOR
function User.new(dataStoreName, key)
	local self = Table.new()
	setmetatable(self, User)
	
	-- Setup information
	local currentTime = os.time()
	local core = {}
	self._core = core
	core.dataStoreName = dataStoreName
	core.dataStore = dataStoreName and key and dataStoreService:GetDataStore(dataStoreName)
	core.key = key
	core.sessionId = httpService:GenerateGUID(false)
	core.player = key and players:GetPlayerByUserId(tonumber(tostring(key):match("%d+")))
	core.dataFailed = Signal.new()
	
	-- Config
	core.errorMessageBase = "DataStore+ | Failed to %s DataKey '".. tostring(key).."' ("..dataStoreName.."): "
	core.onlySaveDataWhenChanged = true
	core.teleportPlayerAwayOnFail = false
	core.autoSave = true
	core.autoSaveInterval = 20--60
	core.callInfo = {
		load = {
			maxRetries = 3,
			maxCallsPerMinute = 8,
			callCooldown = 7,
			callsThisMinute = 0,
			previousRefreshTime = currentTime,
			previousCallTime = currentTime,
		};
		save = {
			maxRetries = 3,
			maxCallsPerMinute = 4,
			callCooldown = 7,
			callsThisMinute = 0,
			previousRefreshTime = currentTime,
			previousCallTime = currentTime,
		}
	}
	
	-- Load User.Data
	core.dataLoaded = Signal.new()
	core.startData = {}
	coroutine.wrap(function()
		self.data = self:loadAsync()
		core.dataLoaded:Fire()
	end)()
	
	-- AutoSave
	core.saveLoopInitialized = false
	core.previousAutoSaveTime = currentTime
	if core.autoSave then
		self:initSaveLoop()
	end
	
	--BindToClose
	if not runService:IsStudio() then
		game:BindToClose(function()
		    self:saveAsync()
		end)
	end
	
	-- When destroyed, clear relevant data
	self.destroyed:Connect(function()
		core.sessionId = nil
	end)
	
	return self
end



-- DATASTORE METHODS
function User:loadAsync(ignoreLimits)
	local callType = "load"
	local core = self._core
	local success, additional = self:protectedCall(callType, ignoreLimits, function(finalAttempt)
		-- Setup table
		local data = Table.new(self)
		-- Load data
		local rawData = core.dataStore:GetAsync(core.key)
		if not rawData then
			rawData = core.startData
			core.IsNewData = true
		end
		-- Check for _failData
		local failData = Table.new(self)
		local previousFailData = rawData._failData or {}
		for k,v in pairs(previousFailData) do
			failData[k] = v
		end
		if failData._tableUpdated then
			coroutine.wrap(function()
				core.dataLoaded:Wait()
				core.dataFailed:Fire(failData)
			end)()
		end
		rawData._failData = failData
		-- Update Data with DataToLoad
		for k,v in pairs(rawData) do
			data[k] = v
		end
		-- Return Data
		return data, rawData
	end)
	return success, additional
end

function User:saveAsync(ignoreLimits)
	local callType = "save"
	local core = self._core
	-- Check if anything needs to be saved
	if self.data._tableUpdated == false and self.data._failData._tableUpdated == false and core.onlySaveDataWhenChanged then
		return false
	end
	-- Save data
	local backupAction = false
	local success, additional = self:protectedCall(callType, ignoreLimits, function(finalAttempt)
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
		if core.teleportPlayerAwayOnFail then
			local player = core.player
			if player then
				teleportService:Teleport(game.PlaceId, player)
				return "FinalAttempt: teleported away"
			end
		end
		-- Keep player in server and reload data so DataIDs match
		local data, rawData = self:loadAsync()
		for k,v in pairs(rawData) do
			self.data[k] = v
		end
		core.dataLoaded:Fire()
		return "FinalAttempt: reloaded data"
	end
	-- Return
	return success, additional
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
	local loopId = core.sessionId
	if not core.saveLoopInitialized then
		core.saveLoopInitialized = true
		coroutine.wrap(function()
			while core.autoSave and loopId == core.sessionId do
				local currentTime = os.time()
				if currentTime - core.previousAutoSaveTime >= core.autoSaveInterval then
					core.previousAutoSaveTime = currentTime
					self:saveAsync()
				end
				wait(1)
			end
			core.saveLoopInitialized = false
		end)()
	end
end

function User:protectedCall(callType, ignoreLimits, func)
	local core = self._core
	if not core.dataStore then
		return {}
	end
	local callTypeInfo = core.callInfo[callType]
	local errorMessageBaseStart = string.format(core.errorMessageBase, callType)
	if not ignoreLimits then
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
	end
	-- Call function and retry if necessary
	local data, additional, success, errorMessage
	for i = 1, callTypeInfo.maxRetries do
		local finalAttempt = i == callTypeInfo.maxRetries
		local success, errorMessage = pcall(function() data, additional = func(finalAttempt) end)
		if success and (data or callType == "load") then
			break
		elseif finalAttempt then
			warn(errorMessageBaseStart, errorMessage)
			return nil
		end
		wait(1)
	end
	return data, additional
end



return User