local SoundController = {
    remotes = {}
}
local main = require(game.Nanoblox)
local sounds = {}



-- START
function SoundController.start()
    -- Setup remotes
    local updateSoundProperties = main.modules.Remote.new("updateSoundProperties")
    SoundController.remotes.updateSoundProperties = updateSoundProperties
	updateSoundProperties.onClientEvent:Connect(function(soundInstance, propertiesToUpdate)
        for propertyName, value in pairs(propertiesToUpdate) do
			soundInstance[propertyName] = value
		end
	end)

    -- Update sounds when localPlayerSettings change
    main.controllers.SettingController.playerSettingsChanged:Connect(function(settingName, soundProperties)
        if settingName == "soundProperties" then
            for soundInstance, sound in pairs(sounds) do
                for propertyName, typeValues in pairs(soundProperties) do
                    local newValue = typeValues[sound.soundTypeName]
                    if soundInstance[propertyName] ~= newValue then
                        soundInstance[propertyName] = newValue
                    end
                end
            end
        end
    end)
end



-- METHODS
function SoundController.createSound(soundId, soundType)
	local sound = main.modules.Sound.new(soundId, soundType)
	sounds[sound.soundInstance] = sound
    return sound
end

function SoundController.getSound(soundId)
    for soundInstance, sound in pairs(sounds) do
        if sound.soundId == soundId then
            return sound
        end
    end
end

function SoundController.getSoundByInstance(soundInstance)
    return sounds[soundInstance]
end

function SoundController.getOrCreateSound(soundId, soundType)
    local sound = SoundController.getSound(soundId)
    if not sound then
        sound = SoundController.createSound(soundId, soundType)
    end
    return sound
end



return SoundController
