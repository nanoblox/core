local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Reloads the player's character"
Command.aliases	= {"res"}
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
Command.args = {"Player"}

function Command.invoke(task, args)
	local player = unpack(args)
	player:LoadCharacter()
end



return Command