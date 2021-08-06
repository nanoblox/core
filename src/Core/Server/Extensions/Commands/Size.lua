local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = "Changes the size of the players body"
Command.aliases	= {"Scale"}
Command.opposites = {}
Command.tags = {"Appearance"}
Command.prefixes = {}
Command.contributors = {82347291}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.R15
Command.revokeRepeats = true
Command.preventRepeats = main.enum.TriStateSetting.False
Command.cooldown = 0
Command.persistence = main.enum.Persistence.UntilPlayerRespawns
Command.args = {"Player", "Scale"}

function Command.invoke(job, args)
	local _, scale = unpack(args)
	if scale then
		job:buffPlayer("BodyScale"):set(scale)
	end
end



return Command