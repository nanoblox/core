local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Plays a dance animation for the player."
Command.aliases	= {"Dance5"}
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
Command.emoteId = 5915781665

function Command.invoke(task, args)
    local player = args[1]
    local animationId = main.modules.Parser.Args.get("AnimationId"):parse(Command.emoteId)
    local speed = task:getOriginalArg("Speed")
    task:hijackCommand("Animate", {player, animationId, speed})
end



return Command