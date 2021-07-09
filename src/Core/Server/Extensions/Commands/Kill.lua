local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Kills the player"
Command.aliases	= {"die", "commitNotAlive"}
Command.opposites = {}
Command.tags = {"Utility", "Abusive"}
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
Command.args = {"Player"}

function Command.invoke(task, args)
	local player = unpack(args)
	local character = player.Character
	if character then
		character:BreakJoints()
	end
end



return Command