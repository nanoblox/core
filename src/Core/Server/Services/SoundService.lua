local SoundService = {
    remotes = {}
}
local main = require(game.Nanoblox)



-- START
function SoundService.start()
    local updateSoundProperty = main.modules.Remote.new("updateSoundProperty")
    SoundService.remotes.updateSoundProperty = updateSoundProperty
end



return SoundService
