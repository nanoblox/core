local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {}
Command.description = "Increments the value of the players stat"
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
Command.args = {"Player", "Stat", "StatValue"}

function Command.invoke(task, args)
	local _, stat, value = unpack(args)
	if stat then
		main.modules.StatHandler.add(stat, value)
	end
end



return Command