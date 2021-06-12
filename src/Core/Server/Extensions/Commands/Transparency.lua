local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {"Trans"}
Command.description = "Changes the transparency of the players body parts"
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
Command.args = {"Player", "Number"}

function Command.invoke(task, args)
	local _, number = unpack(args)
	if number then
		task:buffPlayer("BodyTransparency"):set(number)
	end
end



return Command