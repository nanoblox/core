-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local SettingService = System.new("Settings")



-- EVENTS
SettingService.recordChanged:Connect(function(groupName, statName, value)
	
end)



-- METHODS
function SettingService.generateRecord(key)
	local defaultRecords = {
		---------------------------
		["Player"] = {
			prefixes = {";"},
			argCapsule = "(%s)",
			collective = ",",
			descriptorSeparator = "",
			spaceSeparator = " ",
			batchSeparator = " ",
			
			playerIdentifier = "@",
			playerUndefinedSearch = main.enum.PlayerSearch.UserName, -- 'Undefined' means *without* the 'playerIdentifier' (e.g. ";kill Ben)
			playerDefinedSearch = main.enum.PlayerSearch.DisplayName, -- 'Defined' means *with* the 'playerIdentifier' (e.g. ";kill @ForeverHD)

			previewIncompleteCommands = false,
			
			theme = "",
			backgroundTransparency 	= 0.1,
		},
		
		
		---------------------------
		["System"] = {
			
			restrictedIDs = {
				library = { -- Sounds, Images, Models, etc
					denylist = {["0000"] = true,},
					allowlist = {},
				},
				catalog = { -- Gear, Accessories, Faces, etc
					denylist = {},
					allowlist = {},
				},
				bundle = { -- Bundles
					denylist = {},
					allowlist = {},
				},
			},

			-- Commands
			preventRepeatCommands = true,
			
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

			-- Environments
			createPrivateEnvironmentIfA = {
				privateServer = true,
				reservedServer = true,
				normalServer = true,
			},
		}
		
		
		---------------------------
	}
	return defaultRecords[key]
end

function SettingService.getPlayerSetting(settingName, optionalUser)
	local group = SettingService.getGroup("Player")
	local settingValue
	if optionalUser then
		local playerSettings = optionalUser.perm:getOrSetup("playerSettings")
		settingValue = playerSettings:get(settingName)
	end
	if settingValue == nil then
		settingValue = group[settingName]
	end
	return settingValue
end

function SettingService.updatePlayerSetting(settingName, settingValue, optionalUser)
	if optionalUser ~= nil then
		local playerSettings = optionalUser.perm:getOrSetup("playerSettings")
		playerSettings:set(settingName, settingValue)
	else
		SettingService.updateGroup("Player", {
			[settingName] = settingValue
		})
	end
end

function SettingService.getSystemSetting(settingName)
	local group = SettingService.getGroup("System")
	local settingValue = group[settingName]
	return settingValue
end

function SettingService.updateSystemSetting(settingName, settingValue)
	SettingService.updateGroup("System", {
		[settingName] = settingValue
	})
end

function SettingService.getGroup(groupName)
	return SettingService:getRecord(groupName)
end

function SettingService.getGroups()
	return SettingService:getRecords()
end

function SettingService.updateGroup(groupName, propertiesToUpdate)
	local key = tostring(groupName)
	--propertiesToUpdate["_global"] = true
	SettingService:updateRecord(key, propertiesToUpdate)
	return true
end

function SettingService.verifyCanUseRestrictedID(user, groupName, ID)
	-- Check group exists
	local groupNameLower = tostring(groupName):lower()
	local restrictedIDs = SettingService.getSystemSetting("restrictedIDs")
	local group = restrictedIDs[groupNameLower]
	if not group then
		error(("Attempt to check for a non-existent group '%s'"):format(tostring(groupName)))
	end
	local stringID = tostring(ID)
	local groupNameUpper = groupNameLower:sub(1,1):upper()..groupNameLower:sub(2)
	-- Check if denylisted
	if main.services.RoleService.verifySettings(user, {"limit", "denylistedIDs"}).areAll(true) then
		if group.denylist[stringID] then
			return false, string.format("'%s' is a denied %sID!", stringID, groupNameUpper)
		end
	end
	-- Check if allowlisted
	if main.services.RoleService.verifySettings(user, {"limit", "toAllowlistedIDs"}).areAll(true) then
		if not group.allowlist[stringID] then
			return false, string.format("'%s' is not an allowed %sID!", stringID, groupNameUpper)
		end
	end
	return true
end



return SettingService