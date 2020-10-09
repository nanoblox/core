-- LOCAL
local main = require(game.HDAdmin)
local System = main.modules.System
local SettingsService = System.new("Settings")



-- EVENTS
SettingsService.recordChanged:Connect(function(groupName, statName, value)
	
end)



-- METHODS
function SettingsService.generateRecord(key)
	local defaultRecords = {
		---------------------------
		["Client"] = {
			prefixes				= {","},
			argCapsule 				= "(%s)",
			collective 				= ",",
			descriptorSeparator 	= "",
			spaceSeparator 			= " ",
			batchSeparator 			= " ",
		},
		
		
		---------------------------
		["System"] = {
			-- Gear
			restrictedGear = {},
			
			-- Warning System
			warnExpiryTime = 604800, -- 1 week
			kickUsers = true,
			warnsToKick = 3,
			serverBanUsers = true,
			warnsToServerBan = 4,
			serverBanTime = 7200, -- 2 hours
			globalBanUsers = true,
			warnsToGlobalBan = 5,
			globalBanTime = 172800, -- 2 days
		}
		
		
		---------------------------
	}
	return defaultRecords[key]
end

function SettingsService.getGroup(groupName)
	return SettingsService:getRecord(groupName)
end

function SettingsService.getGroups()
	return SettingsService:getRecords()
end

function SettingsService.updateGroup(groupName, propertiesToUpdate)
	local key = tostring(groupName)
	SettingsService:updateRecord(key, propertiesToUpdate)
	return true
end



return SettingsService