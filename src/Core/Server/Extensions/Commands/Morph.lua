local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Transforms the player into the morph."
Command.aliases	= {}
Command.opposites = {}
Command.tags = {"Fun", "Appearance"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = true
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilPlayerRespawns
Command.args = {"Player", "Morph"}

function Command.invoke(job, args)
	local _, morph = unpack(args)
	if morph then
		job:buffPlayer("HumanoidDescription"):set(morph)
	end
end



return Command