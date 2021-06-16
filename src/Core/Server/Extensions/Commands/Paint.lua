local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {}
Command.description = "Changes the color of the players body"
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
Command.args = {"Player", "Color"}

function Command.invoke(task, args)
	local _, color = unpack(args)
	if color then
		task:buffPlayer("BodyColor"):set(color)
	end
end



return Command