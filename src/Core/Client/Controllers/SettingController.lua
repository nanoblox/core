-- LOCAL
local main = require(game.Nanoblox)
local SettingController = {
	playerSettings = main.modules.State.new(main.modules.PlayerSettingsTemplate, true),
}



-- START
function SettingController.start()
	
	local updateLocalPlayerSettings = main.modules.Remote.new("updateLocalPlayerSettings")
	local DataUtil = main.modules.DataUtil
	updateLocalPlayerSettings.onClientEvent:Connect(function(propertiesToUpdate)
		local propertiesToUpdateFinal = DataUtil.getPathwayDictionaryFromMixedDictionary(propertiesToUpdate)
		DataUtil.mergeSettingTables(SettingController.playerSettings, propertiesToUpdateFinal)
	end)

end

function SettingController.getPlayerSetting(pathwayString)
	return SettingController.playerSettings:get(pathwayString)
end



return SettingController