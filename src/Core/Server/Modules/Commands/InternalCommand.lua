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

Command.args = {} -- the arguments to be processed and passed through the the command; see the 'Args' module for a list of all arguments
function Command:invoke(task, caller, args)
	print("Hello world")
	task.track(main.modules.Task.delay(3, function()
		print("Goodbye world")
	end))
end
function Command:revoke(task, caller, args)

end



return Command