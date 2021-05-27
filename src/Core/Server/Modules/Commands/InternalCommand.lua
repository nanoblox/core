local main = require(game.Nanoblox)
local Command =	{}



Command.name = script.Name -- the name used to display and execute the command
Command.aliases	= {} -- additional names (typically shorthand) which activate the command
Command.description = "" -- a brief description which appears in the menu
Command.contributors = {} -- the names or IDs or people who developed this command
Command.opposites = {} -- the names to undo (revoke) the command, e.g. 'invisible' would have 'visible'
Command.prefixes = {} -- any additional prefixes from the system prefix to activate the command
Command.tags = {} -- tags (lowercase strings) associated with commands for grouping and searching; these are also used by roles to inherit commands (e.g. 'level1', 'level2', etc)
Command.blockPeers = false -- when 'true', prevents users of the same role (i.e. 'peers') executing the command on each other
Command.blockJuniors = false -- when 'true', prevents users of lower roles (i.e. 'junior') executing the command on higher ('i.e. 'senior') roles
Command.autoPreview = false -- preview the commands menu before executing
Command.requiresRig = nil -- e.g. Enum.HumanoidRigType.R15
Command.disableAllModifiers = false
Command.disabledModifiers = {}
Command.preventRepeats = main.enum.TriStateSetting.Default -- prevents two of the same commands being used on the same user or server at once
Command.revokeRepeats = false -- before creating the task, remove all tasks with the same commandName for the associated user or server
Command.persistence = main.enum.Persistence.None -- when set to None, the command will typically revoke (i.e. its task is killed) straight-away - to prevent this, replace 'None' with 'UntilDeath', 'UntilRespawn', 'UntilLeave' or 'UntilRevoke'
Command.args = {} -- the arguments to be processed and passed through the the command; see the 'Args' module for a list of all arguments

function Command.invoke(task, args)
	print("Hello world")
	task:delay(3, function()
		print("Goodbye world")
	end)
end

function Command.revoke(task)

end

function Command.preReplication(task, targetPool, packedData) -- this is called after a client calls ``task:replicateTo[...]``. if false, the client replication will be cancelled
	return true
end



return Command