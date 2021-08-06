local SoundController = {
    remotes = {}
}
local main = require(game.Nanoblox)



-- START
function SoundController.start()
    local updateSoundProperty = main.modules.Remote.new("updateSoundProperty")
    SoundController.remotes.updateSoundProperty = updateSoundProperty
	updateSoundProperty.onClientEvent:Connect(function(soundInstance, propertyName, value)
        soundInstance[propertyName] = value
	end)
end



return SoundController
