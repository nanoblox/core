local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name
Command.aliases	= {}
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