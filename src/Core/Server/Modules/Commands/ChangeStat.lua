local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {"SetStat"}
Command.description = "Changes the stat to the given value"
Command.contributors = {82347291}
Command.opposites = {}
Command.prefixes = {}
Command.tags = {"Stat"}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.revokeRepeats = false
Command.persistence = main.enum.Persistence.None
Command.args = {"Player", "Stat", "Text"}

function Command.invoke(task, args)
	local _, stat, value = unpack(args)
	if stat then
		main.modules.StatHandler.change(stat, value)
	end
end



return Command