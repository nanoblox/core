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
		["Client"] = {
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
			
			noticeVolume = 0.1,
			noticePitch = 1,
			noticePromptSoundId = 2865227271,
			noticeErrorSoundId = 2865228021,
			alertVolume = 0.5,
			alertPitch = 1,
			alertSoundId = 3140355872,
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