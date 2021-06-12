local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {"ref"}
Command.description = "Changes the reflectance of the players body"
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
		task:buffPlayer("BodyReflectance"):set(number)
	end
end



return Command