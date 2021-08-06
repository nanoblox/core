local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Teleports Players directly above the caller's character."
Command.aliases	= {}
Command.opposites = {}
Command.tags = {"Utility"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
Command.persistence = main.enum.Persistence.None
Command.args = {"Players"}

function Command.invoke(job, args)
	local players = args[1]
	local targetPlayer = job.caller
	job:hijackCommand("Teleport2", {players, targetPlayer})
end



return Command