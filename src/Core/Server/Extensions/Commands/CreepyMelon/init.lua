local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = ""
Command.aliases	= {"PraiseTheMelonLord", "Mel"}
Command.opposites = {}
Command.tags = {}
Command.prefixes = {}
Command.contributors = {}
Command.blockPeers = false
Command.blockJuniors = false
Command.autoPreview = false
Command.requiresRig = main.enum.HumanoidRigType.None
Command.revokeRepeats = false
Command.preventRepeats = main.enum.TriStateSetting.Default
Command.cooldown = 0
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