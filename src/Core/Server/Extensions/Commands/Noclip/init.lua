local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Gives the player flight and the ability to pass through objects (while *not* being seen by others)"
Command.aliases	= {"Noclip1"}
Command.opposites = {"Clip", "Clip1"}
Command.tags = {"Utility"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.True
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilPlayerDies
Command.args = {"Player"}

function Command.invoke(task, args)
	local player = args[1]
	task:invokeClient(player)
end



return Command