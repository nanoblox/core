-- This module acts as a gateway between studio (including the plugin,
-- trello, etc) and live servers. Config user.perm data will always reflect
-- the studio version of config (including bans, roles, etc). Every 10
-- seconds a new copy of the loader is retrieved. If differences are present
-- between the copy and previous version, then these changes are transormed
-- into the live server. This essentially enables changes from studio to be
-- synchronised almost instantly into all live servers.

-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local NilledData = System.new("NilledData", true)
local nilledUser = NilledData.user
local ConfigService = {
	user = main.modules.SystemStore:createUser("Config"),
	nilledUser = nilledUser,
}
ConfigService.user.onlySaveDataWhenChanged = false
local Thread = main.modules.Thread
local TableUtil = main.modules.TableUtil
local DataUtil = main.modules.DataUtil



-- PUBIC
-- Create a signal so that MainFramework can complete when all data has loaded been transformed into the
-- correct tables
ConfigService.setupComplete = false
ConfigService.setupCompleteSignal = main.modules.Signal.new()



-- PRIVATE
local function isATable(value)
	return type(value) == "table"
end

local function updateSystems(func, timeout)
	local Promise = main.modules.Promise
	local promises = {}
	local systems = main.modules.SystemStore:getUsers()
	for i, systemUser in pairs(systems) do
		if systemUser.key ~= "Config" and systemUser.key ~= "NilledData" then
			table.insert(promises, Promise.async(function(resolve, reject, onCancel)
				systemUser:waitUntilLoaded()
				func(systemUser)
				resolve(true)
			end))
		end
	end
	local completedSignal = main.modules.Signal.new()
	timeout = timeout or 10
	Promise.allSettled(promises)
		:timeout(timeout)
		:finally(function()
			completedSignal:Fire()
		end)
	completedSignal:Wait()
end



-- START
function ConfigService.start()

	-- Load user and check for recent config update directly from studio
	-- (i.e. this is the first server to receive the update)
	-- If present, force save these changes
	-- The Nanoblox plugin automatically saves changes *within studio*
	-- therefore this is only here as backup (e.g. in case it's disabled)
	local user = ConfigService.user
	local config = main.config
	local latestConfig = ConfigService.getLatestConfig()
	if not TableUtil.doTablesMatch(config, latestConfig) then
		user.perm:set("ConfigData", TableUtil.copy(config))
		user:saveAsync()
	end
	
	-- This 'transforms' any data not registered within a Store Service
	-- (such as RoleService) into that service's user
	updateSystems(function(systemUser)
		local categoryName = systemUser.key
		local service = ConfigService.getServiceFromCategory(categoryName)
		if not service then return end
		local generateRecord = service and service.generateRecord
		local categoryTable = main.modules.State.new(nil, true)
		local configCategory = TableUtil.copy(config[categoryName] or {})
		-- Transform config values into it, ignoring nilled values
		categoryTable:transformToWithoutNilling(configCategory)
		-- Then transform systemUser.perm, also ignoring nilled values
		categoryTable:transformToWithoutNilling(systemUser.perm)
		-- Finally, update the temp (server) container
		service.recordsActionDelay = 0
		systemUser.temp:transformTo(categoryTable)
		Thread.spawnNow(function()
			main.RunService.Heartbeat:Wait()
			service.recordsActionDelay = service.originalRecordsActionDelay
		end)
		-- Remove tm
		categoryTable:destroy()
		
		-- Listen out for nilled data
		-- When category values are nilled (such as a role record), it's
		-- traditionally impossible to determine if that item has
		-- actually been removed due to the way data is loaded from
		-- config on join. This section here enables us to track nilled
		-- values and respond to them accoridngly
		systemUser.perm.changed:Connect(function(key, value, oldValue)
			if value == nil then
				-- Only class as nilled if value present within config
				if main.config[categoryName][key] ~= nil then
					-- Record value as nilled
					oldValue = oldValue or {}
					local nilledCategory = nilledUser.perm[categoryName]
					if nilledCategory == nil then
						nilledCategory = nilledUser.perm:set(categoryName, {})
					end
					nilledCategory:set(key, oldValue)
				end
				
			elseif nilledUser.perm:find(categoryName, key) then
				-- Unnil value
				local nilledCategory = nilledUser.perm[categoryName]
				nilledCategory:set(key, nil)
				-- Sometimes an unnilled value is added after the temp
				-- record, therefore the temp record gets blocked.
				-- This checks to see if the temp record is present
				-- and adds it in if not
				if service.records[key] == nil then
					systemUser.temp:set(key, systemUser.temp[key])
				end
				
			end
		end)
		
		
	end)
	
	-- If a categories item has never been added before, however it exists
	-- by default within Config, then when it is removed on Server A ingame,
	-- server B will not detect this change. This therefore, fixes that issue,
	-- by listening out for specific changes within NilledData instead of
	-- the system's data
	local function setNilUpdate(categoryName, key, isNilled)
		local service = ConfigService.getServiceFromCategory(categoryName)
		if not service then return end
		local systemUser = service.user
		if isNilled then
			Thread.delay(3, function()
				if service.records[key] ~= nil and systemUser.perm:get(key) == nil and DataUtil.isEqual(isNilled, nilledUser.perm:find(categoryName, key)) then
					systemUser.temp:set(key, nil)
				end
			end)
		end
	end
	nilledUser.perm.changed:Connect(function(categoryName, tab)
		if type(tab) == "table" then
			tab.changed:Connect(function(key, isNilled)
				setNilUpdate(categoryName, key, isNilled)
			end)
			for key, isNilled in pairs(tab) do
				setNilUpdate(categoryName, key, isNilled)
			end
		end
	end)
	
	
	-- Complete
	ConfigService.setupComplete = true
	ConfigService.setupCompleteSignal:Fire()


	-- This checks for differences between config and latestConfig and
	-- if present, applies them to the corresponding services
	main.config = config
	local function updateConfig()
		latestConfig = ConfigService.getLatestConfig()
		ConfigService.transformChanges(latestConfig, main.config, "temp")
	end
	updateConfig()
	Thread.delayLoop(10, function()
		updateConfig()
	end)
end



-- METHODS
function ConfigService.getServiceFromCategory(categoryName)
	local serviceName = categoryName:sub(1, #categoryName-1).."Service"
	local service = main.services[serviceName]
	return service
end

function ConfigService.getLatestConfig()
	local user = ConfigService.user
	if user.isLoaded then
		user:loadAsync()
	else
		user:waitUntilLoaded()
	end
	local configData = user.perm.ConfigData or main.config
	return configData
end

function ConfigService.transformChanges(latestConfig, config, permOrTemp)
	local latestConfigCopy = TableUtil.copy(latestConfig)
	updateSystems(function(systemUser)
		local categoryName = systemUser.key
		local serviceName = categoryName:sub(1, #categoryName-1).."Service"
		local dataToUpdate = systemUser[permOrTemp]
		local category1 = latestConfig[categoryName]
		local category2 = config[categoryName]
		dataToUpdate:transformDifferences(category1, category2)
	end)
	main.config = latestConfigCopy
end



ConfigService._order = 4
return ConfigService