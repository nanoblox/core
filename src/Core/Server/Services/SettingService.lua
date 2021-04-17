-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local SettingsService = System.new("Settings")



-- EVENTS
SettingsService.recordChanged:Connect(function(groupName, statName, value)
	
end)



-- METHODS
function SettingsService.generateRecord(key)
	local defaultRecords = {
		---------------------------
		["Player"] = {
			prefixes = {","},
			argCapsule = "(%s)",
			collective = ",",
			descriptorSeparator = "",
			spaceSeparator = " ",
			batchSeparator = " ",
			playerIdentifier = "@",

			previewIncompleteCommands = false,
			
			theme = "",
			backgroundTransparency 	= 0.1,
			--]]
		},
		
		
		---------------------------
		["System"] = {
			
			libraryIDs = { -- Gear, Sounds, Images, etc
				denylist = {},
				allowlist = {},
			},
			catalogIDs = { -- Accessories, Faces, etc
				denylist = {},
				allowlist = {},
			},
			bundleIDs = { -- Bundles
				denylist = {},
				allowlist = {},
			},

			-- Commands
			preventRepeatCommands = true,
			playerUndefinedSearch = main.enum.PlayerSearch.UserName, -- 'Undefined' means *without* the 'playerIdentifier' (e.g. ";kill Ben)
			playerDefinedSearch = main.enum.PlayerSearch.DisplayName, -- 'Defined' means *with* the 'playerIdentifier' (e.g. ";kill @ForeverHD)
			
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

function SettingsService.getPlayerSetting(settingName, optionalPlayer)
	local group = SettingsService.getGroup("Player")
	local user = optionalPlayer and main.modules.PlayerStore:getLoadedUser(optionalPlayer)
	local settingValue
	if user then
		settingValue = user.perm.playerSettings:get(settingName)
	end
	if settingValue == nil then
		settingValue = group[settingName]
	end
	return settingValue
end

function SettingsService.updatePlayerSetting(settingName, settingValue, optionalPlayer)
	if optionalPlayer ~= nil then
		local user = main.modules.PlayerStore:getLoadedUser(optionalPlayer)
		if user then
			user.perm.playerSettings:set(settingName, settingValue)
		end
	else
		SettingsService.updateGroup("Player", {
			[settingName] = settingValue
		})
	end
end

function SettingsService.getSystemSetting(settingName)
	local group = SettingsService.getGroup("System")
	local settingValue = group[settingName]
	return settingValue
end

function SettingsService.updateSystemSetting(settingName, settingValue)
	SettingsService.updateGroup("System", {
		[settingName] = settingValue
	})
end

function SettingsService.getGroup(groupName)
	return SettingsService:getRecord(groupName)
end

function SettingsService.getGroups()
	return SettingsService:getRecords()
end

function SettingsService.updateGroup(groupName, propertiesToUpdate)
	local key = tostring(groupName)
	--propertiesToUpdate["_global"] = true
	SettingsService:updateRecord(key, propertiesToUpdate)
	return true
end



return SettingsService