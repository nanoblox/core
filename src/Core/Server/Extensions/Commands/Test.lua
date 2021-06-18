local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.description = ""
Command.aliases	= {}
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
Command.persistence = main.enum.Persistence.None
Command.args = {"Username"}

function Command.invoke(task, args)
	local username = unpack(args)
    print("USERNAME = ", username)
end

function Command.revoke(task)
	
end

function Command.preReplication(task, targetPool, packedData)
	return false
end



return Command