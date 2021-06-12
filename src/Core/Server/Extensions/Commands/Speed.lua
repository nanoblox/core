local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {"WalkSpeed", "WS"}
Command.description = "Changes the players WalkSpeed"
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
	local _, speed = unpack(args)
	if speed then
		task:buffPlayer("Humanoid", "WalkSpeed"):set(speed)
	end
end



return Command