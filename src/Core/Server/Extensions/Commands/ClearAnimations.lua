local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Plays a random dance animation for the player."
Command.aliases	= {"clrAnimations", "clrAnims", "unDance", "unAnimate", "unEmote", "unAnim"}
Command.opposites = {}
Command.tags = {"Animation"}
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
Command.args = {"Player"}

function Command.invoke(job, args)
    local player = args[1]
    local potentialJobsToClear = main.services.JobService.getJobsWithPlayerUserId(player.UserId)
    for _, potentialJob in pairs(potentialJobsToClear) do
        if potentialJob:findTag("Animation") then
            potentialJob:kill()
        end
    end
end



return Command