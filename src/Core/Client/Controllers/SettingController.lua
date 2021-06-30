-- LOCAL
local main = require(game.Nanoblox)
local SettingController = {
	playerSettings = main.modules.PlayerSettingsTemplate,
	playerSettingsChanged = main.modules.Signal.new()
}



-- START
function SettingController.start()
	
	print("Client DEFAULT playerSettings: ", SettingController.playerSettings)
	local updateLocalPlayerSettings = main.modules.Remote.new("updateLocalPlayerSettings")
	updateLocalPlayerSettings.onClientEvent:Connect(function(tableOfSettings)
		print("Client RECEIVE playerSettings (1): ", tableOfSettings)
		for key, value in pairs(tableOfSettings) do
			SettingController.playerSettings[key] = value
			SettingController.playerSettingsChanged:Fire(key, value)
		end
		print("Client RECEIVE playerSettings (2): ", SettingController.playerSettings)
	end)

end



return SettingController