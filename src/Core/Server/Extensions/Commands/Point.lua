local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Plays an emote for the player."
Command.aliases	= {"Point1"}
Command.opposites = {}
Command.tags = {"Fun", "Emote", "Animation"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.R15
Command.revokeRepeats = true
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
Command.persistence = main.enum.Persistence.None
Command.args = {"Player", "Speed"}

Command.emoteId = 3576823880

function Command.invoke(task, args)
    local player = args[1]
    local animationId = main.modules.Parser.Args.get("AnimationId"):parse(Command.emoteId)
    local speed = task:getOriginalArg("Speed")
    task:hijackCommand("Animate", {player, animationId, speed})
end



return Command