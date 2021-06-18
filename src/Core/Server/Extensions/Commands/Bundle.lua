local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Morphs you into that bundle"
Command.aliases	= {"Bund"}
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
Command.persistence = main.enum.Persistence.UntilPlayerRespawns
Command.args = {"Player", "BundleDescription"}

function Command.invoke(task, args)
	local _, description = unpack(args)
	if description then
		local descClone = task:give(description:Clone())
		descClone.Name = descClone.Name.." CLONE"
		descClone.Parent = workspace
		task:buffPlayer("HumanoidDescription"):set(description)
	end
end



return Command