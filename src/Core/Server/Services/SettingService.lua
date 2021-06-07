-- LOCAL
local main = require(game.Nanoblox)
local System = main.modules.System
local SettingService = System.new("Settings")



-- EVENTS
SettingService.recordChanged:Connect(function(groupName, statName, value)
	
end)



-- LOADED
function SettingService.loaded()
	--local colorsTable = SettingService.records.System.colors
	SettingService.records.System.colors:setTable("lowerCaseColorNames", function()
		local dictionary = {}
		--!!!print("Update colors dictionary...")
		for colorName, colorValue in pairs(SettingService.records.System.colors) do
			dictionary[colorName:lower()] = colorValue
		end
		return dictionary
	end)
	--[[
	spawn(function()
		wait(7)
		print("ADD MELON COLOR")
		--SettingService.records.System.colors:set("Ayyy (1)", Color3.fromRGB(0, 250, 21))
		SettingService.updateSystemSetting("colors", {
			A0005 = Color3.fromRGB(0, 250, 21)
		})
	end)
	--]]
end



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

			-- Colors to be used for the Color arg
			colors = {
				["Red"]	= Color3.fromRGB(255, 0, 0),
				["Orange"] = Color3.fromRGB(250, 100, 0),
				["Yellow"] = Color3.fromRGB(255, 255, 0),
				["Green"] = Color3.fromRGB(0, 255, 0),
				["DarkGreen"] = Color3.fromRGB(0, 125, 0),
				["Blue"] = Color3.fromRGB(0, 255, 255),
				["DarkBlue"] = Color3.fromRGB(0, 50, 255),
				["Purple"] = Color3.fromRGB(150, 0, 255),
				["Pink"] = Color3.fromRGB(255, 85, 185),
				["Black"] = Color3.fromRGB(0, 0, 0),
				["White"] = Color3.fromRGB(255, 255, 255),
			},

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
	if main.services.RoleService.verifySettings(user, "limit.denylistedIDs").areAll(true) then
		if group.denylist[stringID] then
			return false, string.format("'%s' is a denied %sID!", stringID, groupNameUpper)
		end
	end
	-- Check if allowlisted
	if main.services.RoleService.verifySettings(user, "limit.toAllowlistedIDs").areAll(true) then
		if not group.allowlist[stringID] then
			return false, string.format("'%s' is not an allowed %sID!", stringID, groupNameUpper)
		end
	end
	return true
end

function SettingService.getLowerCaseColors()
	return SettingService.records.System.colors:getTable("lowerCaseColorNames")
end



return SettingService