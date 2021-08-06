local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Morphs you into that person"
Command.aliases	= {}
Command.opposites = {}
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
Command.persistence = main.enum.Persistence.UntilCallerRespawns
Command.args = {"UserDescription"}

function Command.invoke(job, args)
	local description = unpack(args)
	if description then
		job:buffCaller("HumanoidDescription"):set(description)
	end
end



return Command