local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Plays a random dance animation for the player."
Command.aliases	= {"RandomDance"}
Command.opposites = {}
Command.tags = {"Fun", "Dance", "Animation"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = true
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
Command.persistence = main.enum.Persistence.None
Command.args = {"Player", "Speed"}

function Command.invoke(task, args)
    local player = args[1]
    local danceGroup = main.services.CommandService.getTable("lowerCaseTagToGroupArray")["dance"]
    local totalCommandsInGroup = (danceGroup and #danceGroup) or 0
    if totalCommandsInGroup == 0 then
        return
    end
    local speed = task:getOriginalArg("Speed")
    local randomCommandName = danceGroup[math.random(1, totalCommandsInGroup)]
    task:hijackCommand(randomCommandName, {player, speed})
end



return Command