local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Morphs the player into that person"
Command.aliases	= {}
Command.opposites = {"Unbecome"}
Command.tags = {"Appearance"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = true
Command.preventRepeats = main.enum.TriStateSetting.False
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilPlayerRespawns
Command.args = {"Player", "UserDescription"}

function Command.invoke(job, args)
	local _, description = unpack(args)
	if description then
		job:buffPlayer("HumanoidDescription"):set(description)
	end
end



return Command