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
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = true
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
Command.persistence = main.enum.Persistence.None
Command.args = {"Player"}

function Command.invoke(task, args)
    local player = args[1]
    local potentialTasksToClear = main.services.TaskService.getTasksWithPlayerUserId(player.UserId)
    for _, potentialTask in pairs(potentialTasksToClear) do
        if potentialTask:findTag("Animation") then
            print("END TASK: ", potentialTask.commandName)
            potentialTask:kill()
        end
    end
end



return Command