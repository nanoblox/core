local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Grants the player with flight (with a sit effect). Double-jump or press E to toggle."
Command.aliases	= {"Flight2"}
Command.opposites = {}
Command.tags = {"Utility", "Flight"}
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
Command.args = {"Player", "Speed"}

function Command.invoke(task, args)
	task:hijackCommand("Fly", args, {
		speed = 50,
		propertyLock = "Sit",
		noclip = false,
	})
end



return Command