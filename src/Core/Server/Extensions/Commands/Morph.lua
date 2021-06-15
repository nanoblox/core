local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {}
Command.description = "Transforms the player into the morph."
Command.contributors = {82347291}
Command.opposites = {}
Command.prefixes = {}
Command.tags = {"Fun", "Appearance"}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.revokeRepeats = true
Command.persistence = main.enum.Persistence.UntilPlayerLeaves
Command.args = {"Player", "Morph"}

function Command.invoke(task, args)
	local _, morph = unpack(args)
	if morph then
		task:buffPlayer("HumanoidDescription"):set(morph)
	end
end



return Command