local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Adds the hat to the given players character"
Command.aliases	= {"Accessory"}
Command.opposites = {}
Command.tags = {"Appearance", "Accessory"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.False
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilPlayerRespawns
Command.args = {"Player", "accessoryDictionary"}

function Command.invoke(task, args)
	local player, dictionary = unpack(args)
	print("player, dictionary = ", player, dictionary)
	if dictionary then
		task:buffPlayer("HumanoidDescription", dictionary.hdPropertyName):merge(dictionary.accessoryId)
	end
end



return Command