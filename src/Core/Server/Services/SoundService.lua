local SoundService = {
    remotes = {}
}
local main = require(game.Nanoblox)
local sounds = {}



-- START
function SoundService.start()
    -- Setup remotes
    local updateSoundProperties = main.modules.Remote.new("updateSoundProperties")
    SoundService.remotes.updateSoundProperties = updateSoundProperties
end



-- METHODS
function SoundService.createSound(soundId, soundType)
    local sound = main.modules.Sound.new(soundId, soundType)
	sounds[sound.soundInstance] = sound
    return sound
end

function SoundService.getSound(soundId)
    for soundInstance, soundObject in pairs(sounds) do
        if soundObject.soundId == soundId then
            return soundObject
        end
    end
end

function SoundService.getSoundByInstance(soundInstance)
    return sounds[soundInstance]
end

function SoundService.getOrCreateSound(soundId, soundType)
    local sound = SoundService.getSound(soundId)
    if not sound then
        sound = SoundService.createSound(soundId, soundType)
    end
    return sound
end



return SoundService
