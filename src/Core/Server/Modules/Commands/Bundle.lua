local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {}
Command.description = "Morphs you into that bundle"
Command.contributors = {82347291}
Command.opposites = {}
Command.prefixes = {}
Command.tags = {"Appearance"}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.preventRepeats = main.enum.TriStateSetting.False
Command.revokeRepeats = true
Command.persistence = main.enum.Persistence.UntilPlayerRespawns
Command.args = {"Player", "BundleDescription"}

function Command.invoke(task, args)
	local _, description = unpack(args)
	if description then
		task:buffPlayer("HumanoidDescription"):set(description)
	end
end



return Command