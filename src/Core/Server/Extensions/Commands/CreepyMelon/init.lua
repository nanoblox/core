local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {"PraiseTheMelonLord", "Mel"}
Command.description = ""
Command.contributors = {}
Command.opposites = {}
Command.prefixes = {}
Command.tags = {}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.revokeRepeats = false
Command.persistence = main.enum.Persistence.UntilPlayerDies
Command.args = {"Player"}

function Command.invoke(task, args)
    local player = unpack(args)
	task:invokeAllAndFutureClients(player)
end

function Command.revoke(task)
	
end

function Command.preReplication(task, targetPool, packedData)
	return false
end



return Command