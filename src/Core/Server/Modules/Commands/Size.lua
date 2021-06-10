local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {"Scale"}
Command.description = "Changes the size of the players body"
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
Command.persistence = main.enum.Persistence.UntilPlayerDies
Command.args = {"Player", "Scale"}

function Command.invoke(task, args)
	local _, scale = unpack(args)
	if scale then
		task:buffPlayer("BodyScale"):set(scale)
	end
end



return Command