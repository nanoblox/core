local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Gives the ability to fly and pass through objects (while being seen by others). Double-jump or press E to toggle."
Command.aliases	= {}
Command.opposites = {"Clip2"}
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
		speed = 25,
		propertyLock = "PlatformStand",
		noclip = true,
	})
end



return Command